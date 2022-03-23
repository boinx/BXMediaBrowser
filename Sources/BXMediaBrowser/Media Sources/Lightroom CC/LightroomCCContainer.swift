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
	/// Creates a new Container for the folder at the specified URL
	
	public required init(album:LightroomCC.Albums.Resource, filter:Object.Filter)
	{
		super.init(
			identifier: album.id,
			name: album.payload.name,
			data: album,
			filter: filter,
			loadHandler: Self.loadContents)
	}


//----------------------------------------------------------------------------------------------------------------------


	// Folders can be expanded, but albums cannot
	
	override open var canExpand: Bool
	{
		guard let album = self.data as? LightroomCC.Albums.Resource else { return false }
		return album.subtype.contains("set")
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


	/// Loads the (shallow) contents of this folder
	
	class func loadContents(for identifier:String, data:Any, filter:Object.Filter) async throws -> Loader.Contents
	{
		FolderSource.log.debug {"\(Self.self).\(#function) \(identifier)"}

		var containers:[Container] = []
		var objects:[Object] = []

		let catalogID = LightroomCC.shared.catalogID
		let allAlbums = LightroomCC.shared.allAlbums
	
		// Find our child albums (parent is self)
		
		let childAlbums = allAlbums.filter
		{
			guard let id = $0.payload.parent?.id else { return false }
			return id == identifier
		}
		
		// Create a Container for each child album
		
		for album in childAlbums
		{
			containers += LightroomCCContainer(album:album, filter:filter)
		}

		// Get the IDs for all assets in this album
		
		let albumContents:LightroomCC.AlbumAssets = try await LightroomCC.shared.getData(from:"https://lr.adobe.io/v2/catalogs/\(catalogID)/albums/\(identifier)/assets")

		let assetIDs = albumContents.resources.map
		{
			$0.asset.id
		}
		
		// Get the info for each asset and wrap it in an Object
		
		let assets = try await withThrowingTaskGroup(of:LightroomCC.Asset.self, returning:[LightroomCC.Asset].self)
		{
			group in

			for assetID in assetIDs
			{
				group.addTask
				{
					try await LightroomCC.shared.getData(from:"https://lr.adobe.io/v2/catalogs/\(catalogID)/assets/\(assetID)")
				}
			}
				
			var assets:[LightroomCC.Asset] = []

			for try await asset in group
			{
				assets += asset
			}

			return assets
		}

//		let assets = try await group.result
		
		for asset in assets
		{
//			let asset:LightroomCC.Asset = try await LightroomCC.shared.getData(from:"https://lr.adobe.io/v2/catalogs/\(catalogID)/assets/\(assetID)")
			objects += LightroomCCObject(with:asset)
		}
				
		// Sort according to specified sort order
		
		filter.sort(&objects)
		
		// Return contents
		
		return (containers,objects)
	}
	
	
//----------------------------------------------------------------------------------------------------------------------


//----------------------------------------------------------------------------------------------------------------------


	/// Encodes/decodes a PexelsFilter from Data
	
//	var filterData:Data?
//	{
//		get
//		{
//			guard let pexelsData = self.data as? PexelsData else { return nil }
//			let filter = pexelsData.lastUsedFilter
//			let data = try? JSONEncoder().encode(filter)
//			return data
//		}
//		
//		set
//		{
//			guard let data = newValue else { return }
//			guard let pexelsData = self.data as? PexelsData else { return }
//			guard let filter = try? JSONDecoder().decode(PexelsFilter.self, from:data) else { return }
//			pexelsData.lastUsedFilter = filter
//		}
//	}


//----------------------------------------------------------------------------------------------------------------------


	/// Returns a textual description of the filter params (for displaying in the UI)
	
//	var description:String
//	{
//		guard let filter = self.filter as? PexelsFilter else { return "" }
//		return Self.description(with:filter)
//	}
//
//	/// Returns a textual description of the filter params (for displaying in the UI)
//
//	class func description(with filter:PexelsFilter) -> String
//	{
//		let searchString = filter.searchString
//		let orientation = filter.orientation != .any ? filter.orientation.localizedName : ""
//		let color = filter.color != .any ? filter.color.localizedName : ""
//
//		var description = searchString
//		if !orientation.isEmpty { description += ", \(orientation)" }
//		if !color.isEmpty { description += ", \(color)" }
//		return description
//	}
}


//----------------------------------------------------------------------------------------------------------------------

