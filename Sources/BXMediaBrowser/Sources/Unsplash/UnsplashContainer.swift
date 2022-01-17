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


import Foundation


//----------------------------------------------------------------------------------------------------------------------


open class UnsplashContainer : Container
{
	class State
	{
		var filterString = ""
		var page = 0
		var photos:[UnsplashPhoto] = []
	}
	
	let state = State()
	
	// Unsplash Container can never be expanded, as they do not have any sub-containers
	
	override var canExpand: Bool
	{
		false
	}
	

	/// Creates a new Container for the folder at the specified URL
	
	public required init()
	{
		super.init(
			identifier: "UnsplashSource:Search",
			info: self.state,
			icon: "magnifyingglass",
			name: "Search",
			removeHandler: nil,
			loadHandler: Self.loadContents)
			
		self.observers += NotificationCenter.default.publisher(for:didScrollToEndNotification, object:self).sink
		{
			[weak self] _ in self?.load(with:nil)
		}
	}


	/// Loads the (shallow) contents of this folder
	
	class func loadContents(for identifier:String, info:Any, filter:String) async throws -> Loader.Contents
	{
		let containers:[Container] = []
		var objects:[Object] = []
		
		guard let state = info as? State else { return (containers,objects) }
		
		// If the search string has changed, then clear the results
		
		if filter != state.filterString
		{
			state.page = 0
			state.photos = []
			print("UnsplashContainer: clear search results")
		}
		
		// Append the next page of search results
			
		if !filter.isEmpty
		{
			state.page += 1
			state.filterString = filter
			state.photos += try await self.photos(for:filter, page:state.page)
			print("UnsplashContainer: appending page \(state.page)")
		}
		
		// Remove potential duplicates, as that would cause serious issues with NSDiffableDataSource
		
		let photos = self.removeDuplicates(from:state.photos)
		
		// Build an Object for each UnsplashPhoto in the search results
		
		for photo in photos
		{
			objects += UnsplashObject(with:photo)
		}
		
		return (containers,objects)
	}
	
	
	/// Returns an array of UnsplashPhotos for the specified search string and page number

	private class func photos(for searchString:String, page:Int) async throws -> [UnsplashPhoto]
	{
		// Build a search request with the provided search string (filter)
		
		let accessKey = UnsplashConfig.shared.accessKey //"VKrgdYuo88hVc1dsG30xE6OjunULacXlvcfdIO6-Zlw" //
		let authorization = "Client-ID \(accessKey)"
		let accessPoint = "https://api.unsplash.com/search/photos"
		var urlComponents = URLComponents(string:accessPoint)!
        
		urlComponents.queryItems =
		[
			URLQueryItem(name:"query", value:searchString),
			URLQueryItem(name:"page", value:"\(page)"),
			URLQueryItem(name:"per_page", value:"30")
		]

		guard let url = urlComponents.url else { throw Error.loadContentsFailed }

		var request = URLRequest(url:url)
		request.httpMethod = "GET"
		request.setValue(authorization, forHTTPHeaderField:"Authorization")
		
		// Perform the online search
		
		let (data,_) = try await URLSession.shared.data(with:request)
		
		// Decode returned JSON to array of UnsplashPhoto
		
		let results = try JSONDecoder().decode(UnsplashSearchResults.self, from:data)
		let photos = results.results
		
		return photos
	}
	
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
}


//----------------------------------------------------------------------------------------------------------------------

