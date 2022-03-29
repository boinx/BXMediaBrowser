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


open class LightroomCCContainer : Container
{
	class LightroomCCData
	{
		var album:LightroomCC.Albums.Resource
		let allowedMediaTypes:[Object.MediaType]
		var cachedContainers:[Container]? = nil
		var cachedObjects:[Object]? = nil
		var objectMap:[String:Object] = [:]
		var nextAccessPoint:String? = nil
		
		init(with album:LightroomCC.Albums.Resource, allowedMediaTypes:[Object.MediaType])
		{
			self.album = album
			self.allowedMediaTypes = allowedMediaTypes
			self.cachedContainers = nil
			self.cachedObjects = nil
			self.nextAccessPoint = nil
		}
	}

	static let loadNextPageOfAssets = Notification.Name("LightroomCCContainer.loadNextPage")
	
	
//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Setup
	
	/// Creates a new Container for the folder at the specified URL
	
	public required init(album:LightroomCC.Albums.Resource, allowedMediaTypes:[Object.MediaType], filter:LightroomCCFilter)
	{
		let data = LightroomCCData(with:album, allowedMediaTypes:allowedMediaTypes)
		let identifier = "LightroomCC:Album:\(album.id)"
		let icon = album.subtype.contains("set") ? "folder" : "rectangle.stack"
		let name = album.payload.name
		
		super.init(
			identifier: identifier,
			icon: icon,
			name: name,
			data: data,
			filter: filter,
			loadHandler: Self.loadContents)

		// If there is another page of assets to be retrieved from the Lightroom server, then reload this container
		
		self.observers += NotificationCenter.default.publisher(for:Self.loadNextPageOfAssets, object:nil).sink
		{
			[weak self] notification in
			
			if let id = notification.object as? String, id == identifier
			{
				self?.load(with:nil)
			}
		}
	}


//----------------------------------------------------------------------------------------------------------------------


	// Folders can be expanded, but albums cannot
	
	override open var canExpand: Bool
	{
		guard let data = self.data as? LightroomCCData else { return false }
		return data.album.subtype.contains("set")
	}

	/// Returns the list of allowed sort Kinds for this Container
		
	override open var allowedSortTypes:[Object.Filter.SortType]
	{
		[.captureDate,.alphabetical,.rating]
	}


	// Choose unit name depending on allowedMediaTypes
	
    @MainActor override open var localizedObjectCount:String
    {
		let n = self.objects.count
		guard let data = data as? LightroomCCData else { return n.localizedItemsString }
		if data.allowedMediaTypes == [.image] { return n.localizedImagesString }
		if data.allowedMediaTypes == [.video] { return n.localizedVideosString }
		return n.localizedItemsString
    }


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Loading
	
	
	class func intialAccessPoint(with data:LightroomCCData,_ filter:LightroomCCFilter) -> String
	{
		let catalogID = LightroomCC.shared.catalogID
		let albumID = data.album.id
		let allowedMediaTypes = data.allowedMediaTypes
		let mediaTypes = allowedMediaTypes.map { $0.rawValue } .joined(separator:";")

		let accessPoint = "https://lr.adobe.io/v2/catalogs/\(catalogID)/albums/\(albumID)/assets"
		var urlComponents = URLComponents(string:accessPoint)!
        
		urlComponents.queryItems =
		[
			URLQueryItem(name:"subtype", value:mediaTypes),
			URLQueryItem(name:"embed", value:"asset"),
			URLQueryItem(name:"limit", value:"50"),
		]

		let string = urlComponents.url?.absoluteString ?? ""
		return string
	}
	
	
	/// Loads the (shallow) contents of this folder
	
	class func loadContents(for identifier:String, data:Any, filter:Object.Filter) async throws -> Loader.Contents
	{
		guard let data = data as? LightroomCCData else { throw Error.loadContentsFailed }
		guard let filter = filter as? LightroomCCFilter else { throw Error.loadContentsFailed }
		LightroomCC.log.debug {"\(Self.self).\(#function) \(identifier)"}
		
