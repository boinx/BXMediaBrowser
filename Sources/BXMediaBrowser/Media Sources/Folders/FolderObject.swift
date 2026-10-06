//----------------------------------------------------------------------------------------------------------------------
//
//  Copyright ©2022-2026 Peter Baumgartner. All rights reserved.
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

#if canImport(QuickLookThumbnailing)
import QuickLookThumbnailing
#endif


//----------------------------------------------------------------------------------------------------------------------


open class FolderObject : Object
{
	/// Creates a new Object for the file at the specified URL
	
	public init(url:URL, name:String? = nil, in library:Library?)
	{
		FolderSource.log.verbose {"\(Self.self).\(#function) url = \(url)"}

		super.init(
			identifier: FolderSource.identifier(for:url),
			name: name ?? url.lastPathComponent,
			data: url,
			loadThumbnailHandler: Self.loadThumbnail,
			loadMetadataHandler: Self.loadMetadata,
			downloadFileHandler: Self.downloadFile,
			in: library)

		// File in a Finder folder are always local, non-download
		
		self.isLocallyAvailable = true
		self.isDownloadable = false
	}


//----------------------------------------------------------------------------------------------------------------------


	// MARK: -

	/// Creates a thumbnail image for the specified local file URL
	
	open class func loadThumbnail(for identifier:String, data:Any) async throws -> CGImage
	{
		FolderSource.log.verbose {"\(Self.self).\(#function) \(identifier)"}

		guard let url = data as? URL else { throw Error.loadThumbnailFailed }
		guard url.exists else { throw Error.loadThumbnailFailed }
    	let size = CGSize(width:256, height:256)
    	
		// This used to call the deprecated - and synchronous - QLThumbnailImageCreate on macOS. Since we are on a
		// cooperative pool thread here, that blocked one of the very few threads that QuickLookThumbnailing itself
		// needs to deliver its result, which deadlocked the whole app (FM-2532). Always use the async API.

		do
		{
			return try await QLThumbnailGenerator.shared.thumbnail(with:url, maxSize:size)
		}
		catch
		{
			FolderSource.log.error {"\(Self.self).\(#function) failed to load thumbnail for \(url) - \(error)"}
			throw Error.loadThumbnailFailed
		}
	}


	/// Loads the metadata dictionary for the specified local file URL
	
	open class func loadMetadata(for identifier:String, data:Any) async throws -> [String:Any]
	{
		FolderSource.log.verbose {"\(Self.self).\(#function) \(identifier)"}

		guard let url = data as? URL else { throw Error.loadMetadataFailed }
		guard url.exists else { throw Error.loadMetadataFailed }

		// These file system attributes are available without reading the file contents, so there is no need
		// to download a cloud based file here (which a coordinated read would have done).
		
		var metadata:[String:Any] = [:]
		
		if let fileSize = url.fileSize
		{
			metadata[.fileSizeKey] = fileSize
		}

		if let creationDate = url.creationDate
		{
			metadata[.creationDateKey] = creationDate
		}

		if let modificationDate = url.modificationDate
		{
			metadata[.modificationDateKey] = modificationDate
		}
		
		return metadata
	}


	/// Tranforms the metadata dictionary into an order list of human readable information (with optional click actions)
	
	@MainActor override open var localizedMetadata:[ObjectMetadataEntry]
    {
		guard let url = data as? URL else { return  [] }
		let dict = self.metadata ?? [:]
		var array:[ObjectMetadataEntry] = []
		
		let label = NSLocalizedString("Metadata.label.file", bundle:.BXMediaBrowser, comment:"Metadata Label")
		array += ObjectMetadataEntry(label:label, value:self.name, action:url.reveal)
		
		if let value = dict[.fileSizeKey] as? Int
		{
			let label = NSLocalizedString("Metadata.label.fileSize", bundle:.BXMediaBrowser, comment:"Metadata Label")
			array += ObjectMetadataEntry(label:label, value:value.fileSizeDescription)
		}
		
		if let value = dict[.captureDateKey] as? Date
		{
			let label = NSLocalizedString("Metadata.label.captureDate", bundle:.BXMediaBrowser, comment:"Metadata Label")
			array += ObjectMetadataEntry(label:label, value:String(with:value))
		}
		else if let value = dict[.creationDateKey] as? Date
		{
			let label = NSLocalizedString("Metadata.label.creationDate", bundle:.BXMediaBrowser, comment:"Metadata Label")
			array += ObjectMetadataEntry(label:label, value:String(with:value))
		}
		else if let value = dict[.modificationDateKey] as? Date
		{
			let label = NSLocalizedString("Metadata.label.modificationDate", bundle:.BXMediaBrowser, comment:"Metadata Label")
			array += ObjectMetadataEntry(label:label, value:String(with:value))
		}
		
		return array
    }


//----------------------------------------------------------------------------------------------------------------------


