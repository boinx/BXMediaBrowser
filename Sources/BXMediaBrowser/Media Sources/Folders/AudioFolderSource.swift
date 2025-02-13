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
import Foundation

#if canImport(AppKit)
import AppKit // for NSWorkspace
#endif

#if canImport(QuickLookThumbnailing)
import QuickLookThumbnailing // for QLThumbnailGenerator
#endif


//----------------------------------------------------------------------------------------------------------------------


open class AudioFolderSource : FolderSource
{
	/// Creates a Container for the folder at the specified URL
	
	override open func createContainer(for url:URL, filter:FolderFilter, in library:Library?) throws -> Container?
	{
		AudioFolderContainer(
			url:url,
			filter:filter,
			removeHandler: { [weak self] in self?.removeTopLevelContainer($0) },
			in:library)
	}


	/// Returns the user "Music" folder, but only the first time around
	
	override open func defaultContainers(with filter:FolderFilter) async throws -> [Container]
	{
		guard !didAddDefaultContainers else { return [] }
		
		var containers:[Container] = []
		
		// ~/Music
		
		if let url = FileManager.default.urls(for:.musicDirectory, in:.userDomainMask).first?.resolvingSymlinksInPath(), url.isReadable
		{
			containers += try self.createContainer(for:url, filter:filter, in:library)
		}
		
		// /Library/Audio/Apple Loops/Apple
		
		containers += try await MainActor.run
		{
			()->Container? in
			guard let url = self.requestReadAccessRights(for:URL(fileURLWithPath:"/Library/Audio/Apple Loops/Apple")) else { return nil }
			return try self.createContainer(for:url, filter:filter, in:library)
		}
		
		return containers
	}
}


//----------------------------------------------------------------------------------------------------------------------


// MARK: -

open class AudioFolderContainer : FolderContainer
{
	// In addition to the filename, this function also searches various audio metadata fields
	
	override open class func filter(_ url:URL, with filter:FolderFilter) -> URL?
	{
		guard url.isAudioFile else { return nil }
		
		let searchString = filter.searchString.lowercased()
		guard !searchString.isEmpty else { return url }
		
		let filename = url.lastPathComponent.lowercased()
		if filename.contains(searchString) { return url }

		let audioMetadata = url.audioMetadata

		if let title = audioMetadata[kMDItemTitle] as? String, title.lowercased().contains(searchString)
		{
			return url
		}

		if let authors = audioMetadata[kMDItemAuthors] as? [String]
		{
			for author in authors
			{
				if author.lowercased().contains(searchString) { return url }
			}
		}

		if let composer = audioMetadata[kMDItemComposer] as? String, composer.lowercased().contains(searchString)
		{
			return url
		}
		
		if let album = audioMetadata[kMDItemAlbum] as? String, album.lowercased().contains(searchString)
		{
			return url
		}
		
		if let genre = audioMetadata[kMDItemMusicalGenre] as? String, genre.lowercased().contains(searchString)
		{
			return url
		}
		
		if let copyright = audioMetadata[kMDItemCopyright] as? String, copyright.lowercased().contains(searchString)
		{
			return url
		}
		
		return nil
	}


	override open class func createObject(for url:URL, filter:FolderFilter, in library:Library?) throws -> Object?
	{
		if Config.DRMProtectedFile.isVisible == false && url.pathExtension == "m4p"
		{
			return nil
		}
		
		if Config.CorruptedAppleLoops.isVisible == false && url.isCorruptedAppleLoopFile
		{
			return nil
		}
		
		return AudioFile(url:url, in:library)
	}

	override nonisolated open var mediaTypes:[Object.MediaType]
	{
		return [.audio]
	}

    @MainActor override open var localizedObjectCount:String
    {
		let n = self.objects.count
		let str = n.localizedSongsString
		return str
    }
}


//----------------------------------------------------------------------------------------------------------------------


// MARK: -

open class AudioFile : FolderObject
{
	override public init(url:URL, name:String? = nil, in library:Library?)
	{
		FolderSource.log.verbose {"\(Self.self).\(#function) url = \(url)"}

		super.init(url:url, name:name, in:library)
		
		/// Check if this a DRM protected audio file, and whether it should be enabled or disabled
		
		self.isDRMProtected = url.pathExtension == "m4p"
		
		if self.isDRMProtected
		{
			self.isEnabled = Config.DRMProtectedFile.isEnabled
		}
		else if url.isCorruptedAppleLoopFile
		{
			self.isEnabled = Config.CorruptedAppleLoops.isEnabled
		}
		else
		{
			self.isEnabled = true
		}
	}


	override nonisolated public var mediaType:MediaType
	{
		return .audio
	}

    
	/// Returns a generic Finder icon for the audio file
	
