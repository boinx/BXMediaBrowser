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


open class LightroomCCContainer : Container, AppLifecycleMixin
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
	
	public required init(library:Library?, album:LightroomCC.Albums.Resource, allowedMediaTypes:[Object.MediaType], filter:LightroomCCFilter)
	{
		let data = LightroomCCData(with:album, allowedMediaTypes:allowedMediaTypes)
		let identifier = "LightroomCC:Album:\(album.id)"
		let icon = album.subtype.contains("set") ? "folder" : "rectangle.stack"
		let name = album.payload.name
		
		super.init(
			library:library,
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
				self?.load(with:nil, in:library)
			}
		}
		
		// Since Lightroom CC does not have any change notification mechanism yet, we need to poll for changes.
		// Whenever the app is brought to the foreground (activated), we just assume that a change was made in
		// Lightroom in the meantime. Perform necessary checks and reload this container if necessary.
		
//		self.registerDidActivateHandler
//		{
//			[weak self] in self?.reloadIfNeeded()
//		}
	}


//----------------------------------------------------------------------------------------------------------------------



	override nonisolated open var mediaTypes:[Object.MediaType]
	{
		guard let data = self.data as? LightroomCCData else { return [.image] }
		return data.allowedMediaTypes
	}

	// Folders can be expanded, but albums cannot
	
	override open var canExpand: Bool
	{
		guard let data = self.data as? LightroomCCData else { return false }
		return data.album.subtype.contains("set")
	}

	/// Returns the list of allowed sort Kinds for this Container
		
	override open var allowedSortTypes:[Object.Filter.SortType]
	{
		[.captureDate,.alphabetical,.rating,.useCount]
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
	
	
	/// Clears the caches so that we can reload a Container
	
	@MainActor override func invalidateCache()
	{
		super.invalidateCache()
		
		guard let data = data as? LightroomCCData else { return }
		data.cachedContainers = nil
		data.cachedObjects = nil
		data.objectMap = [:]
		data.nextAccessPoint = nil
	}
	
	
	/// Returns the accessPoint URL for the first page of data
	
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
	
	class func loadContents(for identifier:String, data:Any, filter:Object.Filter, in library:Library?) async throws -> Loader.Contents
	{
		guard let data = data as? LightroomCCData else { throw Error.loadContentsFailed }
		guard let filter = filter as? LightroomCCFilter else { throw Error.loadContentsFailed }
		LightroomCC.log.debug {"\(Self.self).\(#function) \(identifier)"}

		let id = self.beginSignpost(in:"LightroomCCContainer", #function)
		defer { self.endSignpost(with:id, in:"LightroomCCContainer", #function) }

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
						library:library,
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
			self.add(assets, to:data, in:library)
			data.nextAccessPoint = nextAccessPoint
		}
		
		// Load next page of assets in this album
		
		else if let accessPoint = data.nextAccessPoint
		{
			LightroomCC.log.debug {"\(Self.self).\(#function) accessPoint = \(accessPoint)"}
			
			let (assets,nextAccessPoint) = try await self.nextPageAssets(for:accessPoint)
			self.add(assets, to:data, in:library)
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
		try await Tasks.canContinue()
		
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
	
	private class func add(_ assets:[LightroomCC.Asset], to data:LightroomCCData, in library:Library?)
	{
		let allowedMediaTypes = data.allowedMediaTypes
		let allowImages = allowedMediaTypes.contains(.image)
		let allowVideos = allowedMediaTypes.contains(.video)

		for asset in assets
		{
			let subtype = asset.subtype ?? ""

			if subtype == "image" && allowImages
			{
				let object = LightroomCCImageObject(with:asset, in:library)
				let id = object.identifier
				
				if data.objectMap[id] == nil
				{
					data.cachedObjects?.append(object)
					data.objectMap[id] = object
				}
			}
			else if subtype == "video" && allowVideos
			{
				let object = LightroomCCVideoObject(with:asset, in:library)
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
	
	
	// Since Lightroom CC does not have and change notification mechanism yet, we need to poll for changes.
	// Whenever the app is brought to the foreground (activated), we just assume that a change was made in
	// Lightroom in the meantime. Perform necessary checks and reload this container if necessary.

	private func reloadIfNeeded()
	{
		guard let data = data as? LightroomCCData else { return }
		
		Task
		{
			guard await self.isLoaded else { return }
			
			let catalogID = LightroomCC.shared.catalogID
			let albumID = data.album.id
			let accessPoint = "https://lr.adobe.io/v2/catalogs/\(catalogID)/albums/\(albumID)"
			let album:LightroomCC.Album = try await LightroomCC.shared.getData(from:accessPoint, debugLogging:false)
			let needsReloading = album.payload.userUpdated > data.album.updated || album.updated > data.album.updated

			LightroomCC.log.debug {"\(Self.self).\(#function)   name = \(self.name)   oldUpdated = \(data.album.updated)    newUpdated = \(album.updated)    needsReloading = \(needsReloading)"}

			if needsReloading
			{
				await MainActor.run
				{
					LightroomCC.log.debug {"\(Self.self).\(#function)"}
					self.reload()
				}
			}
		}
	}
}


//----------------------------------------------------------------------------------------------------------------------