	// MARK: -

	/// Since we are already dealing with a local media file, this function simply returns the specified file URL
	
	open class func downloadFile(for identifier:String, data:Any) async throws -> URL
	{
		FolderSource.log.verbose {"\(Self.self).\(#function) \(identifier)"}

		guard let url = data as? URL else { throw Error.downloadFileFailed }
		guard url.exists else { throw Error.downloadFileFailed }
//		guard !item.isDRMProtected else { throw Object.Error.drmProtected }

		// Since we already have the file on disk we do not really spend any time in this "downloadFile"
		// function. But we will still create a local progress object and set it to 100% immediately,
		// so that Progress.globalParent gets notified and the progress bar is updated appropriately.
		
		#warning("FIXME: Implement proper progress reporting, since the above comment is no longer valid when considering cloud storage")
		
		if let parent = Progress.globalParent
		{
			let local = Progress(parent:nil)
			local.totalUnitCount = 1
			parent.addChild(local, withPendingUnitCount:1)
			local.completedUnitCount = 1
		}

	// MARK: - Cloud Based Files
	
	// Reading the contents of a cloud based file whose contents have been evicted (e.g. in iCloud Drive) makes the
	// system download the WHOLE file. Merely browsing a folder must not do that, so thumbnails and metadata of such
	// files are loaded from sources that do not need the file contents: the thumbnail that the file provider keeps
	// in the cloud, and the attributes that Spotlight has indexed. Only downloadFile() may trigger a download.
	
	/// Loads the thumbnail for the specified file. If the file is local, the thumbnail is created by readingFile.
	/// If it is an evicted cloud file, the preview thumbnail is fetched from the file provider instead. Only if the
	/// file provider doesn't have one (rare), the file is downloaded as a last resort, since images and videos must
	/// be identifiable in the browser - a generic file icon is not acceptable for them.
	
	public class func loadThumbnail(for url:URL, readingFile:@escaping (URL) async throws -> CGImage) async throws -> CGImage
	{
		guard url.isEvictedCloudItem else { return try await readingFile(url) }
		
		if let thumbnail = await QLThumbnailGenerator.shared.previewThumbnail(with:url, maxSize:CGSize(width:256, height:256))
		{
			return thumbnail
		}
		
		FolderSource.log.warning {"\(Self.self).\(#function) no cloud thumbnail available, downloading \(url)"}

		// Fallback downloads run one at a time, so that scrolling past many such files doesn't fan out into
		// dozens of simultaneous downloads
		
		return try await Self.downloadFallbackLimiter.perform
		{
			try await Tasks.canContinue()
			return try await url.downloadFromCloudIfNeeded(byAccessor:readingFile)
		}
	}
	
	private static let downloadFallbackLimiter = BXConcurrencyLimiter(limit:1)
	
	
	/// Returns the Spotlight attributes for the specified keys. Since some information (e.g. EXIF) is not available
	/// this way, the returned dictionary is marked as partial, so that the full metadata is loaded as soon as the
	/// file has been downloaded (see Object.localFileURL).
	
	public class func spotlightMetadata(for url:URL, keys:[String]) -> [String:Any]
	{
		var metadata:[String:Any] = [:]
		
		for (key,value) in url.spotlightMetadata(for:keys.map { $0 as CFString })
		{
			metadata[key as String] = value
		}
		
		metadata[.isPartialMetadataKey] = true
		return metadata
	}


	// Return the URL to the media file
	
	open var url:URL?
	{
		data as? URL
	}
	
	
	// Since the file is already local we can get its filename
	
	override public var localFileName:String
	{
		guard let url = self.url else { return super.localFileName }
		return url.lastPathComponent
	}
	
	
	/// Returns the URL for QLPreviewPanel
	
	override open var previewItemURL:URL!
    {
		self.url
    }


//----------------------------------------------------------------------------------------------------------------------


	// MARK: -

	/// Reveal the media file in the Finder
	
	public func revealInFinder()
	{
		guard let url = data as? URL else { return }
		url.reveal()
	}
}


//----------------------------------------------------------------------------------------------------------------------


