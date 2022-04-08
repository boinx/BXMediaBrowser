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
	/// The controller that takes care of loading media assets
	
	static let imageManager:PHImageManager = PHImageManager()
	
	/// This object is reponsible for reporting changes to the Photos library
	
	var observer = PhotosChangeObserver()
	
	
//----------------------------------------------------------------------------------------------------------------------


	// MARK: -
	
	/// Creates a new Source for local file system directories
	
	public init(allowedMediaTypes:[Object.MediaType])
	{
		Photos.log.verbose {"\(Self.self).\(#function) \(Photos.identifier)"}

		let filter = PhotosFilter(allowedMediaTypes:allowedMediaTypes)
		
		super.init(
			identifier:Photos.identifier,
			icon:Photos.icon,
			name:Photos.name,
			filter:filter)
		
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


	// When the contents of the Photos library change, then reload the top-level containers
	
    public func photoLibraryDidChange(_ change:PHChange)
    {
//		self.load()
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


	/// Loads the top-level containers of this source.
	///
	/// Subclasses can override this function, e.g. to load top level folder from the preferences file
	
	private func loadContainers(with sourceState:[String:Any]? = nil, filter:Object.Filter) async throws -> [Container]
	{
		Photos.log.debug {"\(Self.self).\(#function) \(identifier)"}

		guard let filter = filter as? PhotosFilter else { return [] }
		var containers:[Container] = []
		
		// Library
		
		let libraryFetchResult = PHAsset.fetchAssets(with:filter.fetchOptions)
		let libraryData = PhotosData.library(assets:libraryFetchResult)
		let title = filter.allowedMediaTypes == [.video] ?
			NSLocalizedString("All Videos", tableName:"Photos", bundle:.BXMediaBrowser, comment:"Container Name") :
			NSLocalizedString("All Photos", tableName:"Photos", bundle:.BXMediaBrowser, comment:"Container Name")
	
		containers += PhotosContainer(
			identifier: "\(Photos.identifier):Library",
			icon: "photo.on.rectangle",
			name: title,
			data: libraryData,
			filter: filter)

		// Recently Added
		
		let recentsFetchResult = PHAssetCollection.fetchAssetCollections(with:.smartAlbum, subtype:.smartAlbumRecentlyAdded, options:nil)
		
		if let recentsCollection = recentsFetchResult.firstObject
		{
			let recentsData = PhotosData.album(collection:recentsCollection)
			
			containers += PhotosContainer(
				identifier: "Photos:Recents",
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
			identifier: "Photos:Albums",
			icon: "folder",
			name: NSLocalizedString("Albums", tableName:"Photos", bundle:.BXMediaBrowser, comment:"Container Name"),
			data: albumsData,
			filter: filter)
		
		// Years

		let yearsCollections = PHAssetCollection.yearsCollections(mediaType:filter.assetMediaType)
//		let yearsData = PhotosData.folder(collections:yearsCollections)
		let yearsData = PhotosData.dateInterval(unit:.era, assetCollection:nil, subCollections:yearsCollections)
		
		containers += PhotosContainer(
			identifier: "Photos:Years",
			icon: "folder",
			name: NSLocalizedString("Years", tableName:"Photos", bundle:.BXMediaBrowser, comment:"Container Name"),
			data: yearsData,
			filter: filter)

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
		
		return containers
	}
}


//----------------------------------------------------------------------------------------------------------------------


