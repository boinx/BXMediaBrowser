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


open class LightroomCCContainer : Container
{
	class LightroomCCData
	{
		var album:LightroomCC.Albums.Resource
		let allowedMediaTypes:[Object.MediaType]
//		var assets:[LightroomCC.Asset]? = nil
		var containers:[Container]? = nil
		var objects:[Object]? = nil
//		var nextAccessPoint:String? = nil
//		var pageIndex:Int = 0
		var lastUsedFilter = LightroomCCFilter()
		
		init(with album:LightroomCC.Albums.Resource, allowedMediaTypes:[Object.MediaType])
		{
			self.album = album
			self.allowedMediaTypes = allowedMediaTypes
//			self.assets = nil
			self.containers = nil
			self.objects = nil
//			self.nextAccessPoint = nil
//			self.pageIndex = 0
		}
	}


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Setup
	
	/// Creates a new Container for the folder at the specified URL
	
	public required init(album:LightroomCC.Albums.Resource, allowedMediaTypes:[Object.MediaType], filter:LightroomCCFilter)
	{
		let data = LightroomCCData(with:album, allowedMediaTypes:allowedMediaTypes)
		
		super.init(
			identifier: "LightroomCC:Album:\(album.id)",
			icon: album.subtype.contains("set") ? "folder" : "rectangle.stack",
			name: album.payload.name,
			data: data,
			filter: filter,
			loadHandler: Self.loadContents)

//		Self.resetPaging(with:data,filter)
		
//		#if os(macOS)
//
//		self.observers += NotificationCenter.default.publisher(for:NSCollectionView.didScrollToEnd, object:self).sink
//		{
//			[weak self] _ in self?.load(with:nil)
//		}
//
//		#elseif os(iOS)
//		#warning("TODO: implement")
//		#endif
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
	
	
	class func resetPaging(with data:LightroomCCData,_ filter:LightroomCCFilter)
	{
//		data.nextAccessPoint = Self.intialAccessPoint(with:data,filter)
//		data.containers = nil
//		data.objects = nil
//		data.pageIndex = 0
		
		data.lastUsedFilter.searchString = filter.searchString
		data.lastUsedFilter.rating = filter.rating
		data.lastUsedFilter.sortType = filter.sortType
		data.lastUsedFilter.sortDirection = filter.sortDirection
	}
	
	
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
//			URLQueryItem(name:"limit", value:"50"),
//			URLQueryItem(name:"order_after", value:"-"),
		]
		
//		if !filter.searchString.isEmpty
//		{
//			urlComponents.queryItems? += URLQueryItem(name:"filter[fileName]", value:filter.searchString)
//		}
		
//		if filter.sortType == .creationDate
//		{
//			if filter.sortDirection == .ascending
//			{
//				urlComponents.queryItems? += URLQueryItem(name:"filter[asset/payload/importSource/fileName]", value:filter.searchString)
//			}
//			else
//			{
//				urlComponents.queryItems? += URLQueryItem(name:"captured_before", value:"3000-01-01T00:00:00")
//			}
//		}
//		else
//		{
//			if filter.sortDirection == .ascending
//			{
//				urlComponents.queryItems? += URLQueryItem(name:"order_after", value:"-")
//			}
//			else
//			{
//				urlComponents.queryItems? += URLQueryItem(name:"order_before", value:"")
//			}
//		}

