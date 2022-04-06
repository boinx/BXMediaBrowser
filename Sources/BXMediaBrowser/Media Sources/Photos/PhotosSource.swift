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
import AppKit


//----------------------------------------------------------------------------------------------------------------------


public class PhotosSource : Source, AccessControl
{
	/// The unique identifier of this source must always remain the same. Do not change this
	/// identifier, even if the class name changes due to refactoring, because the identifier
	/// might be stored in a preferences file or user documents.
	
	static let identifier = "PhotosSource:"
	
	static let icon = NSImage.icon(for:"com.apple.Photos")?.CGImage
	
	
	/// The controller that takes care of loading media assets
	
	static let imageManager:PHImageManager = PHImageManager()
	
	///
	var observer = PhotosChangeObserver()
	
	
//----------------------------------------------------------------------------------------------------------------------


	/// Creates a new Source for local file system directories
	
	public init()
	{
		PhotosSource.log.verbose {"\(Self.self).\(#function) \(Self.identifier)"}

		super.init(identifier:Self.identifier, icon:Self.icon, name:"Photos", filter:Object.Filter())
		self.loader = Loader(loadHandler:self.loadContainers)

		// Make sure we can detect changes to the library
	
		observer.didChangeHandler =
		{
			[weak self] in self?.photoLibraryDidChange($0)
		}
		
		// Request access to photo library if not available yet. Reload all containers once access has been granted.

		Task
		{
			await MainActor.run
			{
				if !self.hasAccess
				{
					self.grantAccess()
					{
						[weak self] isGranted in
						if isGranted { self?.load() }
					}
				}
			}
		}
	}


//----------------------------------------------------------------------------------------------------------------------


	/// Returns true if we have access to the Photos library
	
	@MainActor public var hasAccess:Bool
	{
		PHPhotoLibrary.authorizationStatus() == .authorized
	}
	
	/// Calling this function prompts the user to grant access to the Photos library
	
	@MainActor public func grantAccess(_ completionHandler:@escaping (Bool)->Void = { _ in })
	{
		PHPhotoLibrary.requestAuthorization
		{
			status in completionHandler(status == .authorized)
		}
	}

	// Photos doesn't let us remove access once it has been granted
	
	@MainActor public func revokeAccess(_ completionHandler:@escaping (Bool)->Void = { _ in })
	{
		completionHandler(hasAccess)
	}


//----------------------------------------------------------------------------------------------------------------------


	// When the contents of the Photos library change, then reload the top-level containers
	
    public func photoLibraryDidChange(_ change:PHChange)
    {
//		self.load() 
    }


//----------------------------------------------------------------------------------------------------------------------


	/// Loads the top-level containers of this source.
	///
	/// Subclasses can override this function, e.g. to load top level folder from the preferences file
	
	private func loadContainers(with sourceState:[String:Any]? = nil, filter:Object.Filter) async throws -> [Container]
	{
		PhotosSource.log.debug {"\(Self.self).\(#function) \(identifier)"}

		var containers:[Container] = []
	
		// Sorting
		
        let sortOptions = PHFetchOptions()
        sortOptions.sortDescriptors = [NSSortDescriptor(key:"creationDate", ascending:true)]

		// Library
		
        let allPhotosFetchResult = PHAsset.fetchAssets(with:sortOptions)
		let allPhotosData = PhotosData.library(assets:allPhotosFetchResult)

		containers += PhotosContainer(
			identifier: "PhotosSource:Library",
			icon: "photo.on.rectangle",
			name: "All Photos",
			data: allPhotosData,
			filter: filter)

		// Recently Added
		
		let recentsFetchResult = PHAssetCollection.fetchAssetCollections(with:.smartAlbum, subtype:.smartAlbumRecentlyAdded, options:nil)
		
		if let recentsCollection = recentsFetchResult.firstObject
		{
			let recentsData = PhotosData.album(collection:recentsCollection)
			
			containers += PhotosContainer(
				identifier: "PhotosSource:\(recentsCollection.localIdentifier)",
				icon: "clock",
				name: recentsCollection.localizedTitle ?? "Recents",
				data: recentsData,
				filter: filter)
		}

		// Albums
		
		let albumsFetchResult = PHCollectionList.fetchTopLevelUserCollections(with:nil)
		let albumsCollections = PhotosData.items(for:albumsFetchResult)
		let albumsData = PhotosData.folder(collections:albumsCollections)

		containers += PhotosContainer(
			identifier: "PhotosSource:Albums",
			icon: "folder",
			name: "Albums",
			data: albumsData,
			filter: filter)
		
		// Years

		let yearsCollectionList = PHCollectionList.years(mediaType:.image)
		let yearsFetchResult = PHCollection.fetchCollections(in:yearsCollectionList, options:nil)
		let yearsCollections = PhotosData.items(for:yearsFetchResult)
		let yearsData = PhotosData.folder(collections:yearsCollections)

		containers += PhotosContainer(
			identifier: "PhotosSource:Years",
			icon: "folder",
			name: "Years",
			data: yearsData,
			filter: filter)
		
//		if allPhotosFetchResult.count > 0
//		{
//			yearCollections.append(PHAssetCollection.transientAssetCollection(withAssetFetchResult: assets, title: "\(year)"))
//		}
//}
//
//let phCollectionList = PHCollectionList.transientCollectionList(with: yearCollections, title: "Years")



		// Smart Albums
		
//		let smartAlbums = PHAssetCollection.fetchAssetCollections( with:.smartAlbum, subtype:.any, options:nil)
//
//		for i in 0 ..< smartAlbums.count
//		{
//			containers += PhotosContainer(with:smartAlbums[i], filter:filter)
//		}
		
		// Smart Folders

//		let smartFolders = PHCollectionList.fetchCollectionLists(
//			with:.smartFolder,
//			subtype:.any,
//			options:nil)
//
//		for i in 0 ..< smartFolders.count
//		{
//			let smartFolder = smartFolders[i]
//			let container = PhotosContainer(with:smartFolder, filter:filter)
//			containers += container
//		}

		// User Albums
		
//		let container = PhotosContainer(
//			with:PHCollectionList.fetchTopLevelUserCollections(with:nil),
//			identifier:"PhotosSource:Albums",
//			name:"Albums",
//			filter:filter)
//
//		containers += container
		
		return containers
	}


//----------------------------------------------------------------------------------------------------------------------


	public static var log:BXLogger =
	{
		()->BXLogger in
		
		var logger = BXLogger()

		logger.addDestination
		{
			(level:BXLogger.Level,string:String)->() in
			BXMediaBrowser.log.print(level:level, force:true) { string }
		}
		
		return logger
	}()
}


//----------------------------------------------------------------------------------------------------------------------


