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
	
 	public init(identifier:String, icon:String, name:String, data:Any, filter:Object.Filter, in library:Library?)
	{
		Photos.log.debug {"\(Self.self).\(#function) \(identifier)"}
		
		super.init(
			identifier:identifier,
			icon:icon,
			name:name,
			data:data,
			filter:filter,
			loadHandler:Self.loadContents,
			removeHandler:nil,
			in:library)

		observer.didChangeHandler =
		{
			[weak self] in self?.didChange($0)
		}
	}


//----------------------------------------------------------------------------------------------------------------------


	/// Returns the allowed mediaTypes in this Container
	
	override nonisolated open var mediaTypes:[Object.MediaType]
	{
 		guard let filter = filter as? PhotosFilter else { return [] }
		return filter.allowedMediaTypes
	}


	/// Returns the list of allowed sort Kinds for this Container
		
	override open var allowedSortTypes:[Object.Filter.SortType]
	{
		[.creationDate,.rating,.useCount]
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
	
	class func loadContents(for identifier:String, data:Any, filter:Object.Filter, in library:Library?) async throws -> Loader.Contents
	{
		guard let data = data as? PhotosData else { return ([],[]) }
 		guard let filter = filter as? PhotosFilter else { return ([],[]) }

		try await Tasks.canContinue()

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
			
			case .folder(let collections,_):

				for collection in collections
				{
					if let assetCollection = collection as? PHAssetCollection
					{
						assetsFetchResult = PHAsset.fetchAssets(in:assetCollection, options:fetchOptions)
						let icon = assetCollection.assetCollectionType == .smartAlbum ? "gearshape" : "rectangle.stack"
						let name = assetCollection.localizedTitle ?? ""
						
						let container = PhotosContainer(
							identifier: "Photos:Album:\(assetCollection.localIdentifier)",
							icon: icon,
							name: name,
							data: PhotosData.album(collection:assetCollection),
							filter: filter,
							in: library)
						
						containers += container
					}
					else if let collectionList = collection as? PHCollectionList
					{
						let fetchResult = PHCollection.fetchCollections(in:collectionList, options:nil)
						let collections = PhotosData.items(for:fetchResult)
						let name = collectionList.localizedTitle ?? ""
						
						let container = PhotosContainer(
							identifier: "Photos:Folder:\(collectionList.localIdentifier)",
							icon: "folder",
							name: name,
							data: PhotosData.folder(collections:collections, fetchResult:fetchResult),
							filter: filter,
							in: library)
						
						containers += container
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
								filter: filter,
								in: library)
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
								filter: filter,
								in: library)
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
								filter: filter,
								in: library)
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
					objects += PhotosImageObject(with:asset, in:library)
				}
				else
				{
					objects += PhotosVideoObject(with:asset, in:library)
				}
			}
		}
		
		// Sort according to specified sort order
		
		filter.sort(&objects)

		// Return contents of this Container
		
		return (containers,objects)
	}

	
//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Change Detection & Reloading
	
	/// This object is responsible for detecting changes to the Photos.app library
	
	var observer = PhotosChangeObserver()


	// When we get a change notification from Photos.app, then update the data property and reload the Container
	
	public func didChange(_ change:PHChange)
    {
		guard let data = data as? PhotosData else { return }
		var requestReload = false
		
		switch data
		{
			// Reload the "All Photos" library container if the list of objects has changed (e.g. new imports)
			
			case .library(let allAssets):

				if let details = change.changeDetails(for:allAssets), details.insertedIndexes != nil || details.removedIndexes != nil || details.hasMoves
				{
					requestReload = true
				}
			
			// Reload this album when its list of objects has changed
			
			case .album(let assetCollection):

				if change.changeDetails(for:assetCollection) != nil
				{
					requestReload = true
				}
			
			// Reload this folder when its list of sub-containers has changed
			
			case .folder(_, let fetchResult):

				if let fetchResult = fetchResult as? PHFetchResult<PHCollectionList>, let details = change.changeDetails(for:fetchResult)
				{
					let newFetchResult = details.fetchResultAfterChanges
					let newCollections = PhotosData.items(for:newFetchResult)
					self.data = PhotosData.folder(collections:newCollections, fetchResult:newFetchResult)
					requestReload = true
				}

			// Reload a year/month/day folder if it list of objects has changed
			
			case .dateInterval(_, let assetCollection, _):

				if let assetCollection = assetCollection, change.changeDetails(for:assetCollection) != nil
				{
					requestReload = true
				}
		}
		
		// Only perform a requested reload if a container was loaded before
		
		if requestReload
		{
			Task
			{
				await MainActor.run
				{
					if self.isLoaded { self.reload() }
				}
			}
		}
    }


	// For any Containers that are not currently selected, remember the reload request
	
	override func reload()
	{
		if self.isSelected
		{
			super.reload()
		}
		else
		{
			self.didRequestReload = true
		}
	}

	private var didRequestReload = false
	
	
	// Once a Container is selected again, reload it now it if was requested before
	
	override public var isSelected:Bool
	{
		didSet
		{
			if isSelected && didRequestReload
			{
				self.didRequestReload = false
				self.reload()
			}
		}
	}
}


//----------------------------------------------------------------------------------------------------------------------
