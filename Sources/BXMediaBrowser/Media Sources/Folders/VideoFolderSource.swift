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
import AVFoundation
import QuickLook
import Foundation


//----------------------------------------------------------------------------------------------------------------------


open class VideoFolderSource : FolderSource
{
	/// Creates a Container for the folder at the specified URL
	
	override open func createContainer(for url:URL, filter:FolderFilter, in library:Library?) throws -> Container?
	{
		VideoFolderContainer(
			url: url,
			filter: filter,
			removeHandler: { [weak self] in self?.removeTopLevelContainer($0) },
			in: library)
	}


	/// Returns the user "Movies" folder, but only the first time around
	
	override open func defaultContainers(with filter:FolderFilter) async throws -> [Container]
	{
		guard !didAddDefaultContainers else { return [] }
		
		guard let url = FileManager.default.urls(for:.moviesDirectory, in:.userDomainMask).first?.resolvingSymlinksInPath() else { return [] }
		guard url.isReadable else { return [] }
		guard let container = try self.createContainer(for:url, filter:filter, in:library) else { return [] }

		return [container]
	}
}


//----------------------------------------------------------------------------------------------------------------------


// MARK: -

open class VideoFolderContainer : FolderContainer
{
	override open class func createObject(for url:URL, filter:FolderFilter, in library:Library?) throws -> Object?
	{
		guard url.exists else { throw Object.Error.notFound }
		guard url.isVideoFile else { return nil }
		return VideoFile(url:url, in:library)
	}

	override nonisolated open var mediaTypes:[Object.MediaType]
	{
		return [.video]
	}

    @MainActor override open var localizedObjectCount:String
    {
		let n = self.objects.count
		let str = n.localizedVideosString
		return str
    }
}


//----------------------------------------------------------------------------------------------------------------------


// MARK: -

open class VideoFile : FolderObject
{
	override nonisolated public var mediaType:MediaType
	{
		return .video
	}

	/// Creates a thumbnail image for the specified local file URL
	
	override open class func loadThumbnail(for identifier:String, data:Any) async throws -> CGImage
	{
		FolderSource.log.verbose {"\(Self.self).\(#function) \(identifier)"}

		guard let url = data as? URL else { throw Error.loadThumbnailFailed }
		guard url.exists else { throw Error.loadThumbnailFailed }
		let size = CGSize(256,256)

		// Try with AVAssetImageGenerator
		
		do
		{
			let asset = AVURLAsset(url:url)
			let duration = asset.duration.seconds
			let posterFrame = 0.5 * duration
			let time = CMTime(seconds:posterFrame, preferredTimescale:600)
			
			let generator = AVAssetImageGenerator(asset:asset)
			generator.appliesPreferredTrackTransform = true
			generator.maximumSize = size
			
			let thumbnail = try generator.copyCGImage(at:time, actualTime:nil)
			return thumbnail
		}
		
		// Use QuickLook as fallback solution
		
		catch let error
		{
			#if os(macOS)
			
			if let image = QLThumbnailImageCreate(kCFAllocatorDefault, url as CFURL, size, nil)?.takeRetainedValue()
			{
				return image
			}
			
			throw error
			
			#else
			
			return try await QLThumbnailGenerator.shared.thumbnail(with:url, maxSize:size)

			#endif
		}
	}


	/// Loads the metadata dictionary for the specified local file URL
	
	override open class func loadMetadata(for identifier:String, data:Any) async throws -> [String:Any]
	{
		FolderSource.log.verbose {"\(Self.self).\(#function) \(identifier)"}

		guard let url = data as? URL else { throw Error.loadMetadataFailed }
		guard url.exists else { throw Error.loadMetadataFailed }
		
		var metadata = try await super.loadMetadata(for:identifier, data:data)
		
		let videoInfo = url.videoMetadata
		
		for (key,value) in videoInfo
		{
			metadata[key as String] = value
		}
		
		if let exif = metadata["{Exif}"] as? [String:Any], let str = exif[.exifCaptureDateKey] as? String
		{
			metadata[.captureDateKey] = str.date
		}

		return metadata
	}

	
	/// Tranforms the metadata dictionary into an order list of human readable information (with optional click actions)
	
	@MainActor override open var localizedMetadata:[ObjectMetadataEntry]
    {
		guard let url = data as? URL else { return [] }
		let metadata = self.metadata ?? [:]
		var array:[ObjectMetadataEntry] = []
		
		let label = NSLocalizedString("Metadata.label.file", bundle:.BXMediaBrowser, comment:"Metadata Label")
		array += ObjectMetadataEntry(label:label, value:self.name, action:url.reveal)
		
		if let kind = metadata[.kindKey] as? String, !kind.isEmpty
		{
			let label = NSLocalizedString("Metadata.label.kind", bundle:.BXMediaBrowser, comment:"Metadata Label")
			array += ObjectMetadataEntry(label:label, value:kind)
		}

		if let w = metadata[.widthKey] as? Int, let h = metadata[.heightKey] as? Int
		{
			let label = NSLocalizedString("Metadata.label.videoSize", bundle:.BXMediaBrowser, comment:"Metadata Label")
			array += ObjectMetadataEntry(label:label, value:"\(w) × \(h) Pixels")
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
		
		if let codecs = metadata[.codecsKey] as? [String], !codecs.isEmpty
		{
			let label = NSLocalizedString("Metadata.label.codec", bundle:.BXMediaBrowser, comment:"Metadata Label")
			array += ObjectMetadataEntry(label:label, value:codecs.joined(separator:", "))
		}
		
		if let value = metadata[.exifCaptureDateKey] as? String, let date = value.date
		{
			let label = NSLocalizedString("Metadata.label.captureDate", bundle:.BXMediaBrowser, comment:"Metadata Label")
			array += ObjectMetadataEntry(label:label, value:String(with:date))
		}
		else if let value = metadata[.captureDateKey] as? Date
		{
			let label = NSLocalizedString("Metadata.label.captureDate", bundle:.BXMediaBrowser, comment:"Metadata Label")
			array += ObjectMetadataEntry(label:label, value:String(with:value))
		}
		else if let value = metadata[.creationDateKey] as? Date
		{
			let label = NSLocalizedString("Metadata.label.creationDate", bundle:.BXMediaBrowser, comment:"Metadata Label")
			array += ObjectMetadataEntry(label:label, value:String(with:value))
		}
		else if let value = metadata[.modificationDateKey] as? Date
		{
			let label = NSLocalizedString("Metadata.label.modificationDate", bundle:.BXMediaBrowser, comment:"Metadata Label")
			array += ObjectMetadataEntry(label:label, value:String(with:value))
		}
		
		return array
    }


	/// Returns the UTI of the promised image file
	
	override public var localFileUTI:String
	{
		guard let url = data as? URL else { return String.movieUTI }
		return url.uti ?? String.movieUTI
	}
}


//----------------------------------------------------------------------------------------------------------------------

