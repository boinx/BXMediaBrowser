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
	
	override open func createContainer(for url:URL) throws -> Container?
	{
		VideoFolderContainer(url:url)
		{
			[weak self] in self?.removeContainer($0)
		}
	}
}


//----------------------------------------------------------------------------------------------------------------------


// MARK: -

open class VideoFolderContainer : FolderContainer
{
	override open class func createObject(for url:URL) throws -> Object?
	{
		guard url.exists else { throw Object.Error.notFound }
		guard url.isVideoFile else { return nil }
		return VideoFile(url:url)
	}

    @MainActor override var localizedObjectCount:String
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
			if let image = QLThumbnailImageCreate(kCFAllocatorDefault, url as CFURL, size, nil)?.takeRetainedValue()
			{
				return image
			}
			
			throw error
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
		
		return metadata
	}

	
	/// Tranforms the metadata dictionary into an order list of human readable information (with optional click actions)
	
	@MainActor override var localizedMetadata:[ObjectMetadataEntry]
    {
		guard let url = data as? URL else { return [] }
		let metadata = self.metadata ?? [:]
		var array:[ObjectMetadataEntry] = []
		
		array += ObjectMetadataEntry(label:"File", value:self.name, action:url.reveal)
		
		if let kind = metadata[kMDItemKind as String] as? String, !kind.isEmpty
		{
			array += ObjectMetadataEntry(label:"Kind", value:kind)
		}

		if let w = metadata[kMDItemPixelWidth as String] as? Int, let h = metadata[kMDItemPixelHeight as String] as? Int
		{
			array += ObjectMetadataEntry(label:"Video Size", value:"\(w) × \(h) Pixels")
		}
		
		if let duration = metadata[kMDItemDurationSeconds as String] as? Double
		{
			array += ObjectMetadataEntry(label:"Duration", value:duration.shortTimecodeString())
		}
		
		if let value = metadata[kMDItemFSSize as String] as? Int, let str = Formatter.fileSizeFormatter.string(for:value)
		{
			array += ObjectMetadataEntry(label:"File Size", value:str)
		}
		
		if let codecs = metadata[kMDItemCodecs as String] as? [String], !codecs.isEmpty
		{
			array += ObjectMetadataEntry(label:"Codecs", value:codecs.joined(separator:", "))
		}
		
		if let value = metadata["creationDate"] as? Date
		{
			array += ObjectMetadataEntry(label:"Creation Date", value:String(with:value))
		}
		
		return array
    }


	/// Returns the UTI of the promised image file
	
	override var localFileUTI:String
	{
		guard let url = data as? URL else { return String.movieUTI }
		return url.uti ?? String.movieUTI
	}
}


//----------------------------------------------------------------------------------------------------------------------

