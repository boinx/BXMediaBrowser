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


#if os(macOS)

import BXSwiftUtils
import iTunesLibrary
import UniformTypeIdentifiers
import QuickLook
import AppKit


//----------------------------------------------------------------------------------------------------------------------


public class MusicObject : Object
{
	/// Creates a new MusicObject with the specified ITLibMediaItem
	///
	public init(with item:ITLibMediaItem)
	{
		let identifier = "MusicSource:ITLibMediaItem:\(item.persistentID)"
		let name = item.title
		
		super.init(
			identifier: identifier,
			name: name,
			data: item,
			loadThumbnailHandler: Self.loadThumbnail,
			loadMetadataHandler: Self.loadMetadata,
			downloadFileHandler: Self.downloadFile)
			
		self.isLocallyAvailable = item.locationType == .file && item.location != nil
		self.isDRMProtected = item.isDRMProtected
		self.isDownloadable = false
		self.isEnabled = isLocallyAvailable
		
		if isDRMProtected && Config.DRMProtectedFile.isEnabled == false
		{
			self.isEnabled = false
		}
	}

	override nonisolated public var mediaType:MediaType
	{
		return .audio
	}


//----------------------------------------------------------------------------------------------------------------------


	/// Creates a thumbnail image for the ITLibMediaItem
	
	class func loadThumbnail(for identifier:String, data:Any) async throws -> CGImage
	{
		guard let item = data as? ITLibMediaItem else { throw Error.notFound }
		let url = item.location
		let uti = url?.uti ?? "public.mp3"
		
		if #available(macOS 11, *)
		{
			if let type = UTType(uti)
			{
				let image = NSWorkspace.shared.icon(for:type)
				guard let thumbnail = image.cgImage(forProposedRect:nil, context:nil, hints:nil) else { throw Error.loadThumbnailFailed }
				return thumbnail
			}
		}
		
		guard let url = url else { throw Error.notFound }
		let image = NSWorkspace.shared.icon(forFile:url.path)
		guard let thumbnail = image.cgImage(forProposedRect:nil, context:nil, hints:nil) else { throw Error.loadThumbnailFailed }
		return thumbnail
	}


//----------------------------------------------------------------------------------------------------------------------


	/// Loads the metadata dictionary
	
	class func loadMetadata(for identifier:String, data:Any) async throws -> [String:Any]
	{
		guard let item = data as? ITLibMediaItem else { throw Object.Error.loadMetadataFailed }
		let artist = (item.artist?.name ?? "") as String
		var metadata:[String:Any] = [:]
		
		metadata[.titleKey] = item.title
		metadata[.authorsKey] = [artist]
		metadata[.composerKey] = item.composer
		metadata[.albumKey] = item.album.title
		metadata[.genreKey] = item.genre
		metadata[.durationKey] = Double(item.totalTime) / 1000.0
		metadata[.fileSizeKey] = Int(item.fileSize)
		metadata[.kindKey] = item.kind
		metadata[.tempoKey] = Double(item.beatsPerMinute)
		metadata["bpm"] = Double(item.beatsPerMinute)

		return metadata
	}


	/// Tranforms the metadata dictionary into an order list of human readable information (with optional click actions)
	
