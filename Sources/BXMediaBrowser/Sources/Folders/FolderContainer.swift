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


import SwiftUI
import QuickLook
import UniformTypeIdentifiers


//----------------------------------------------------------------------------------------------------------------------


open class FolderContainer : Container
{
	let folderObserver:FolderObserver
	
	/// Creates a new Container for the folder at the specified URL
	
	public required init(url:URL, removeHandler:((Container)->Void)? = nil)
	{
		self.folderObserver = FolderObserver(url:url)
		
		super.init(
			identifier: FolderSource.identifier(for:url),
			info: url,
			name: url.lastPathComponent,
			removeHandler: removeHandler,
			loadHandler: Self.loadContents)
			
		self.folderObserver.folderDidChange =
		{
			[weak self] in self?.load()
		}
		
		self.folderObserver.resume()
	}


	// This container can be expanded if it has subfolders
	
	override var canExpand: Bool
	{
		if self.isLoaded { return !self.containers.isEmpty }
		guard let folderURL = info as? URL else { return false }
		return folderURL.hasSubfolders
	}
	
	
	/// Loads the (shallow) contents of this folder
	
	class func loadContents(for identifier:String, info:Any, filter:String) async throws -> Loader.Contents
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
		
		let filterString = filter.lowercased()
		
		// Go through all items
		
		for filename in filenames
		{
			guard !Task.isCancelled else { throw Error.loadContentsCancelled }
			
			let url = folderURL.appendingPathComponent(filename)
			
			guard url.isFileURL else { continue }
			guard url.isReadable else { continue }
			guard !url.isHidden else { continue }
			
			if !filterString.isEmpty
			{
				guard url.lastPathComponent.lowercased().contains(filterString) else { continue }
			}
			
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
	
	
	/// Creates a Container (of same type) for the folder at the specified URL.
	///
	/// Subclasses can override this function to filter out some directories.
	
	open class func createContainer(for url:URL) throws -> Container?
	{
		guard url.exists else { throw Container.Error.notFound }
		guard url.isDirectory else { throw Container.Error.notFound }
		return Self.init(url:url)
	}


	/// Creates a Object for the file at the specified URL.
	///
	/// Subclasses can override this function to filter out some files.
	
	open class func createObject(for url:URL) throws -> Object?
	{
		// Check if file exists
		
		guard url.exists else { throw Container.Error.notFound }
		guard !url.isDirectory else { throw Container.Error.notFound }
		
		// Depending on file UTI create different Object subclass instances
		
		if url.isImageFile
		{
			return ImageFile(url:url)
		}
		else if url.isVideoFile
		{
			return VideoFile(url:url)
		}
		else if url.isAudioFile
		{
			return AudioFile(url:url)
		}
		else
		{
			return FolderObject(url:url)
		}
	}
}


//----------------------------------------------------------------------------------------------------------------------
