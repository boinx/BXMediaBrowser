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


import Photos


//----------------------------------------------------------------------------------------------------------------------


public class PhotosContainer : Container
{
	var observer = PhotosChangeObserver()


//----------------------------------------------------------------------------------------------------------------------


 	public init(mediaType:PHAssetMediaType)
	{
		let identifier = "PhotosSource:Library"
		let icon = "photo.on.rectangle"
		let name = "Library"

		let options = PHFetchOptions()
		options.sortDescriptors = [NSSortDescriptor(key:"creationDate", ascending:true)]
		let assets = PHAsset.fetchAssets(with:mediaType, options:options)

		super.init(
			identifier:identifier,
			info:assets,
			icon:icon,
			name:name,
			loadHandler:Self.loadContents)

		self.commonInit()
	}
	

  	public init(with albums:PHFetchResult<PHCollection>, identifier:String, name:String)
	{
		super.init(
			identifier:identifier,
			info:albums,
			name:name,
			loadHandler:Self.loadContents)

		self.commonInit()
	}
	
	
	public init(with collectionList:PHCollectionList)
	{
		let identifier = "PhotosSource:\(collectionList.localIdentifier)"
		let name = collectionList.localizedTitle ?? "Album"
	
		super.init(
			identifier:identifier,
			info:collectionList,
			name:name,
			loadHandler:Self.loadContents)

		self.commonInit()
	}


	public init(with assetCollection:PHAssetCollection)
	{
		let identifier = "PhotosSource:\(assetCollection.localIdentifier)"
		let name = assetCollection.localizedTitle ?? "Album"
		
		super.init(
			identifier:identifier,
			info:assetCollection,
			icon:"rectangle.stack",
			name:name,
			loadHandler:Self.loadContents)

		self.commonInit()
	}
    

	public init(with collection:PHCollection)
	{
		let identifier = "PhotosSource:\(collection.localIdentifier)"
		let name = collection.localizedTitle ?? "Album"

		super.init(
			identifier:identifier,
			info:collection,
			name:name,
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
	
	
//----------------------------------------------------------------------------------------------------------------------


	/// Loads the (shallow) contents of this folder
	
	class func loadContents(for identifier:String, info:Any) async throws -> Loader.Contents
	{
		var containers:[Container] = []
		var objects:[Object] = []
		
		// PHCollectionList (Folder) - can contain subfolders and albums, but no images (PHAssets)
		
		if let collectionList = info as? PHCollectionList
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
							containers += PhotosContainer(with:collectionList)
						}
						else if let assetCollection = collection as? PHAssetCollection
						{
							containers += PhotosContainer(with:assetCollection)
						}
						else if let collection = collection as? PHCollection
						{
							containers += PhotosContainer(with:collection)
						}
					}
				}
				
				// Album
				
				else if let assetCollection = collection as? PHAssetCollection
				{
					let container = PhotosContainer(with:assetCollection)
					containers += container
				}
			}
		}
		
		// PHAssetCollection (Album) - only contains images (PHAssets) but no subfolders
		
		else if let album = info as? PHAssetCollection
		{
			let assets = PHAsset.fetchAssets(in:album, options:nil)

			for i in 0 ..< assets.count
			{
				let asset = assets[i]
				objects += PhotosObject(with:asset)
			}
		}
		
		//
		
		else if let collection = info as? PHCollection
		{
			print("hmmm")
		}
		
		// Datatype not determined yet, so get it from a PHFetchResult
		
		else if let items = info as? PHFetchResult<PHObject>
		{
			for i in 0 ..< items.count
			{
				let item = items[i]
				
				if let collectionList = item as? PHCollectionList
				{
					containers += PhotosContainer(with:collectionList)
				}
				else if let assetCollection = item as? PHAssetCollection
				{
					containers += PhotosContainer(with:assetCollection)
				}
				else if let collection = item as? PHCollection
				{
					containers += PhotosContainer(with:collection)
				}
				else if let asset = item as? PHAsset
				{
					objects += PhotosObject(with:asset)
				}
				else
				{
					print("\(item)")
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
			if let object = self.info as? PHObject
			{
				if let object = change.changeDetails(for:object)
				{
					self.info = object
					self.load()
				}
			}
			else if let fetchResult = self.info as? PHFetchResult<PHObject>
			{
				if let fetchResult = change.changeDetails(for:fetchResult)
				{
					self.info = fetchResult
					self.load()
				}
			}
		}
    }
}


//----------------------------------------------------------------------------------------------------------------------
