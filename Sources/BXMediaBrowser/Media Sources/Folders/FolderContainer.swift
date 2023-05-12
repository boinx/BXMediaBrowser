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
import SwiftUI
import QuickLook

#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif

#if canImport(AppKit)
import AppKit
#endif


//----------------------------------------------------------------------------------------------------------------------


open class FolderContainer : Container
{
	/// These helpers report any external changes to the folder
	
	private var nameObserver:FolderObserver
	private var contentsObserver:FolderObserver

	/// Creates a new Container for the folder at the specified URL
	
	public required init(url:URL, name:String? = nil, filter:FolderFilter, removeHandler:((Container)->Void)? = nil)
	{
		let refURL = (url as NSURL).fileReferenceURL
		
		self.nameObserver = FolderObserver(url:url.deletingLastPathComponent())
		self.contentsObserver = FolderObserver(url:url)
		
		super.init(
			identifier: FolderSource.identifier(for:url),
			name: name ?? FileManager.default.displayName(atPath:url.path),
			data: refURL,
			filter: filter,
			loadHandler: Self.loadContents,
			removeHandler: removeHandler)
		
		// Observe changes of folder name - in this case the container name needs to be updated, and the container needs to be reloaded
		
		self.nameObserver.folderDidChange =
		{
			[weak self] in
			guard let self = self else { return }
			self.name = name ?? FileManager.default.displayName(atPath:refURL.swiftURL.path)
			self.reload()
		}

		self.nameObserver.resume()
		
		// Observe changes of folder contents
		
		self.contentsObserver.folderDidChange =
		{
			[weak self] in self?.reload()
		}

		self.contentsObserver.resume()
		
		#if os(macOS)
		self.fileDropDestination = FolderDropDestination(folderURL:url)
		#endif
	}


	/// Returns the list of allowed sort Kinds for this Container
		
	override open var allowedSortTypes:[Object.Filter.SortType]
	{
		[.captureDate,.alphabetical,.rating,.useCount]
	}


	// This container can be expanded if it has subfolders. Since it is fairly expensive to scan a directory just to
	// find out whether it has any subfolders, we will perform the scanning on a background task. In the meantime we
	// will return a default value of false (meaning that no disclosure triangle is displayed in the user interface.
	// Once the result is available, it will be assigned to the published helper property 'hasSubfolders' which will
	// trigger the UI to be updated automatically.
	
	override open var canExpand: Bool
	{
		guard let folderURL = data as? URL else { return false }

		if self.isLoaded { return !self.containers.isEmpty }
		
		if !didScanSubfolders
		{
			self.didScanSubfolders = true
			
			Task
			{
				let result = folderURL.hasSubfolders
				await MainActor.run { self.hasSubfolders = result }
			}
		}

		return self.hasSubfolders
	}
	
	private var didScanSubfolders = false
	
	@MainActor @Published public private(set) var hasSubfolders = false

	
//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Loading
	
	/// Loads the (shallow) contents of this folder
	
	class func loadContents(for identifier:String, data:Any, filter:Object.Filter) async throws -> Loader.Contents
	{
		FolderSource.log.debug {"\(Self.self).\(#function) \(identifier)"}

		var containers:[Container] = []
		var objects:[Object] = []
		
		// Convert identifier to URL and perform some sanity checks
		
		guard let folderURL = data as? URL else { throw Error.notFound }
		guard folderURL.exists else { throw Error.notFound }
		guard folderURL.isDirectory else { throw Error.notFound }
		guard folderURL.isReadable else { throw Error.accessDenied }
		guard let filter = filter as? FolderFilter else { throw Error.loadContentsFailed }
		
		// Get the folder contents
		
		let filenames = try self.filenames(in:folderURL)
		
		// Convert to file URLs
		
		guard !Task.isCancelled else { throw Error.loadContentsCancelled }

		let urls = filenames.compactMap
		{
			(filename:String) -> URL? in
			let url = folderURL.appendingPathComponent(filename)
			guard url.isFileURL else { return nil }
			guard url.isReadable else { return nil }
			guard !url.isHidden else { return nil }
			return url
		}
		
		// Go through all URLs
		
		for url in urls
		{
			guard !Task.isCancelled else { throw Error.loadContentsCancelled }
			
			// For a directory, create a Container
			
			if url.isDirectory && !url.isPackage
			{
				if let container = try? Self.createContainer(for:url, filter:filter)
				{
					containers.append(container)
				}
			}
			
			// If a file meets the filter criteria create an Object
			
			else if let url = Self.filter(url, with:filter)
			{
				if let object = try? Self.createObject(for:url, filter:filter)
				{
					if filter.rating == 0 || StatisticsController.shared.rating(for:object) >= filter.rating
					{
						objects.append(object)

						// For sorting by capture date we need to make sure a date is available
						
						if filter.sortType == .captureDate
						{
							let metadata = try? await object.loader.metadata
							object.captureDate =
								(metadata?[.captureDateKey] as? Date) ??
								url.creationDate
						}
					}
				}
			}
		}
		
		// Sort according to specified sort order
		
		guard !Task.isCancelled else { throw Error.loadContentsCancelled }

		filter.sort(&objects)
		
		// Return contents
		
		return (containers,objects)
	}
	
	
	/// Returns the names of all files inside this folder
	
	class func filenames(in folderURL:URL) throws -> [String]
	{
		if #available(macOS 12, iOS 15, *)
		{
			return try FileManager.default
				.contentsOfDirectory(atPath:folderURL.path)
				.sorted(using:.localizedStandard)
		}
		else
		{
			return try FileManager.default
				.contentsOfDirectory(atPath:folderURL.path)
				.sorted()
		}
	}
	
	
	/// Check if the specified URL meets the filter criteria. Returns the URL itself if yes, or nil if not.
	
	open class func filter(_ url:URL, with filter:FolderFilter) -> URL?
	{
		let searchString = filter.searchString.lowercased()
		guard !searchString.isEmpty else { return url }
		
		let filename = url.lastPathComponent.lowercased()
		return filename.contains(searchString) ? url : nil
	}
	
	
	/// Creates a Container (of same type) for the folder at the specified URL.
	///
	/// Subclasses can override this function to filter out some directories.
	
	open class func createContainer(for url:URL, filter:FolderFilter) throws -> Container?
	{
		guard url.exists else { throw Container.Error.notFound }
		guard url.isDirectory else { throw Container.Error.notFound }
		return Self.init(url:url, filter:filter)
	}


	/// Creates a Object for the file at the specified URL.
	///
	/// Subclasses can override this function to filter out some files.
	
	open class func createObject(for url:URL, filter:FolderFilter) throws -> Object?
	{
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
	
	
	/// If the container caches any expensive data, calling this function will discard any cached data
	
	override func invalidateCache()
	{
		super.invalidateCache()
		self.didScanSubfolders = false
		self.hasSubfolders = false
	}
	
	
//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Actions
	
	/// Reveals the folder in the Finder
	
	open func revealInFinder()
	{
		guard let url = data as? URL else { return }
		guard url.exists else { return }
		
		#if os(macOS)
		
		NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath:url.deletingLastPathComponent().path)
	
		#else
		
		#warning("TODO: implement for iOS")
		
		#endif
	}

}


//----------------------------------------------------------------------------------------------------------------------
