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


 	public init(mediaType:PHAssetMediaType, filter:Object.Filter)
	{
		let identifier = "PhotosSource:Library"
		let icon = "photo.on.rectangle"
		let name = "Library"

		let options = PHFetchOptions()
		options.sortDescriptors = [NSSortDescriptor(key:"creationDate", ascending:true)]
		let assets = PHAsset.fetchAssets(with:mediaType, options:options)

		super.init(
			identifier:identifier,
			icon:icon,
			name:name,
			data:assets,
			filter:filter,
			loadHandler:Self.loadContents)

		self.commonInit()
	}
	

  	public init(with albums:PHFetchResult<PHCollection>, identifier:String, name:String, filter:Object.Filter)
	{
		super.init(
			identifier:identifier,
			name:name,
			data:albums,
			filter:filter,
			loadHandler:Self.loadContents)

		self.commonInit()
	}
	
	
	public init(with collectionList:PHCollectionList, filter:Object.Filter)
	{
		let identifier = "PhotosSource:\(collectionList.localIdentifier)"
		let name = collectionList.localizedTitle ?? "Album"
	
		super.init(
			identifier:identifier,
			name:name,
			data:collectionList,
			filter:filter,
			loadHandler:Self.loadContents)

		self.commonInit()
	}


	public init(with assetCollection:PHAssetCollection, filter:Object.Filter)
	{
		let identifier = "PhotosSource:\(assetCollection.localIdentifier)"
		let name = assetCollection.localizedTitle ?? "Album"
		
		super.init(
			identifier:identifier,
			icon:"rectangle.stack",
			name:name,
			data:assetCollection,
			filter:filter,
			loadHandler:Self.loadContents)

		self.commonInit()
	}
    

	public init(with collection:PHCollection, filter:Object.Filter)
	{
		let identifier = "PhotosSource:\(collection.localIdentifier)"
		let name = collection.localizedTitle ?? "Album"

		super.init(
			identifier:identifier,
			name:name,
			data:collection,
			filter:filter,
			loadHandler:Self.loadContents)

		self.commonInit()
	}


	func commonInit()
	{
		observer.didChangeHandler =
		{
			[weak self] in self?.didChange($0)
		}
	}
	
	
	// Folders can be expanded, because they have sub-containers
	
	override var canExpand: Bool
	{
		if self.identifier == "PhotosSource:Library" { return false }
		if self.identifier == "PhotosSource:Albums" { return true }
		return data is PHCollectionList
	}
	
	
//----------------------------------------------------------------------------------------------------------------------


	/// Loads the (shallow) contents of this folder
	
	class func loadContents(for identifier:String, data:Any, filter:Object.Filter) async throws -> Loader.Contents
	{
		PhotosSource.log.debug {"\(Self.self).\(#function) \(identifier)"}

		var containers:[Container] = []
		var objects:[Object] = []
		
		// PHCollectionList (Folder) - can contain subfolders and albums, but no images (PHAssets)
		
		if let collectionList = data as? PHCollectionList
		{
			let collections = PHCollection.fetchCollections(in:collectionList, options:nil)
			
			for i in 0 ..< collections.count
			{
				let collection = collections[i]
				
				// Subfolder
				
				if let collectionList = collection as? PHCollectionList
				{
					let collections = PHCollection.fetchCollections(in:collectionList, options:nil)
				
					for i in 0..<collections.count
					{
						let collection = collections[i]

						if let collectionList = collection as? PHCollectionList
						{
							containers += PhotosContainer(with:collectionList, filter:filter)
						}
						else if let assetCollection = collection as? PHAssetCollection
						{
							containers += PhotosContainer(with:assetCollection, filter:filter)
						}
						else if let collection = collection as? PHCollection
						{
							containers += PhotosContainer(with:collection, filter:filter)
						}
					}
				}
				
				// Album
				
				else if let assetCollection = collection as? PHAssetCollection
				{
					let container = PhotosContainer(with:assetCollection, filter:filter)
					containers += container
				}
			}
		}
		
		// PHAssetCollection (Album) - only contains images (PHAssets) but no subfolders
		
		else if let album = data as? PHAssetCollection
		{
			let assets = PHAsset.fetchAssets(in:album, options:nil)

			for i in 0 ..< assets.count
			{
				let asset = assets[i]
				objects += PhotosObject(with:asset)
			}
		}
		
		// Not sure how to deal with this case
		
		else if let collection = data as? PHCollection
		{
			PhotosSource.log.error {"\(Self.self).\(#function) ERROR encountered abstract PHCollection"}
		}
		
		// Datatype not determined yet, so get it from a PHFetchResult
		
		else if let items = data as? PHFetchResult<PHObject>
		{
			for i in 0 ..< items.count
			{
				let item = items[i]
				
				if let collectionList = item as? PHCollectionList
				{
					containers += PhotosContainer(with:collectionList, filter:filter)
				}
				else if let assetCollection = item as? PHAssetCollection
				{
					containers += PhotosContainer(with:assetCollection, filter:filter)
				}
				else if let collection = item as? PHCollection
				{
					containers += PhotosContainer(with:collection, filter:filter)
				}
				else if let asset = item as? PHAsset
				{
					objects += PhotosObject(with:asset)
				}
				else
				{
					PhotosSource.log.error {"\(Self.self).\(#function) ERROR unknown data type \(item)"}
				}
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
	
    @MainActor override var localizedObjectCount:String
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