		// Find our child albums (parent is self) and create a Container for each child
		
		if data.cachedContainers == nil
		{
			data.cachedContainers = []
			
			let albumID = data.album.id
			let allAlbums = LightroomCC.shared.allAlbums
			let childAlbums = allAlbums.filter
			{
				guard let id = $0.payload.parent?.id else { return false }
				return id == albumID
			}

			for album in childAlbums
			{
				data.cachedContainers?.append(
					LightroomCCContainer(
						album:album,
						allowedMediaTypes:data.allowedMediaTypes,
						filter:filter))
			}
		}

		let containers = data.cachedContainers ?? []
		
		// When starting out, load first page of assets in this album
		
		if data.cachedObjects == nil
		{
			data.cachedObjects = []
			
			let accessPoint = Self.intialAccessPoint(with:data,filter)
			
			let (assets,nextAccessPoint) = try await self.nextPageAssets(for:accessPoint)
			self.add(assets, to:data)
			data.nextAccessPoint = nextAccessPoint
		}
		
		// Load next page of assets in this album
		
		else if let accessPoint = data.nextAccessPoint
		{
			LightroomCC.log.debug {"\(Self.self).\(#function) accessPoint = \(accessPoint)"}
			
			let (assets,nextAccessPoint) = try await self.nextPageAssets(for:accessPoint)
			self.add(assets, to:data)
			data.nextAccessPoint = nextAccessPoint
		}

		// Filter by name and/or rating
			
		let searchString = filter.searchString.lowercased()
		var objects:[Object] = []
		
		for object in data.cachedObjects ?? []
		{
			guard searchString.isEmpty || object.name.lowercased().contains(searchString) else { continue }
			guard filter.rating == 0 || StatisticsController.shared.rating(for:object) >= filter.rating else { continue }
			objects += object
		}
		
		// Sort according to specified sort order
		
		filter.sort(&objects)
		
		// If there is another page then trigger reloading
		
		if data.nextAccessPoint != nil
		{
			DispatchQueue.main.async
			{
				NotificationCenter.default.post(name: Self.loadNextPageOfAssets, object:identifier)
			}
		}
		
		// Return contents
		
		return (containers,objects)
	}


	/// Returns the next page of assets, and if available the accessPoint link to the following page
	
	private class func nextPageAssets(for accessPoint:String) async throws -> ([LightroomCC.Asset],String?)
	{
		// Get next page of assets
			
		LightroomCC.log.debug {"\(Self.self).\(#function) accessPoint = \(accessPoint)"}
		let page:LightroomCC.AlbumAssets = try await LightroomCC.shared.getData(from:accessPoint, debugLogging:false)
		let assets = page.resources.map { $0.asset }
			
		// Check if there is there yet another page
		
		var nextAccessPoint:String? = nil

		if let base = page.base, let next = page.links?.next?.href
		{
			nextAccessPoint = base + next
		}
		
		return (assets,nextAccessPoint)
	}


	/// Adds a pages of assets to the Object cache of this Container
	
	private class func add(_ assets:[LightroomCC.Asset], to data:LightroomCCData)
	{
		let allowedMediaTypes = data.allowedMediaTypes
		let allowImages = allowedMediaTypes.contains(.image)
		let allowVideos = allowedMediaTypes.contains(.video)

		for asset in assets
		{
			let subtype = asset.subtype ?? ""

			if subtype == "image" && allowImages
			{
				let object = LightroomCCImageObject(with:asset)
				let id = object.identifier
				
				if data.objectMap[id] == nil
				{
					data.cachedObjects?.append(object)
					data.objectMap[id] = object
				}
			}
			else if subtype == "video" && allowVideos
			{
				let object = LightroomCCVideoObject(with:asset)
				let id = object.identifier
				
				if data.objectMap[id] == nil
				{
					data.cachedObjects?.append(object)
					data.objectMap[id] = object
				}
			}
		}
		
//		dump(assets)
	}
}


//----------------------------------------------------------------------------------------------------------------------