	override open class func loadThumbnail(for identifier:String, data:Any) async throws -> CGImage
	{
		FolderSource.log.verbose {"\(Self.self).\(#function) \(identifier)"}

		guard let url = data as? URL else { throw Error.loadThumbnailFailed }
		guard url.exists else { throw Error.loadThumbnailFailed }
		
		return try await url.downloadFromCloudIfNeeded
		{
			url in
			#if os(macOS)
			
			let image = NSWorkspace.shared.icon(forFile:url.path)
			guard let thumbnail = image.cgImage(forProposedRect:nil, context:nil, hints:nil) else { throw Error.loadThumbnailFailed }
			return thumbnail
			
			#else
			
			let size = CGSize(256,256)
			return try await QLThumbnailGenerator.shared.thumbnail(with:url, maxSize:size, type:.icon)
			
			#endif
		}
	}


	/// Loads the metadata dictionary for the specified local file URL
	
	override open class func loadMetadata(for identifier:String, data:Any) async throws -> [String:Any]
	{
		FolderSource.log.verbose {"\(Self.self).\(#function) \(identifier)"}

		guard let url = data as? URL else { throw Error.loadMetadataFailed }
		guard url.exists else { throw Error.loadMetadataFailed }
		
		// Get general file metadata
		
		var metadata = try await super.loadMetadata(for:identifier, data:data)
		
		// Get audio specific info
		
		let audioInfo = try await url.downloadFromCloudIfNeeded
		{
			url in url.audioMetadata
		}
		
		// And copy it to metadata dict
		
		for (key,value) in audioInfo
		{
			metadata[key as String] = value
		}
		
		return metadata
	}

	
	/// Tranforms the metadata dictionary into an order list of human readable information (with optional click actions)
	
	@MainActor override open var localizedMetadata:[ObjectMetadataEntry]
    {
		guard let url = data as? URL else { return [] }
		let metadata = self.metadata ?? [:]
		var array:[ObjectMetadataEntry] = []
		
		if let name = metadata[.titleKey] as? String, !name.isEmpty
		{
			let label = NSLocalizedString("Metadata.label.song", bundle:.BXMediaBrowser, comment:"Metadata Label")
			array += ObjectMetadataEntry(label:label, value:name, action:url.reveal)
		}
		
		if let album = metadata[.albumKey] as? String, !album.isEmpty
		{
			let label = NSLocalizedString("Metadata.label.album", bundle:.BXMediaBrowser, comment:"Metadata Label")
			array += ObjectMetadataEntry(label:label, value:album)
		}
		
		if let artists = metadata[.authorsKey] as? [String], !artists.isEmpty
		{
			let label = NSLocalizedString("Metadata.label.artist", bundle:.BXMediaBrowser, comment:"Metadata Label")
			array += ObjectMetadataEntry(label:label, value:artists.joined(separator:"\n"))
		}
		
		if let composer = metadata[.composerKey] as? String, !composer.isEmpty
		{
			let label = NSLocalizedString("Metadata.label.composer", bundle:.BXMediaBrowser, comment:"Metadata Label")
			array += ObjectMetadataEntry(label:label, value:composer)
		}
		
		if let genre = metadata[.genreKey] as? String, !genre.isEmpty
		{
			let label = NSLocalizedString("Metadata.label.genre", bundle:.BXMediaBrowser, comment:"Metadata Label")
			array += ObjectMetadataEntry(label:label, value:genre)
		}
		
		if let duration = metadata[.durationKey] as? Double
		{
			let label = NSLocalizedString("Metadata.label.duration", bundle:.BXMediaBrowser, comment:"Metadata Label")
			array += ObjectMetadataEntry(label:label, value:duration.shortTimecodeString())
		}
		
		if let value = metadata[.fileSizeKey] as? Int, let str = Formatter.fileSizeFormatter.string(for:value)
		{
			let label = NSLocalizedString("Metadata.label.fileSize", bundle:.BXMediaBrowser, comment:"Metadata Label")
			array += ObjectMetadataEntry(label:label, value:str)
		}

		if let value = metadata[.tempoKey] as? Double, let str = Formatter.singleDigitFormatter.string(for:value)
		{
			let label = NSLocalizedString("Metadata.label.tempo", bundle:.BXMediaBrowser, comment:"Metadata Label")
			array += ObjectMetadataEntry(label:label, value:"\(str) BPM")
		}

		if let value = metadata[.whereFromsKey] as? [String], let str = value.first, let url = URL(string:str)
		{
			let label = NSLocalizedString("Metadata.label.url", bundle:.BXMediaBrowser, comment:"Metadata Label")
			array += ObjectMetadataEntry(label:label, value:str, action:url.open)
		}
		
		return array
    }
    
    
	/// Returns the UTI of the promised image file
	
	override public var localFileUTI:String
	{
		guard let url = data as? URL else { return String.audioUTI }
		return url.uti ?? String.audioUTI
	}
}


//----------------------------------------------------------------------------------------------------------------------


