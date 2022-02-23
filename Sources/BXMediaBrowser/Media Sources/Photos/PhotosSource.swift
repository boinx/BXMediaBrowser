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

		if !self.hasAccess
		{
			self.grantAccess()
			{
				[weak self] isGranted in
				if isGranted { self?.load() }
			}
		}
	}


//----------------------------------------------------------------------------------------------------------------------


	/// Returns true if we have access to the Photos library
	
	public var hasAccess:Bool
	{
		PHPhotoLibrary.authorizationStatus() == .authorized
	}
	
	/// Calling this function prompts the user to grant access to the Photos library
	
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
	
	private func loadContainers(with sourceState:[String:Any]? = nil, filter:Object.Filter) async throws -> [Container]
	{
		PhotosSource.log.debug {"\(Self.self).\(#function) \(identifier)"}

		var containers:[Container] = []
		
		// Library
		
		let library = PhotosContainer(mediaType:.image, filter:filter)
		containers += library

		// Recently Added
		
		let recentsFetchResult = PHAssetCollection.fetchAssetCollections(
			with:.smartAlbum,
			subtype:.smartAlbumRecentlyAdded,
			options:nil)
			
		if let recents = recentsFetchResult.firstObject
		{
			containers += PhotosContainer(
				with:recents,
				icon:"clock",
				filter:filter)
		}



		// Years
		
//		let years = PHCollectionList.fetchMomentLists(with:.momentListYear,options:nil)
//
//		let yearsContainer = iOSMediaBrowserPhotosContainer(
//			years:yearsFetchResult,
//			identifier:"com.apple.photos.years",
//			name:NSLocalizedString("Years",bundle:bundle,comment:"Container name"))
//
//		if yearsContainer.childContainers.count > 0 || yearsContainer.itemCount > 0
//		{
//			containers.append(yearsContainer)
//		}
		
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
			let container = PhotosContainer(with:smartFolder, filter:filter)
			containers += container
		}

		// User Folders & Albums
		
		let container = PhotosContainer(
			with:PHCollectionList.fetchTopLevelUserCollections(with:nil),
			identifier:"PhotosSource:Albums",
			name:"Albums",
			filter:filter)
			
		containers += container
		
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


