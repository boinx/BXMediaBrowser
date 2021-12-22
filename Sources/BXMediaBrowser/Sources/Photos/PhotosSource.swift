//
//  PhotosSource.swift
//  MediaBrowserTest
//  Created by Peter Baumgartner on 04.12.21.
//

import Photos


//----------------------------------------------------------------------------------------------------------------------


public class PhotosSource : Source,AccessControl //,PHPhotoLibraryChangeObserver
{
	/// The unique identifier of this source must always remain the same. Do not change this
	/// identifier, even if the class name changes due to refactoring, because the identifier
	/// might be stored in a preferences file or user documents.
	
	static let identifier = "PhotosSource:"
	
	/// The controller that takes care of loading media assets
	
	static let imageManager:PHImageManager = PHImageManager()
	
	var observer = PhotosChangeObserver()
	
	
//----------------------------------------------------------------------------------------------------------------------


	/// Creates a new Source for local file system directories
	
	public init()
	{
		super.init(identifier:Self.identifier, name:"Photos")
		self.loader = Loader(identifier:self.identifier, loadHandler:self.load)

		// Request access to photo library if not available yet
		
		if PHPhotoLibrary.authorizationStatus() != .authorized
		{
			PHPhotoLibrary.requestAuthorization()
			{
				_ in
			}
		}

		// Make sure we can detect changes to the library
	
		observer.didChangeHandler =
		{
			[weak self] in self?.photoLibraryDidChange($0)
		}
	}


//    deinit
//    {
//        PHPhotoLibrary.shared().unregisterChangeObserver(self)
//    }


//----------------------------------------------------------------------------------------------------------------------


	public var hasAccess:Bool { PHPhotoLibrary.authorizationStatus() == .authorized }
	
	public func grantAccess(_ completionHandler:@escaping (Bool)->Void)
	{
		PHPhotoLibrary.requestAuthorization
		{
			status in completionHandler(status == .authorized)
		}
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
	
	private func load() async throws -> [Container]
	{
		var containers:[Container] = []
		
		// Library
		
		let library = PhotosContainer(mediaType:.image)
		containers += library

		// Smart Albums
		
//		let smartAlbums = PHAssetCollection.fetchAssetCollections(
//			with:.smartAlbum,
//			subtype:.any,
//			options:nil)
//
//		for i in 0 ..< smartAlbums.count
//		{
//			let smartAlbum = smartAlbums[i]
//			let container = PhotosContainer(with:smartAlbum)
//			containers += container
//		}
		
		// Smart Folders

		let smartFolders = PHCollectionList.fetchCollectionLists(
			with:.smartFolder,
			subtype:.any,
			options:nil)

		for i in 0 ..< smartFolders.count
		{
			let smartFolder = smartFolders[i]
			let container = PhotosContainer(with:smartFolder)
			containers += container
		}

		// User Folders & Albums
		
		let container = PhotosContainer(
			with:PHCollectionList.fetchTopLevelUserCollections(with:nil),
			identifier:"PhotosSource:Albums",
			name:"Albums")
			
		containers += container
		
		return containers
	}

}


//----------------------------------------------------------------------------------------------------------------------


