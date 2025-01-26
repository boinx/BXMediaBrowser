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


open class LightroomCCContainerAllPhotos : Container, AppLifecycleMixin, ScrollToBottomMixin
{
	class LightroomCCData
	{
		let allowedMediaTypes:[Object.MediaType]
		var cachedObjects:[Object]? = nil
		var objectMap:[String:Object] = [:]
		var nextAccessPoint:String? = nil
		
		init(allowedMediaTypes:[Object.MediaType])
		{
			self.allowedMediaTypes = allowedMediaTypes
			self.cachedObjects = nil
			self.nextAccessPoint = nil
		}
	}

	static let loadNextPageOfAssets = Notification.Name("LightroomCCContainer.loadNextPage")
	
	
//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Setup
	
	/// Creates a new Container for the folder at the specified URL
	
	public required init(allowedMediaTypes:[Object.MediaType], filter:LightroomCCFilter, in library:Library?)
	{
		let data = LightroomCCData(allowedMediaTypes:allowedMediaTypes)
		let identifier = "LightroomCC:AllPhotos"
		let icon = "photo.on.rectangle"
		let name = allowedMediaTypes == [.video] ?
			NSLocalizedString("All Videos", tableName:"LightroomCC", bundle:.BXMediaBrowser, comment:"Container Name") :
			NSLocalizedString("All Photos", tableName:"LightroomCC", bundle:.BXMediaBrowser, comment:"Container Name")
		
		super.init(
			identifier: identifier,
			icon: icon,
			name: name,
			data: data,
			filter: filter,
			loadHandler: Self.loadContents,
			in: library)

		// When scrolling to bottom, load the next page of assets
		
		self.registerScrollToBottomHandler()
		{
			[weak self] in self?.load(with:nil, in:library)
		}
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
		false
	}

	/// Returns the list of allowed sort Kinds for this Container
		
	override open var allowedSortTypes:[Object.Filter.SortType]
	{
		[.rating,.useCount]
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
		data.cachedObjects = nil
		data.objectMap = [:]
		data.nextAccessPoint = nil
	}
	
	
	/// Returns the accessPoint URL for the first page of data
	
	class func intialAccessPoint(with data:LightroomCCData,_ filter:LightroomCCFilter) -> String
	{
		let catalogID = LightroomCC.shared.catalogID
		let allowedMediaTypes = data.allowedMediaTypes
		let mediaTypes = allowedMediaTypes.map { $0.rawValue } .joined(separator:";")

		let accessPoint = "https://lr.adobe.io/v2/catalogs/\(catalogID)/assets"
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
		
//		filter.sort(&objects)
		
		// If there is another page then trigger reloading
		
		if data.nextAccessPoint != nil
		{
			DispatchQueue.main.async
			{
				NotificationCenter.default.post(name: Self.loadNextPageOfAssets, object:identifier)
			}
		}
		
		// Return contents
		
		return ([],objects)
	}


	/// Returns the next page of assets, and if available the accessPoint link to the following page
	
	private class func nextPageAssets(for accessPoint:String) async throws -> ([LightroomCC.Asset],String?)
	{
		try await Tasks.canContinue()
		
		LightroomCC.log.debug {"\(Self.self).\(#function) accessPoint = \(accessPoint)"}
		let page:LightroomCC.CatalogAssets = try await LightroomCC.shared.getData(from:accessPoint, debugLogging:false)
		
		/// Convert CatalogAssets to regular Assets (because that's how the following code expects the data)
		
		let assets = page.resources.map
		{
			LightroomCC.Asset(
				base: page.base,
				id: $0.id,
				subtype: $0.subtype,
				updated: $0.updated,
				payload: LightroomCC.Asset.Payload(
					captureDate:$0.payload.captureDate,
					importSource: $0.payload.importSource,
					xmp:nil,
					video: $0.payload.video,
					ratings:nil),
				links: $0.links)
		}
			
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
	}
}


//----------------------------------------------------------------------------------------------------------------------

