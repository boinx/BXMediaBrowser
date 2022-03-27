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
		var nextAccessPoint:String? = nil
		var containers:[Container]? = nil
		var objects:[Object]? = nil
		var pageIndex:Int = 0
		
		init(with album:LightroomCC.Albums.Resource, allowedMediaTypes:[Object.MediaType])
		{
			self.album = album
			self.allowedMediaTypes = allowedMediaTypes
			self.nextAccessPoint = nil
			self.containers = nil
			self.objects = nil
			self.pageIndex = 0
		}
	}


//----------------------------------------------------------------------------------------------------------------------


	/// Creates a new Container for the folder at the specified URL
	
	public required init(album:LightroomCC.Albums.Resource, allowedMediaTypes:[Object.MediaType], filter:Object.Filter)
	{
		super.init(
			identifier: "LightroomCC:Album:\(album.id)",
			icon: album.subtype.contains("set") ? "folder" : "rectangle.stack",
			name: album.payload.name,
			data: LightroomCCData(with:album, allowedMediaTypes:allowedMediaTypes),
			filter: filter,
			loadHandler: Self.loadContents)

		self.resetPaging()
		
		#if os(macOS)
		
		self.observers += NotificationCenter.default.publisher(for:NSCollectionView.didScrollToEnd, object:self).sink
		{
			[weak self] _ in self?.load(with:nil)
		}
		
		#elseif os(iOS)
		#warning("TODO: implement")
		#endif
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
		[.alphabetical,.creationDate,.rating]
	}


	// Return "Images" instead of "Items"
	
    @MainActor override open var localizedObjectCount:String
    {
		self.objects.count.localizedImagesString
    }
    
//	/// Returns the list of allowed sort Kinds for this Container
//
//	override open var allowedSortTypes:[Object.Filter.SortType]
//	{
//		[]
//	}


//----------------------------------------------------------------------------------------------------------------------


	func resetPaging()
	{
		guard let data = data as? LightroomCCData else { return }

		let catalogID = LightroomCC.shared.catalogID
		let albumID = data.album.id
		
		let allowedMediaTypes = data.allowedMediaTypes
		let subtype = allowedMediaTypes
			.map { $0.rawValue }
			.joined(separator:";")

		data.nextAccessPoint = "https://lr.adobe.io/v2/catalogs/\(catalogID)/albums/\(albumID)/assets?limit=50&subtype=\(subtype)&embed=asset;links"
		data.containers = nil
		data.objects = nil
		data.pageIndex = 0
	}
	
	
	/// Loads the (shallow) contents of this folder
	
	class func loadContents(for identifier:String, data:Any, filter:Object.Filter) async throws -> Loader.Contents
	{
		guard let data = data as? LightroomCCData else { throw Error.loadContentsFailed }

		let allowedMediaTypes = data.allowedMediaTypes
		let allowImages = allowedMediaTypes.contains(.image)
		let allowVideos = allowedMediaTypes.contains(.video)
		
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
		
		// Get another page of assets in this album
		
		guard let accessPoint = data.nextAccessPoint else { return (data.containers ?? [],data.objects ?? []) }
		LightroomCC.log.debug {"\(Self.self).\(#function) \(identifier) - PAGE \(data.pageIndex)"}
		let page:LightroomCC.AlbumAssets = try await LightroomCC.shared.getData(from:accessPoint, debugLogging:false)

//		dump(page)
//		print("\n\n")

		for resource in page.resources
		{
			let asset = resource.asset
			let subtype = asset.subtype ?? ""
			let identifier = LightroomCCObject.identifier(for:asset)
			
			// Filter by name and/or rating
			
			guard filter.searchString.isEmpty || asset.name.contains(filter.searchString) else { continue }
			guard filter.rating == 0 || StatisticsController.shared.rating(for:identifier) >= filter.rating else { continue }
			
			// Wrap asset in an Object
			
			if subtype == "image" && allowImages
			{
				let object = LightroomCCObject(with:asset)
				self.safelyAdd(object, to:data)
			}
			else if subtype == "video" && allowVideos
			{
				let object = LightroomCCObject(with:asset)
				self.safelyAdd(object, to:data)
			}
		}
		
		data.pageIndex += 1

		// If there is a next page, then store its accessPoint link
		
		if let base = page.base, let next = page.links?.next?.href
		{
			data.nextAccessPoint = base + next
		}
		else
		{
			data.nextAccessPoint = nil
		}
		
		// Sort according to specified sort order
		
		let containers = data.containers ?? []
		var objects:[Object] = data.objects ?? []
		filter.sort(&objects)
		
		// Return contents
		
		return (containers,objects)
	}


	private class func safelyAdd(_ object:LightroomCCObject, to data:LightroomCCData)
	{
		let id = object.identifier
		
		// If we do not have an array yet, then create an empty one
		
		if data.objects == nil
		{
			data.objects = []
		}
		
		// If the new object is already in the array, then replace the old with the new one
		
		if let i = data.objects?.firstIndex(where:{ $0.identifier == id })
		{
			data.objects?[i] = object
		}
		
		// Otherwise just append at the end
		
		else
		{
			data.objects?.append(object)
		}
	}
}


//----------------------------------------------------------------------------------------------------------------------

