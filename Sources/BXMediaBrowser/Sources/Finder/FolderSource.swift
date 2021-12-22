//
//  FolderSource.swift
//  MediaBrowserTest
//  Created by Peter Baumgartner on 04.12.21.
//

import SwiftUI
import QuickLook


//----------------------------------------------------------------------------------------------------------------------


open class FolderSource : Source, AccessControl
{
	/// The unique identifier of this source must always remain the same. Do not change this
	/// identifier, even if the class name changes due to refactoring, because the identifier
	/// might be stored in a preferences file or user documents.
	
	static let identifier = "FolderSource:"
	
	
	/// Creates a new Source for local file system directories
	
	public init()
	{
		super.init(identifier:Self.identifier, name:"Finder")
		self.loader = Loader(identifier:self.identifier, loadHandler:self.load)
	}


	/// Converts a file URL to a unique identifier
	
	public class func identifier(for url:URL) -> String
	{
		return "\(Self.identifier)\(url.absoluteString)"
	}
	
	
	/// Converts a unique identifier back to a file URL
	
	public class func url(for identifier:String) throws -> URL
	{
		let string = identifier.replacingOccurrences(of:Self.identifier, with:"")
		guard let url = URL(string:string) else { throw Container.Error.notFound }
		return url
	}


	/// Loads the top-level containers of this source.
	///
	/// Subclasses can override this function, e.g. to load top level folder from the preferences file
	
	private func load() async throws -> [Container]
	{
		return []
	}


	public var hasAccess:Bool { true }
	
	public func grantAccess(_ completionHandler:@escaping (Bool)->Void)
	{
		completionHandler(hasAccess)
	}
}


//----------------------------------------------------------------------------------------------------------------------


// MARK: -

open class FolderContainer : Container
{
	let observer:FolderObserver
	
	/// Creates a new Container for the folder at the specified URL
	
	public init(url:URL)
	{
		self.observer = FolderObserver(url:url)
		
		super.init(
			identifier: FolderSource.identifier(for:url),
			info: url,
			name: url.lastPathComponent,
			loadHandler: Self.loadContents)
			
		self.observer.folderDidChange =
		{
			[weak self] in self?.load()
		}
		
		self.observer.resume()
	}


	/// Loads the (shallow) contents of this folder
	
	class func loadContents(for identifier:String, info:Any) async throws -> Loader.Contents
	{
		var containers:[Container] = []
		var objects:[Object] = []
		
		// Convert identifier to URL and perform some sanity checks
		
		guard let folderURL = info as? URL else { throw Error.notFound }
		guard folderURL.exists else { throw Error.notFound }
		guard folderURL.isDirectory else { throw Error.notFound }
		guard folderURL.isReadable else { throw Error.accessDenied }
		
		// Get the folder contents and sort them like the Finder would
		
		let filenames = try FileManager.default
			.contentsOfDirectory(atPath:folderURL.path)
			.sorted(using:.localizedStandard)
		
		// Go through all items
		
		for filename in filenames
		{
			guard !Task.isCancelled else { throw Error.loadContentsCancelled }
			
			let url = folderURL.appendingPathComponent(filename)
			
			guard url.isFileURL else { continue }
			guard url.isReadable else { continue }
			guard !url.isHidden else { continue }

			// For a directory, create a sub-container
			
			if url.isDirectory && !url.isPackage
			{
				if let container = try? Self.createContainer(for:url)
				{
					containers.append(container)
				}
			}
			
			// For a file create a file object
			
			else
			{
				if let object = try? Self.createObject(for:url)
				{
					objects.append(object)
				}
			}
		}
		
		return (containers,objects)
	}
	
	
	/// Creates a Container for the folder at the specified URL.
	///
	/// Subclasses can override this function to filter out some directories.
	
	open class func createContainer(for url:URL) throws -> Container?
	{
		guard url.exists else { throw Container.Error.notFound }
		guard url.isDirectory else { throw Container.Error.notFound }
		return FolderContainer(url:url)
	}


	/// Creates a Object for the file at the specified URL.
	///
	/// Subclasses can override this function to filter out some files.
	
	open class func createObject(for url:URL) throws -> Object?
	{
		guard url.exists else { throw Container.Error.notFound }
		guard !url.isDirectory else { throw Container.Error.notFound }
		return AnyFile(url:url)
	}
}


//----------------------------------------------------------------------------------------------------------------------


// MARK: -

open class AnyFile : Object
{
	/// Creates a new Object for the file at the specified URL
	
	public init(url:URL)
	{
		super.init(
			identifier: FolderSource.identifier(for:url),
			name: url.lastPathComponent,
			info: url,
			loadThumbnailHandler: Self.loadThumbnail,
			loadMetadataHandler: Self.loadMetadata,
			downloadFileHandler: Self.downloadFile)
	}


	/// Creates a thumbnail image for the specified local file URL
	
	open class func loadThumbnail(for identifier:String, info:Any) async throws -> CGImage
	{
		guard let url = info as? URL else { throw Error.loadThumbnailFailed }
		guard url.exists else { throw Error.loadThumbnailFailed }
		
    	let size = CGSize(width:256, height:256)
        let options = [ kQLThumbnailOptionIconModeKey : kCFBooleanFalse ]
        
        let ref = QLThumbnailImageCreate(
			kCFAllocatorDefault,
			url as CFURL,
			size,
			options as CFDictionary)
        
        guard let thumbnail = ref?.takeUnretainedValue() else { throw Error.loadThumbnailFailed }
		return thumbnail
	}


	/// Loads the metadata dictionary for the specified local file URL
	
	open class func loadMetadata(for identifier:String, info:Any) async throws -> [String:Any]
	{
		guard let url = info as? URL else { throw Error.loadMetadataFailed }
		guard url.exists else { throw Error.loadMetadataFailed }

		var metadata:[String:Any] = [:]
		
		if let fileSize = url.fileSize
		{
			metadata["fileSize"] = fileSize
		}

		if let creationDate = url.creationDate
		{
			metadata["creationDate"] = creationDate
		}

		if let modificationDate = url.modificationDate
		{
			metadata["modificationDate"] = modificationDate
		}
		
		return metadata
	}


	/// Since we are already dealing with a local media file, this function simply returns the specified file URL
	
	open class func downloadFile(for identifier:String, info:Any) async throws -> URL
	{
		guard let url = info as? URL else { throw Error.downloadFileFailed }
		guard url.exists else { throw Error.downloadFileFailed }
		return url
	}
}


//----------------------------------------------------------------------------------------------------------------------


