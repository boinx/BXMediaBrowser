//----------------------------------------------------------------------------------------------------------------------
//
//  Copyright ©2022 Peter Baumgartner. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//
//----------------------------------------------------------------------------------------------------------------------


import BXSwiftUtils
import Foundation

#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif


//----------------------------------------------------------------------------------------------------------------------


open class UnsplashContainer : Container
{
	class UnsplashData
	{
		var lastUsedFilter = UnsplashFilter()
		var page = 0
		var photos:[UnsplashPhoto] = []
	}
	
	public typealias SaveContainerHandler = (UnsplashContainer)->Void
	
	let saveHandler:SaveContainerHandler?
	
	
//----------------------------------------------------------------------------------------------------------------------


	/// Creates a new Container for the folder at the specified URL
	
	public required init(identifier:String, icon:String, name:String, filter:UnsplashFilter, saveHandler:SaveContainerHandler? = nil, removeHandler:((Container)->Void)? = nil)
	{
		Unsplash.log.verbose {"\(Self.self).\(#function) \(identifier)"}

		self.saveHandler = saveHandler

		super.init(
			identifier: identifier,
			icon: icon,
			name: name,
			data: UnsplashData(),
			filter: filter,
			loadHandler: Self.loadContents,
			removeHandler: removeHandler)
		
		#if os(macOS)
		
		self.observers += NotificationCenter.default.publisher(for:NSCollectionView.didScrollToEnd, object:self).sink
		{
			[weak self] _ in self?.load(with:nil)
		}
		
		#elseif os(iOS)
		#warning("TODO: implement")
		#endif
	}


	override nonisolated open var mediaTypes:[Object.MediaType]
	{
		return [.image]
	}
	
	// Unsplash Container can never be expanded, as they do not have any sub-containers
	
	override open var canExpand: Bool
	{
		false
	}
	

//----------------------------------------------------------------------------------------------------------------------


	/// Loads the (shallow) contents of this folder
	
	class func loadContents(for identifier:String, data:Any, filter:Object.Filter) async throws -> Loader.Contents
	{
		Unsplash.log.debug {"\(Self.self).\(#function) \(identifier)"}

		let containers:[Container] = []
		var objects:[Object] = []
		
		guard let unsplashData = data as? UnsplashData else { return (containers,objects) }
		guard let unsplashFilter = filter as? UnsplashFilter else { return (containers,objects) }
		
		// If the search string has changed, then clear the results and store the new filter 
		
		if unsplashFilter != unsplashData.lastUsedFilter
		{
			unsplashData.page = 0
			unsplashData.photos = []
			unsplashData.lastUsedFilter.searchString = unsplashFilter.searchString
			unsplashData.lastUsedFilter.orientation = unsplashFilter.orientation
			unsplashData.lastUsedFilter.color = unsplashFilter.color
			unsplashData.lastUsedFilter.rating = unsplashFilter.rating
			Unsplash.log.verbose {"    clear search results"}
		}
		
		// Append the next page of search results
			
		if !unsplashFilter.searchString.isEmpty
		{
			unsplashData.page += 1
			unsplashData.photos += try await self.photos(for:unsplashFilter, page:unsplashData.page)
			Unsplash.log.verbose {"    appending page \(unsplashData.page)"}
		}
		
		// Remove potential duplicates, as that would cause serious issues with NSDiffableDataSource
		
		let photos = self.removeDuplicates(from:unsplashData.photos)
		
		// Build an Object for each UnsplashPhoto in the search results
		
		for photo in photos
		{
			let object = UnsplashObject(with:photo)
			
			if StatisticsController.shared.rating(for:object) >= filter.rating
			{
				objects += object
			}
		}
		
		return (containers,objects)
	}
	
	
//----------------------------------------------------------------------------------------------------------------------


	/// Returns an array of UnsplashPhotos for the specified search string and page number

	private class func photos(for filter:UnsplashFilter, page:Int) async throws -> [UnsplashPhoto]
	{
		// Build a search request with the provided search string (filter)
		
		let accessKey = Unsplash.shared.accessKey
		let authorization = "Client-ID \(accessKey)"
		let accessPoint = "https://api.unsplash.com/search/photos"
		var urlComponents = URLComponents(string:accessPoint)!
        
		urlComponents.queryItems =
		[
			URLQueryItem(name:"query", value:filter.searchString),
			URLQueryItem(name:"page", value:"\(page)"),
			URLQueryItem(name:"per_page", value:"30")
		]
		
		if filter.orientation != .any
		{
			urlComponents.queryItems?.append(URLQueryItem(name:"orientation", value:filter.orientation.rawValue))
		}
		
		if filter.color != .any
		{
			urlComponents.queryItems?.append(URLQueryItem(name:"color", value:filter.color.rawValue))
		}
		
		guard let url = urlComponents.url else { throw Error.loadContentsFailed }

		var request = URLRequest(url:url)
		request.httpMethod = "GET"
		request.setValue(authorization, forHTTPHeaderField:"Authorization")
		
		// Perform the online search
		
		let data = try await URLSession.shared.data(with:request)
		
		// Decode returned JSON to array of UnsplashPhoto
		
		let results = try JSONDecoder().decode(UnsplashSearchResults.self, from:data)
		let photos = results.results
		
		return photos
	}
	
	
	/// Removes any duplicate photos from the specified array. The returned array only contains unique entries.
	/// This is important when using a NSDiffableDataSource with NSCollectionView. Having duplicate identifiers
	/// would cause fatal exceptions.
	
	private class func removeDuplicates(from photos:[UnsplashPhoto]) -> [UnsplashPhoto]
	{
		var uniquePhotos:[UnsplashPhoto] = []
		var identifiers:[String] = []
		
		for photo in photos
		{
			guard !identifiers.contains(photo.id) else { continue }
			uniquePhotos += photo
			identifiers += photo.id
		}
		
		return uniquePhotos
	}
	
	
//----------------------------------------------------------------------------------------------------------------------


	/// Encodes/decodes a UnsplashFilter from Data
	
	var filterData:Data?
	{
		get
		{
			guard let unsplashData = self.data as? UnsplashData else { return nil }
			let filter = unsplashData.lastUsedFilter
			let data = try? JSONEncoder().encode(filter)
			return data
		}
		
		set
		{
			guard let data = newValue else { return }
			guard let unsplashData = self.data as? UnsplashData else { return }
			guard let filter = try? JSONDecoder().decode(UnsplashFilter.self, from:data) else { return }
			unsplashData.lastUsedFilter = filter
		}
	}

	/// Returns a textual description of the filter params (for displaying in the UI)
	
	var description:String
	{
		guard let filter = self.filter as? UnsplashFilter else { return "" }
		return Self.description(with:filter)
	}

	/// Returns a textual description of the filter params (for displaying in the UI)

	class func description(with filter:UnsplashFilter) -> String
	{
		let searchString = filter.searchString
		let orientation = filter.orientation != .any ? filter.orientation.localizedName : ""
		let color = filter.color != .any ? filter.color.localizedName : ""

		var description = searchString
		if !orientation.isEmpty { description += ", \(orientation)" }
		if !color.isEmpty { description += ", \(color)" }
		return description
	}

	/// Returns a description of the contents of this Container
	
    @MainActor override open var localizedObjectCount:String
    {
		let n = self.objects.count
		let str = n.localizedImagesString
		return str
    }


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Sorting
	
	/// Returns the list of allowed sort Kinds for this Container
		
	override open var allowedSortTypes:[Object.Filter.SortType] { [] }
}


//----------------------------------------------------------------------------------------------------------------------

