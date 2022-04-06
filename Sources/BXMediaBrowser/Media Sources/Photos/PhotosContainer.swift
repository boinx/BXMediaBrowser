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
import Photos


//----------------------------------------------------------------------------------------------------------------------


public class PhotosContainer : Container
{
	var observer = PhotosChangeObserver()


//----------------------------------------------------------------------------------------------------------------------


 	public init(identifier:String, icon:String, name:String, data:Any, filter:Object.Filter)
	{
		PhotosSource.log.debug {"\(Self.self).\(#function) \(identifier)"}
		
		super.init(
			identifier:identifier,
			icon:icon,
			name:name,
			data:data,
			filter:filter,
			loadHandler:Self.loadContents,
			removeHandler:nil)

		self.commonInit()
	}
	
//	public init(mediaType:PHAssetMediaType, filter:Object.Filter)
//	{
//		let identifier = "PhotosSource:Library"
//		let icon = "photo.on.rectangle"
//		let name = "Library"
//
//		let options = PHFetchOptions()
//		options.sortDescriptors = [NSSortDescriptor(key:"creationDate", ascending:true)]
//		let assets = PHAsset.fetchAssets(with:mediaType, options:options)
//
//		super.init(
//			identifier:identifier,
//			icon:icon,
//			name:name,
//			data:assets,
//			filter:filter,
//			loadHandler:Self.loadContents)
//
//		self.commonInit()
//	}
//
//
//  	public init(with albums:PHFetchResult<PHCollection>, identifier:String, name:String, filter:Object.Filter)
//	{
//		super.init(
//			identifier:identifier,
//			name:name,
//			data:albums,
//			filter:filter,
//			loadHandler:Self.loadContents)
//
//		self.commonInit()
//	}
//
//
//	public init(with collectionList:PHCollectionList, icon:String? = nil, filter:Object.Filter)
//	{
//		let identifier = "PhotosSource:\(collectionList.localIdentifier)"
//		let name = collectionList.localizedTitle ?? "Album"
//
//		super.init(
//			identifier:identifier,
//			icon:icon,
//			name:name,
//			data:collectionList,
//			filter:filter,
//			loadHandler:Self.loadContents)
//
//		self.commonInit()
//	}
//
//
//	public init(with assetCollection:PHAssetCollection, icon:String? = "rectangle.stack", filter:Object.Filter)
//	{
//		let identifier = "PhotosSource:\(assetCollection.localIdentifier)"
//		let name = assetCollection.localizedTitle ?? "Album"
//
//		super.init(
//			identifier:identifier,
//			icon:icon,
//			name:name,
//			data:assetCollection,
//			filter:filter,
//			loadHandler:Self.loadContents)
//
//		self.commonInit()
//	}
//
//
//	public init(with collection:PHCollection, filter:Object.Filter)
//	{
//		let identifier = "PhotosSource:\(collection.localIdentifier)"
//		let name = collection.localizedTitle ?? "Album"
//
//		super.init(
//			identifier:identifier,
//			name:name,
//			data:collection,
//			filter:filter,
//			loadHandler:Self.loadContents)
//
//		self.commonInit()
//	}


	func commonInit()
	{
		observer.didChangeHandler =
		{
			[weak self] in self?.didChange($0)
		}
	}
	
	
	override nonisolated open var mediaTypes:[Object.MediaType]
	{
		return [.image]
	}

	// Folders can be expanded, because they have sub-containers
	
	override open var canExpand: Bool
	{
		if self.identifier == "PhotosSource:Library" { return false }
		if self.identifier == "PhotosSource:Albums" { return true }
		guard let data = self.data as? PhotosData else { return false }
		
		switch data
		{
			case .folder: return true
			default: return false
		}
	}
	
	
//----------------------------------------------------------------------------------------------------------------------

	
	/// Loads the (shallow) contents of this folder
	
	class func loadContents(for identifier:String, data:Any, filter:Object.Filter) async throws -> Loader.Contents
	{
		PhotosSource.log.debug {"\(Self.self).\(#function) \(identifier)"}

		var containers:[Container] = []
		var objects:[Object] = []
		var assetsFetchResult:PHFetchResult<PHAsset>? = nil
		
		guard let data = data as? PhotosData else { return (containers,objects) }
        let sortOptions = PHFetchOptions()
        sortOptions.sortDescriptors = [NSSortDescriptor(key:"creationDate", ascending:true)]

		// Load containers

		switch data
		{
			case .library(let allAssets):

				assetsFetchResult = allAssets

			case .album(let assetCollection):

				assetsFetchResult = PHAsset.fetchAssets(in:assetCollection, options:sortOptions)

			case .folder(let collections):

				for collection in collections
				{
					if let assetCollection = collection as? PHAssetCollection
					{
						let icon = assetCollection.assetCollectionType == .smartAlbum ?
							"gearshape" :
							"rectangle.stack"
							
						containers += PhotosContainer(
							identifier: "PhotosSource:\(assetCollection.localIdentifier)",
							icon: icon,
							name: assetCollection.localizedTitle ?? "",
							data: PhotosData.album(collection:assetCollection),
							filter: filter)

						assetsFetchResult = PHAsset.fetchAssets(in:assetCollection, options:sortOptions)
					}
					else if let collectionList = collection as? PHCollectionList
					{
						let fetchResult = PHCollection.fetchCollections(in:collectionList, options:nil)
						let collections = PhotosData.items(for:fetchResult)

						containers += PhotosContainer(
							identifier: "PhotosSource:\(collectionList.localIdentifier)",
							icon: "folder",
							name: collectionList.localizedTitle ?? "",
							data: PhotosData.folder(collections:collections),
							filter: filter)
					}
				}
		}

		// Load objects

		if let assetsFetchResult = assetsFetchResult
		{
			for i in 0 ..< assetsFetchResult.count
			{
				let asset = assetsFetchResult[i]
				objects += PhotosObject(with:asset)
			}
		}
		

		return (containers,objects)
	}


//----------------------------------------------------------------------------------------------------------------------


	public func didChange(_ change:PHChange)
    {
		DispatchQueue.main.async
		{
			if let object = self.data as? PHObject
			{
				if let object = change.changeDetails(for:object)
				{
					self.data = object
					self.load()
				}
			}
			else if let fetchResult = self.data as? PHFetchResult<PHObject>
			{
				if let fetchResult = change.changeDetails(for:fetchResult)
				{
					self.data = fetchResult
					self.load()
				}
			}
		}
    }


	/// Returns a description of the contents of this Container
	
    @MainActor override open var localizedObjectCount:String
    {
		let n = self.objects.count
		let str = n.localizedImagesString
		return str
    }


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Sorting
	
	/// Returns the list of allowed sort Kinds for this Container
		
	override open var allowedSortTypes:[Object.Filter.SortType] { [.creationDate,.rating] }
}


//----------------------------------------------------------------------------------------------------------------------