	@MainActor override open var localizedMetadata:[ObjectMetadataEntry]
    {
//		guard let item = data as? ITLibMediaItem else { return [] }
		let metadata = self.metadata ?? [:]
		var array:[ObjectMetadataEntry] = []
		
		if let name = metadata[.titleKey] as? String, !name.isEmpty
		{
			let label = NSLocalizedString("Song", tableName:"Music", bundle:.BXMediaBrowser, comment:"Label")
			array += ObjectMetadataEntry(label:label, value:name, action:{ [weak self] in self?.revealInFinder() })
		}
		
		if let duration = metadata[.durationKey] as? Double
		{
			let label = NSLocalizedString("Duration", tableName:"Music", bundle:.BXMediaBrowser, comment:"Label")
			array += ObjectMetadataEntry(label:label, value:duration.shortTimecodeString())
		}
		
		if let artists = metadata[.authorsKey] as? [String], !artists.isEmpty
		{
			let label = NSLocalizedString("Artist", tableName:"Music", bundle:.BXMediaBrowser, comment:"Label")
			array += ObjectMetadataEntry(label:label, value:artists.joined(separator:"\n"))
		}
		
		if let composer = metadata[.composerKey] as? String, !composer.isEmpty
		{
			let label = NSLocalizedString("Composer", tableName:"Music", bundle:.BXMediaBrowser, comment:"Label")
			array += ObjectMetadataEntry(label:label, value:composer)
		}
		
		if let album = metadata[.albumKey] as? String, !album.isEmpty
		{
			let label = NSLocalizedString("Album", tableName:"Music", bundle:.BXMediaBrowser, comment:"Label")
			array += ObjectMetadataEntry(label:label, value:album)
		}
		
		if let genre = metadata[.genreKey] as? String, !genre.isEmpty
		{
			let label = NSLocalizedString("Genre", tableName:"Music", bundle:.BXMediaBrowser, comment:"Label")
			array += ObjectMetadataEntry(label:label, value:genre)
		}
		
		if let value = metadata[.fileSizeKey] as? Int, let str = Formatter.fileSizeFormatter.string(for:value)
		{
			let label = NSLocalizedString("File Size", tableName:"Music", bundle:.BXMediaBrowser, comment:"Label")
			array += ObjectMetadataEntry(label:label, value:str) // value.fileSizeDescription)
		}
		
		return array
    }


	/// This optional comment can be displayed in the user interface, e.g. as a tooltip
	
	@MainActor override open var comment:String?
	{
		isLocallyAvailable ? nil : NSLocalizedString("MusicObject.tooltip.download", tableName:"Music", bundle:.BXMediaBrowser, comment:"Tooltip for Music.app songs that are not available locally")
	}
	
	
//----------------------------------------------------------------------------------------------------------------------


	/// Returns the UTI of the promised local file
	
	override public var localFileUTI:String
	{
		guard let item = data as? ITLibMediaItem else { return String.audioUTI }
		guard let url = item.location else { return String.audioUTI }
		return url.uti ?? String.audioUTI
	}


	/// Returns the filename of the local file
	
	override public var localFileName:String
	{
		let defaultFilename = NSLocalizedString("Audio File", tableName:"Music", bundle:.BXMediaBrowser, comment:"Default Filename")
		guard let item = data as? ITLibMediaItem else { return defaultFilename }
		guard let url = item.location else { return defaultFilename }
		return url.lastPathComponent
	}
	
	
	/// Returns the local file URL. If this file is only in the cloud this function throws an error,
	/// because the iTunesLibrary API doesn't support downloading the audio file.
	
	class func downloadFile(for identifier:String, data:Any) async throws -> URL
	{
		guard let item = data as? ITLibMediaItem else { throw Object.Error.notFound }
		guard let url = item.location else { throw Object.Error.notFound }
		guard item.locationType == .file else { throw Object.Error.notFound }
		
		if Config.DRMProtectedFile.isEnabled == false && item.isDRMProtected
		{
			throw Object.Error.drmProtected
		}

		return url
	}
	

	/// Returns the URL for QLPreviewPanel
	
	override public var previewItemURL:URL!
    {
		guard let item = data as? ITLibMediaItem else { return nil }
		guard let url = item.location else { return nil }
		return url
    }
    
    
    /// Reveals the local audio file in the Finder
	
    func revealInFinder()
    {
		guard let url = self.previewItemURL else { return }
		guard url.exists else { return }
		NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath:url.deletingLastPathComponent().path)
    }
}


//----------------------------------------------------------------------------------------------------------------------


#endif