		let string = urlComponents.url?.absoluteString ?? ""
		return string
	}
	
	
	/// Loads the (shallow) contents of this folder
	
	class func loadContents(for identifier:String, data:Any, filter:Object.Filter) async throws -> Loader.Contents
	{
		guard let data = data as? LightroomCCData else { throw Error.loadContentsFailed }
		guard let filter = filter as? LightroomCCFilter else { throw Error.loadContentsFailed }
		LightroomCC.log.debug {"\(Self.self).\(#function) \(identifier)"}
		
		let allowedMediaTypes = data.allowedMediaTypes
		let allowImages = allowedMediaTypes.contains(.image)
		let allowVideos = allowedMediaTypes.contains(.video)
		
		// When the filter has changed, then reset paging data
		
//		if data.lastUsedFilter != filter
//		{
//			Self.resetPaging(with:data,filter)
//		}
		
		// Find our child albums (parent is self) and create a Container for each child
		
		if data.containers == nil
		{
			let albumID = data.album.id
			let allAlbums = LightroomCC.shared.allAlbums
			let childAlbums = allAlbums.filter
			{
				guard let id = $0.payload.parent?.id else { return false }
				return id == albumID
			}

			var containers:[Container] = []

			for album in childAlbums
			{
				containers += LightroomCCContainer(album:album, allowedMediaTypes:allowedMediaTypes, filter:filter)
			}
			
			data.containers = containers
		}
		
		let containers = data.containers ?? []

		// Get another page of assets in this album
		
		if data.objects == nil
		{
			data.objects = []
			
			let accessPoint = Self.intialAccessPoint(with:data,filter)
			LightroomCC.log.debug {"\(Self.self).\(#function) accessPoint = \(accessPoint)"}
			
			let assets = try await self.allAssets(for:accessPoint)
//			let searchString = filter.searchString.lowercased()
			
			for asset in assets
			{
				let subtype = asset.subtype ?? ""
//				let identifier = LightroomCCObject.identifier(for:asset)
				
				// Filter by name and/or rating
				
//				guard searchString.isEmpty || asset.name.lowercased().contains(searchString) else { continue }
//				guard filter.rating == 0 || StatisticsController.shared.rating(for:identifier) >= filter.rating else { continue }
				
				// Wrap asset in an Object
				
				if subtype == "image" && allowImages
				{
					let object = LightroomCCImageObject(with:asset)
					data.objects?.append(object)
				}
				else if subtype == "video" && allowVideos
				{
					let object = LightroomCCVideoObject(with:asset)
					data.objects?.append(object)
				}
			}
		}
		
//		guard let accessPoint = data.nextAccessPoint else { return (data.containers ?? [],data.objects ?? []) }
//		LightroomCC.log.debug {"\(Self.self).\(#function) \(identifier) - PAGE \(data.pageIndex)"}
//		let page:LightroomCC.AlbumAssets = try await LightroomCC.shared.getData(from:accessPoint, debugLogging:false)
//
////		dump(page)
////		dump(page.links)
////		print("\n\n")
		
		let searchString = filter.searchString.lowercased()
		var objects:[Object] = []
		
		for object in data.objects ?? []
		{
//			let asset = resource.asset
//			let subtype = asset.subtype ?? ""
//			let identifier = LightroomCCObject.identifier(for:asset)
			
			// Filter by name and/or rating
			
			guard searchString.isEmpty || object.name.lowercased().contains(searchString) else { continue }
			guard filter.rating == 0 || StatisticsController.shared.rating(for:object) >= filter.rating else { continue }
			
			objects += object
		}
		
//		data.pageIndex += 1
//
//		// If there is a next page, then store its accessPoint link
//
//		if let base = page.base, let next = page.links?.next?.href
//		{
//			data.nextAccessPoint = base + next
//		}
//		else
//		{
//			data.nextAccessPoint = nil
//		}
		
		// Sort according to specified sort order
		
//		let objects = data.objects ?? []
		filter.sort(&objects)
		
		// Return contents
		
		return (containers,objects)
	}


	private class func allAssets(for accessPoint:String) async throws -> [LightroomCC.Asset]
	{
		var assets:[LightroomCC.Asset] = []
		var nextAccessPoint:String? = accessPoint
		var i = 0
		
		// Iterate through all pages
		
		while nextAccessPoint != nil
		{
			// Get next page and append to assets array
			
			let page:LightroomCC.AlbumAssets = try await LightroomCC.shared.getData(from:nextAccessPoint!, debugLogging:false)
			assets += page.resources.map { $0.asset }
			
			i += 1
			LightroomCC.log.debug {"\(Self.self).\(#function) PAGE \(i)"}
			
			// Is there yet another page?
			
			if let base = page.base, let next = page.links?.next?.href
			{
				nextAccessPoint = base + next
			}
			else
			{
				nextAccessPoint = nil
			}
		}
		
		return assets
	}


//	private class func safelyAdd(_ object:LightroomCCObject, to data:LightroomCCData)
//	{
//		let id = object.identifier
//
//		// If we do not have an array yet, then create an empty one
//
//		if data.objects == nil
//		{
//			data.objects = []
//		}
//
//		// If the new object is already in the array, then replace the old with the new one
//
//		if let i = data.objects?.firstIndex(where:{ $0.identifier == id })
//		{
//			data.objects?[i] = object
//		}
//
//		// Otherwise just append at the end
//
//		else
//		{
//			data.objects?.append(object)
//		}
//	}
}


//----------------------------------------------------------------------------------------------------------------------

