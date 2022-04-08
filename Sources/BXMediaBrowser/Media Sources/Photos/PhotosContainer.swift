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
	/// Create a new PhotosContainer
	
 	public init(identifier:String, icon:String, name:String, data:Any, filter:Object.Filter)
	{
		Photos.log.debug {"\(Self.self).\(#function) \(identifier)"}
		
		super.init(
			identifier:identifier,
			icon:icon,
			name:name,
			data:data,
			filter:filter,
			loadHandler:Self.loadContents,
			removeHandler:nil)

		observer.didChangeHandler =
		{
			[weak self] in self?.didChange($0)
		}
	}


	/// Returns the allowed mediaTypes in this Container
	
	override nonisolated open var mediaTypes:[Object.MediaType]
	{
 		guard let filter = filter as? PhotosFilter else { return [] }
		return filter.allowedMediaTypes
	}

	/// Returns the list of allowed sort Kinds for this Container
		
	override open var allowedSortTypes:[Object.Filter.SortType]
	{
		[.creationDate,.rating]
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
			case .dateInterval(let unit,_,_): return unit != .day
			default: return false
		}
	}
	
	/// Returns a description of the contents of this Container
	
    @MainActor override open var localizedObjectCount:String
    {
		let n = self.objects.count
		
		if mediaTypes == [.image]
		{
			return n.localizedImagesString
		}
		else if mediaTypes == [.video]
		{
			return n.localizedVideosString
		}
		
		return n.localizedItemsString
    }
	
	
//----------------------------------------------------------------------------------------------------------------------

	
	// MARK: - Loading
	
	/// Loads the (shallow) contents of this Container
	
	class func loadContents(for identifier:String, data:Any, filter:Object.Filter) async throws -> Loader.Contents
	{
		guard let data = data as? PhotosData else { return ([],[]) }
 		guard let filter = filter as? PhotosFilter else { return ([],[]) }

		Photos.log.debug {"\(Self.self).\(#function) \(identifier)"}

		let startTime = CFAbsoluteTimeGetCurrent()
		defer
		{
			let duration = CFAbsoluteTimeGetCurrent() - startTime
			Photos.log.debug {"\(Self.self).\(#function) \(identifier) loading time = \(duration)s "}
		}
		
		var containers:[Container] = []
		var objects:[Object] = []
		let fetchOptions = filter.assetFetchOptions
		var assetsFetchResult:PHFetchResult<PHAsset>? = nil

		// Load sub-containers

		switch data
		{
			// The library contains only assets, but not sub-containers
			
			case .library(let allAssets):

				assetsFetchResult = allAssets

			// An album contains only assets, but not sub-containers
			
			case .album(let assetCollection):

				assetsFetchResult = PHAsset.fetchAssets(in:assetCollection, options:fetchOptions)

			// A folder contains sub-containers (either albums or folders)
			
			case .folder(let collections):

				for collection in collections
				{
					if let assetCollection = collection as? PHAssetCollection
					{
						let icon = assetCollection.assetCollectionType == .smartAlbum ?
							"gearshape" :
							"rectangle.stack"
							
						containers += PhotosContainer(
							identifier: "Photos:Album:\(assetCollection.localIdentifier)",
							icon: icon,
							name: assetCollection.localizedTitle ?? "",
							data: PhotosData.album(collection:assetCollection),
							filter: filter)

						assetsFetchResult = PHAsset.fetchAssets(in:assetCollection, options:fetchOptions)
					}
					else if let collectionList = collection as? PHCollectionList
					{
						let fetchResult = PHCollection.fetchCollections(in:collectionList, options:nil)
						let collections = PhotosData.items(for:fetchResult)

						containers += PhotosContainer(
							identifier: "Photos:Folder:\(collectionList.localIdentifier)",
							icon: "folder",
							name: collectionList.localizedTitle ?? "",
							data: PhotosData.folder(collections:collections),
							filter: filter)
					}
					else
					{
					}
				}
			
			// A DateInterval let you drill down by year, month, day
			
			case .dateInterval(let unit, let assetCollection, let subCollections):
			
				switch unit
				{
					case .era:
					
						for (interval,collection) in subCollections // years
						{
							let year = interval.start.year
							let id = "\(year)"

							let monthCollections = PHAssetCollection.monthsCollections(
								year: year,
								mediaType: filter.assetMediaType)
							
							containers += PhotosContainer(
								identifier: "Photos:Date:\(id)",
								icon: "folder",
								name: collection.localizedTitle ?? id,
								data: PhotosData.dateInterval(unit:.year, assetCollection:collection, subCollections:monthCollections),
								filter: filter)
						}

					case .year:
					
						for (interval,collection) in subCollections // months of the year
						{
							let year = interval.start.year
							let month = interval.start.month
							let id = "\(year)/\(month)"

							let dayCollections = PHAssetCollection.daysCollections(
								year: year, month:month,
								mediaType: filter.assetMediaType)
							
							containers += PhotosContainer(
								identifier: "Photos:Date:\(id)",
								icon: "folder",
								name: collection.localizedTitle ?? id,
								data: PhotosData.dateInterval(unit:.month, assetCollection:collection, subCollections:dayCollections),
								filter: filter)
						}
					
					case .month:
					
						for (interval,collection) in subCollections // days of the month
						{
							let year = interval.start.year
							let month = interval.start.month
							let day = interval.start.day
							let id = "\(year)/\(month)/\(day)"
							
							containers += PhotosContainer(
								identifier: "Photos:Date:\(id)",
								icon: "folder",
								name: collection.localizedTitle ?? id,
								data: PhotosData.dateInterval(unit:.day, assetCollection:collection, subCollections:[]),
								filter: filter)
						}
					
					default: break
				}
				
				if let assetCollection = assetCollection
				{
					assetsFetchResult = PHAsset.fetchAssets(in:assetCollection, options:fetchOptions)
				}
		}

		// Load objects

		if let assetsFetchResult = assetsFetchResult
		{
			for i in 0 ..< assetsFetchResult.count
			{
				let asset = assetsFetchResult[i]
				let mediaType = asset.mediaType
				let identifier = PhotosObject.identifier(for:asset)
				guard filter.rating == 0 || StatisticsController.shared.rating(for:identifier) >= filter.rating else { continue }

				if mediaType == .image
				{
					objects += PhotosImageObject(with:asset)
				}
				else
				{
					objects += PhotosVideoObject(with:asset)
				}
			}
		}
		
		// Sort according to specified sort order
		
		filter.sort(&objects)

		// Return contents of this Container
		
		return (containers,objects)
	}

	
//----------------------------------------------------------------------------------------------------------------------


	/// This object is responsible for detecting changes to the Photos.app library
	
	var observer = PhotosChangeObserver()


	// When we get a change notification from Photos.app, then update the data property and reload the Container
	
	public func didChange(_ change:PHChange)
    {
		#warning("FIXME: needs to be updated for new PhotosData enum")

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


}


//----------------------------------------------------------------------------------------------------------------------
