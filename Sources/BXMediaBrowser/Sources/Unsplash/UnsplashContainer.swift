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
		var filter = UnsplashFilter()
		var page = 0
		var photos:[UnsplashPhoto] = []
	}
	
	let _unsplashData = UnsplashData()
	
	public typealias SaveContainerHandler = (UnsplashContainer)->Void
	
	let saveHandler:SaveContainerHandler?
	
	
//----------------------------------------------------------------------------------------------------------------------


	/// Creates a new Container for the folder at the specified URL
	
	public required init(identifier:String, icon:String, name:String, saveHandler:SaveContainerHandler? = nil, removeHandler:((Container)->Void)? = nil)
	{
		UnsplashSource.log.verbose {"\(Self.self).\(#function) \(identifier)"}

		self.saveHandler = saveHandler

		super.init(
			identifier: identifier,
			icon: icon,
			name: name,
			data: self._unsplashData,
			loadHandler: Self.loadContents,
			removeHandler: removeHandler)
		
		self.observers += NotificationCenter.default.publisher(for:NSCollectionView.didScrollToEnd, object:self).sink
		{
			[weak self] _ in self?.load(with:nil)
		}
	}


	// Unsplash Container can never be expanded, as they do not have any sub-containers
	
	override var canExpand: Bool
	{
		false
	}
	

//----------------------------------------------------------------------------------------------------------------------


	/// Loads the (shallow) contents of this folder
	
	class func loadContents(for identifier:String, data:Any, filter:Any?) async throws -> Loader.Contents
	{
		UnsplashSource.log.debug {"\(Self.self).\(#function) \(identifier)"}

		let containers:[Container] = []
		var objects:[Object] = []
		
		guard let unsplashData = data as? UnsplashData else { return (containers,objects) }
		
		// If the search string has changed, then clear the results
		
		if (filter as? UnsplashFilter) != unsplashData.filter
		{
			unsplashData.page = 0
			unsplashData.photos = []
			UnsplashSource.log.verbose {"    clear search results"}
		}
		
		// Append the next page of search results
			
		if let unplashFilter = filter as? UnsplashFilter, !unplashFilter.searchString.isEmpty
		{
			unsplashData.page += 1
			unsplashData.filter = unplashFilter
			unsplashData.photos += try await self.photos(for:unplashFilter, page:unsplashData.page)
			UnsplashSource.log.verbose {"    appending page \(unsplashData.page)"}
		}
		
		// Remove potential duplicates, as that would cause serious issues with NSDiffableDataSource
		
		let photos = self.removeDuplicates(from:unsplashData.photos)
		
		// Build an Object for each UnsplashPhoto in the search results
		
		for photo in photos
		{
			objects += UnsplashObject(with:photo)
		}
		
		return (containers,objects)
	}
	
	
//----------------------------------------------------------------------------------------------------------------------


	/// Returns an array of UnsplashPhotos for the specified search string and page number

	private class func photos(for filter:UnsplashFilter, page:Int) async throws -> [UnsplashPhoto]
	{
		// Build a search request with the provided search string (filter)
		
		let accessKey = UnsplashConfig.shared.accessKey
		let authorization = "Client-ID \(accessKey)"
		let accessPoint = "https://api.unsplash.com/search/photos"
		var urlComponents = URLComponents(string:accessPoint)!
        
		urlComponents.queryItems =
		[
			URLQueryItem(name:"query", value:filter.searchString),
			URLQueryItem(name:"page", value:"\(page)"),
			URLQueryItem(name:"per_page", value:"30")
		]
		
		if let orientation = filter.orientation
		{
			urlComponents.queryItems?.append(URLQueryItem(name:"orientation", value:orientation.rawValue))
		}
		
		if let color = filter.color
		{
			urlComponents.queryItems?.append(URLQueryItem(name:"color", value:color.rawValue))
		}
		
		guard let url = urlComponents.url else { throw Error.loadContentsFailed }

		var request = URLRequest(url:url)
		request.httpMethod = "GET"
		request.setValue(authorization, forHTTPHeaderField:"Authorization")
		
		// Perform the online search
		
		let (data,_) = try await URLSession.shared.data(for:request)
		
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


	var filterData:Data?
	{
		get
		{
			guard let unsplashData = self.data as? UnsplashData else { return nil }
			let filter = unsplashData.filter
			let data = try? JSONEncoder().encode(filter)
			return data
		}
		
		set
		{
			guard let data = newValue else { return }
			guard let unsplashData = self.data as? UnsplashData else { return }
			guard let filter = try? JSONDecoder().decode(UnsplashFilter.self, from:data) else { return }
			unsplashData.filter = filter
		}
	}


	var description:String
	{
		guard let filter = self.filter as? UnsplashFilter else { return "" }
		return Self.description(with:filter)
	}


	class func description(with filter:UnsplashFilter) -> String
	{
		let searchString = filter.searchString
		let orientation = filter.orientation?.localizedName ?? ""
		let color = filter.color?.localizedName ?? ""

		var description = searchString
		if !orientation.isEmpty { description += ", \(orientation)" }
		if !color.isEmpty { description += ", \(color)" }
		return description
	}


	/// Returns a description of the contents of this Container
	
    @MainActor override var objectCountDescription:String
    {
		let n = self.objects.count
		let str = n.localizedImagesString
		return str
    }
}


//----------------------------------------------------------------------------------------------------------------------

