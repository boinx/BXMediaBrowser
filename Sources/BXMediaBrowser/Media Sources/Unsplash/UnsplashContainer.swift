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

// Needed for NSCollectionView

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
		var objects:[UnsplashObject] = []
		var knownIDs:[String:UnsplashPhoto] = [:]
		var didReachEnd = false
		var loadNextPage = true
	}
	
	public typealias SaveContainerHandler = (UnsplashContainer)->Void
	
	let saveHandler:SaveContainerHandler?
	
	
//----------------------------------------------------------------------------------------------------------------------


	// MARK: -
	
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
			[weak self] _ in self?.didScrollToEnd()
		}
		
		#elseif os(iOS)
		
		#warning("TODO: implement")
		
		#endif
	}

	// Unsplash only handles images
	
	override nonisolated open var mediaTypes:[Object.MediaType]
	{
		return [.image]
	}
	
	// Unsplash Container can never be expanded, as they do not have any sub-containers
	
	override open var canExpand: Bool
	{
		false
	}
	
	/// Returns the list of allowed sort Kinds for this Container
		
	override open var allowedSortTypes:[Object.Filter.SortType]
	{
		[]
	}

	/// Returns a description of the contents of this Container
	
    @MainActor override open var localizedObjectCount:String
    {
		let n = self.objects.count
		let str = n.localizedImagesString
		return str
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


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Loading
	
	/// This method will be called when the user scrolls to the end of the NSCollectionView.
	
	func didScrollToEnd()
	{
		guard let unsplashData = data as? UnsplashData else { return }
		guard let unsplashFilter = filter as? UnsplashFilter else { return }
		guard !unsplashFilter.searchString.isEmpty else { return }
		guard unsplashFilter.rating == 0 else { return }
		
		// If the content is not being filtered by rating, then load the next page of data
		
		if !unsplashData.didReachEnd
		{
			unsplashData.loadNextPage = true
			self.load(with:nil)
		}
	}
	
	
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
			Unsplash.log.debug {"    clear search results"}

			unsplashData.page = 0
			unsplashData.objects = []
			unsplashData.knownIDs = [:]
			unsplashData.didReachEnd = false
			unsplashData.loadNextPage = true

			unsplashData.lastUsedFilter.searchString = unsplashFilter.searchString
			unsplashData.lastUsedFilter.orientation = unsplashFilter.orientation
			unsplashData.lastUsedFilter.color = unsplashFilter.color
		}
		
		// Append the next page of search results

		if unsplashData.loadNextPage
		{
			unsplashData.page += 1
			let page = unsplashData.page
			Unsplash.log.debug {"    appending page \(page)"}
			
			let newPhotos = try await self.photos(for:unsplashFilter, page:page)
			self.add(newPhotos, to:unsplashData)

			unsplashData.loadNextPage = false
			if newPhotos.isEmpty { unsplashData.didReachEnd = true }
		}
		
		// Filter objects by rating
		
		objects = unsplashData.objects.filter
		{
			StatisticsController.shared.rating(for:$0) >= filter.rating
		}

		return (containers,objects)
	}
	
	
//----------------------------------------------------------------------------------------------------------------------


	/// Returns an array of UnsplashPhotos for the specified search string and page number

	private class func photos(for filter:UnsplashFilter, page:Int) async throws -> [UnsplashPhoto]
	{
		guard !filter.searchString.isEmpty else { return [] }

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
	
	
	/// Adds the new photos to the list of cached Objects. To make sure that NSDiffableDataSource doesn't
	/// complain (and throw an exception), any duplicates will be ignored.
	
	private class func add(_ photos:[UnsplashPhoto], to unsplashData:UnsplashData)
	{
		for photo in photos
		{
			let id = photo.id
			guard unsplashData.knownIDs[id] == nil else { continue }
			unsplashData.objects += UnsplashObject(with:photo)
			unsplashData.knownIDs[id] = photo
		}
	}
	
	
//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Saving

	
	/// Creates a new Container with the saved search parameters of this Container
	
	public func save()
	{
		self.saveHandler?(self)
	}
	
	
	/// Encodes/decodes a UnsplashFilter from Data
	
	var filterData:Data?
	{
		get
		{
			guard let filter = self.filter as? UnsplashFilter else { return nil }
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

}


//----------------------------------------------------------------------------------------------------------------------

