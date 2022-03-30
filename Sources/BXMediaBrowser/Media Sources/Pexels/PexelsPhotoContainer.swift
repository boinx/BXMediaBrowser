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

#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif


//----------------------------------------------------------------------------------------------------------------------


open class PexelsPhotoContainer : PexelsContainer
{
	/// Creates a new Container for the folder at the specified URL
	
	public required init(identifier:String, icon:String, name:String, filter:PexelsFilter, saveHandler:SaveContainerHandler? = nil, removeHandler:((Container)->Void)? = nil)
	{
		Pexels.log.verbose {"\(Self.self).\(#function) \(identifier)"}

		super.init(
			identifier: identifier,
			icon: icon,
			name: name,
			data: PexelsData(),
			filter: filter,
			loadHandler: Self.loadContents,
			removeHandler: removeHandler)

		self.saveHandler = saveHandler

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
	
	/// Returns a description of the contents of this Container
	
    @MainActor override open var localizedObjectCount:String
    {
		let n = self.objects.count
		let str = n.localizedImagesString
		return str
    }


//----------------------------------------------------------------------------------------------------------------------


	/// Loads the (shallow) contents of this folder
	
	class func loadContents(for identifier:String, data:Any, filter:Object.Filter) async throws -> Loader.Contents
	{
		Pexels.log.debug {"\(Self.self).\(#function) \(identifier)"}

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
			Pexels.log.verbose {"    clear search results"}
		}
		
		// Append the next page of search results
			
		if !pexelsFilter.searchString.isEmpty
		{
			pexelsData.page += 1
			pexelsData.photos += try await self.photos(for:pexelsFilter, page:pexelsData.page)
			Pexels.log.verbose {"    appending page \(pexelsData.page)"}
		}
		
		// Remove potential duplicates, as that would cause serious issues with NSDiffableDataSource
		
		let photos = self.removeDuplicates(from:pexelsData.photos)
		
		// Build an Object for each PexelsPhoto in the search results
		
		for photo in photos
		{
			let object = PexelsPhotoObject(with:photo)
			
			if StatisticsController.shared.rating(for:object) >= filter.rating
			{
				objects += object
			}
		}
		
		return (containers,objects)
	}
	
	
	/// Returns an array of PexelsPhotos for the specified search string and page number

	private class func photos(for filter:PexelsFilter, page:Int) async throws -> [Pexels.Photo]
	{
		// Build a search request with the provided search string (filter)
		
		let accessPoint = Pexels.shared.imagesAPI
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

}


//----------------------------------------------------------------------------------------------------------------------

