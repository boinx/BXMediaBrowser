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

#if os(macOS)
import AppKit
#else
import UIKit
#endif


//----------------------------------------------------------------------------------------------------------------------


open class AudioFolderSource : FolderSource
{
	/// Creates a Container for the folder at the specified URL
	
	override open func createContainer(for url:URL, filter:FolderFilter) throws -> Container?
	{
		AudioFolderContainer(url:url, filter:filter)
		{
			[weak self] in self?.removeTopLevelContainer($0)
		}
	}
}


//----------------------------------------------------------------------------------------------------------------------


// MARK: -

open class AudioFolderContainer : FolderContainer
{
	override open class func createObject(for url:URL, filter:FolderFilter) throws -> Object?
	{
		guard url.exists else { throw Object.Error.notFound }
		guard url.isAudioFile else { return nil }
		return AudioFile(url:url)
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
		
		let image = NSWorkspace.shared.icon(forFile:url.path)
		guard let thumbnail = image.cgImage(forProposedRect:nil, context:nil, hints:nil) else { throw Error.loadThumbnailFailed }
		return thumbnail
	}


	/// Loads the metadata dictionary for the specified local file URL
	
	override open class func loadMetadata(for identifier:String, data:Any) async throws -> [String:Any]
	{
		FolderSource.log.verbose {"\(Self.self).\(#function) \(identifier)"}

		guard let url = data as? URL else { throw Error.loadMetadataFailed }
		guard url.exists else { throw Error.loadMetadataFailed }
		
		var metadata = try await super.loadMetadata(for:identifier, data:data)
		
		let audioInfo = url.audioMetadata
		
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
			array += ObjectMetadataEntry(label:"Song", value:name, action:url.reveal)
		}
		
		if let album = metadata[.albumKey] as? String, !album.isEmpty
		{
			array += ObjectMetadataEntry(label:"Album", value:album)
		}
		
		if let artists = metadata[.authorsKey] as? [String], !artists.isEmpty
		{
			array += ObjectMetadataEntry(label:"Artist", value:artists.joined(separator:"\n"))
		}
		
		if let composer = metadata[.composerKey] as? String, !composer.isEmpty
		{
			array += ObjectMetadataEntry(label:"Composer", value:composer)
		}
		
		if let genre = metadata[.genreKey] as? String, !genre.isEmpty
		{
			array += ObjectMetadataEntry(label:"Genre", value:genre)
		}
		
		if let duration = metadata[.durationKey] as? Double
		{
			array += ObjectMetadataEntry(label:"Duration", value:duration.shortTimecodeString())
		}
		
		if let value = metadata[.fileSizeKey] as? Int, let str = Formatter.fileSizeFormatter.string(for:value)
		{
			array += ObjectMetadataEntry(label:"File Size", value:str)
		}

		if let value = metadata[.tempoKey] as? Double, let str = Formatter.singleDigitFormatter.string(for:value)
		{
			array += ObjectMetadataEntry(label:"Tempo", value:"\(str) BPM")
		}

		if let value = metadata[.whereFromsKey] as? [String], let str = value.first, let url = URL(string:str)
		{
			array += ObjectMetadataEntry(label:"URL", value:str, action:url.open)
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


