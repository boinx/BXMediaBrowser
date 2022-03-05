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


open class PexelsContainer : Container
{
	class PexelsData
	{
		var lastUsedFilter = PexelsFilter()
		var page = 0
		var photos:[Pexels.Photo] = []
	}
	
	public typealias SaveContainerHandler = (PexelsContainer)->Void
	
	let saveHandler:SaveContainerHandler?
	
	
//----------------------------------------------------------------------------------------------------------------------


	/// Creates a new Container for the folder at the specified URL
	
	public required init(identifier:String, icon:String, name:String, filter:PexelsFilter, saveHandler:SaveContainerHandler? = nil, removeHandler:((Container)->Void)? = nil)
	{
		PexelsSource.log.verbose {"\(Self.self).\(#function) \(identifier)"}

		self.saveHandler = saveHandler

		super.init(
			identifier: identifier,
			icon: icon,
			name: name,
			data: PexelsData(),
			filter: filter,
			loadHandler: Self.loadContents,
			removeHandler: removeHandler)
		
		self.observers += NotificationCenter.default.publisher(for:NSCollectionView.didScrollToEnd, object:self).sink
		{
			[weak self] _ in self?.load(with:nil)
		}
	}


	// Pexels Container can never be expanded, as they do not have any sub-containers
	
	override open var canExpand: Bool
	{
		false
	}
	

//----------------------------------------------------------------------------------------------------------------------


	/// Loads the (shallow) contents of this folder
	
	class func loadContents(for identifier:String, data:Any, filter:Object.Filter) async throws -> Loader.Contents
	{
		PexelsSource.log.debug {"\(Self.self).\(#function) \(identifier)"}

		let containers:[Container] = []
		var objects:[Object] = []
		
		guard let pexelsData = data as? PexelsData else { return (containers,objects) }
		guard let pexelsFilter = filter as? PexelsFilter else { return (containers,objects) }
		
		// If the search string has changed, then clear the results and store the new filter 
		
		if pexelsFilter != pexelsData.lastUsedFilter
		{
			pexelsData.page = 0
			pexelsData.photos = []
			pexelsData.lastUsedFilter.searchString = pexelsFilter.searchString
			pexelsData.lastUsedFilter.orientation = pexelsFilter.orientation
			pexelsData.lastUsedFilter.color = pexelsFilter.color
			pexelsData.lastUsedFilter.size = pexelsFilter.size
			pexelsData.lastUsedFilter.rating = pexelsFilter.rating
			PexelsSource.log.verbose {"    clear search results"}
		}
		
		// Append the next page of search results
			
		if !pexelsFilter.searchString.isEmpty
		{
			pexelsData.page += 1
			pexelsData.photos += try await self.photos(for:pexelsFilter, page:pexelsData.page)
			PexelsSource.log.verbose {"    appending page \(pexelsData.page)"}
		}
		
		// Remove potential duplicates, as that would cause serious issues with NSDiffableDataSource
		
		let photos = self.removeDuplicates(from:pexelsData.photos)
		
		// Build an Object for each PexelsPhoto in the search results
		
		for photo in photos
		{
			let object = PexelsObject(with:photo)
			
			if StatisticsController.shared.rating(for:object) >= filter.rating
			{
				objects += PexelsObject(with:photo)
			}
		}
		
		return (containers,objects)
	}
	
	
//----------------------------------------------------------------------------------------------------------------------


	/// Returns an array of PexelsPhotos for the specified search string and page number

	private class func photos(for filter:PexelsFilter, page:Int) async throws -> [Pexels.Photo]
	{
		// Build a search request with the provided search string (filter)
		
		let accessPoint = "https://api.pexels.com/v1/search"
		let accessKey = Pexels.shared.accessKey
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
		request.setValue(accessKey, forHTTPHeaderField:"Authorization")
		
		// Perform the online search
		
		let data = try await URLSession.shared.data(with:request)

		// Decode returned JSON to array of PexelsPhoto
		
		let results = try JSONDecoder().decode(Pexels.Photo.SearchResults.self, from:data)
		return results.photos
	}
	
	
	/// Removes any duplicate photos from the specified array. The returned array only contains unique entries.
	/// This is important when using a NSDiffableDataSource with NSCollectionView. Having duplicate identifiers
	/// would cause fatal exceptions.
	
	private class func removeDuplicates(from photos:[Pexels.Photo]) -> [Pexels.Photo]
	{
		var uniquePhotos:[Pexels.Photo] = []
		var identifiers:[Int] = []
		
		for photo in photos
		{
			guard !identifiers.contains(photo.id) else { continue }
			uniquePhotos += photo
			identifiers += photo.id
		}
		
		return uniquePhotos
	}
	
	
//----------------------------------------------------------------------------------------------------------------------


	/// Encodes/decodes a PexelsFilter from Data
	
	var filterData:Data?
	{
		get
		{
			guard let pexelsData = self.data as? PexelsData else { return nil }
			let filter = pexelsData.lastUsedFilter
			let data = try? JSONEncoder().encode(filter)
			return data
		}
		
		set
		{
			guard let data = newValue else { return }
			guard let pexelsData = self.data as? PexelsData else { return }
			guard let filter = try? JSONDecoder().decode(PexelsFilter.self, from:data) else { return }
			pexelsData.lastUsedFilter = filter
		}
	}

	/// Returns a textual description of the filter params (for displaying in the UI)
	
	var description:String
	{
		guard let filter = self.filter as? PexelsFilter else { return "" }
		return Self.description(with:filter)
	}

	/// Returns a textual description of the filter params (for displaying in the UI)

	class func description(with filter:PexelsFilter) -> String
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

