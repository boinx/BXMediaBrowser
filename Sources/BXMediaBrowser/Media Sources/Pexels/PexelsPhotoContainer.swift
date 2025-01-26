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


//----------------------------------------------------------------------------------------------------------------------


open class PexelsPhotoContainer : PexelsContainer
{
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
	
	override class func loadContents(for identifier:String, data:Any, filter:Object.Filter, in library:Library?) async throws -> Loader.Contents
	{
		Pexels.log.debug {"\(Self.self).\(#function) \(identifier)"}

		let containers:[Container] = []
		var objects:[Object] = []
		
		guard let pexelsData = data as? PexelsData else { return (containers,objects) }
		guard let pexelsFilter = filter as? PexelsFilter else { return (containers,objects) }
		
		// If the search string has changed, then clear the results and store the new filter
		
		if pexelsFilter != pexelsData.lastUsedFilter
		{
			Pexels.log.debug {"    clear search results"}

			pexelsData.page = 0
			pexelsData.objects = []
			pexelsData.knownIDs.removeAll()
			pexelsData.didReachEnd = false
			pexelsData.loadNextPage = true
			
			pexelsData.lastUsedFilter.searchString = pexelsFilter.searchString
			pexelsData.lastUsedFilter.orientation = pexelsFilter.orientation
			pexelsData.lastUsedFilter.color = pexelsFilter.color
			pexelsData.lastUsedFilter.size = pexelsFilter.size
		}
		
		// Append the next page of search results
			
		if pexelsData.loadNextPage
		{
			pexelsData.page += 1
			let page = pexelsData.page
			Pexels.log.debug {"    appending page \(page)"}
			
			let newPhotos = try await self.photos(for:pexelsFilter, page:page)
			self.add(newPhotos, to:pexelsData, in:library)

			pexelsData.loadNextPage = false
			if newPhotos.isEmpty { pexelsData.didReachEnd = true }
		}
		
		// Filter objects by rating
		
		objects = pexelsData.objects.filter
		{
			StatisticsController.shared.rating(for:$0) >= filter.rating
		}
		
		return (containers,objects)
	}
	
	
	/// Returns an array of PexelsPhotos for the specified search string and page number

	private class func photos(for filter:PexelsFilter, page:Int) async throws -> [Pexels.Photo]
	{
		guard !filter.searchString.isEmpty else { return [] }
		
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
	
	
	/// Adds the new photos to the list of cached Objects. To make sure that NSDiffableDataSource doesn't
	/// complain (and throw an exception), any duplicates will be ignored.
	
	private class func add(_ photos:[Pexels.Photo], to pexelsData:PexelsData, in library:Library?)
	{
		synchronized(pexelsData)
		{
			for photo in photos
			{
				let id = photo.id
				guard !pexelsData.knownIDs.contains(id) else { continue }
				pexelsData.knownIDs.insert(id)
				pexelsData.objects += PexelsPhotoObject(with:photo, in:library)
			}
		}
	}
}


//----------------------------------------------------------------------------------------------------------------------

