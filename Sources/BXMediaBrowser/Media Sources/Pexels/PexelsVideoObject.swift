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
import ImageIO

#if canImport(AppKit)
import AppKit
#endif

#if canImport(UIKit)
import UIKit
#endif

#if canImport(MobileCoreServices)
import MobileCoreServices
#endif


//----------------------------------------------------------------------------------------------------------------------


open class PexelsVideoObject : Object
{
	/// Creates a new Object for the file at the specified URL
	
	public required init(with video:Pexels.Video)
	{
		let format = NSLocalizedString("%@ on Pexels", tableName:"Pexels", bundle:.BXMediaBrowser, comment:"Label")
		let name = String(format:format, video.user.name)
		
		super.init(
			identifier: "PexelsSource:Video:\(video.id)",
			name: name,
			data: video,
			loadThumbnailHandler: Self.loadThumbnail,
			loadMetadataHandler: Self.loadMetadata,
			downloadFileHandler: Self.downloadFile)
	}

	override nonisolated public var mediaType:MediaType
	{
		return .video
	}


//----------------------------------------------------------------------------------------------------------------------


	/// Creates a thumbnail image for the specified local file URL
	
	open class func loadThumbnail(for identifier:String, data:Any) async throws -> CGImage
	{
		guard let video = data as? Pexels.Video else { throw Error.loadThumbnailFailed }
		guard let url = URL(string:video.image) else { throw Error.loadThumbnailFailed }
		
		let data = try await URLSession.shared.data(with:url)
		guard let source = CGImageSourceCreateWithData(data as CFData,nil) else { throw Error.loadThumbnailFailed }
		guard let image = CGImageSourceCreateImageAtIndex(source,0,nil) else { throw Error.loadThumbnailFailed }
		
		return image
	}


//----------------------------------------------------------------------------------------------------------------------


	/// Loads the metadata dictionary for the specified local file URL
	
	open class func loadMetadata(for identifier:String, data:Any) async throws -> [String:Any]
	{
		Pexels.log.verbose {"\(Self.self).\(#function) \(identifier)"}

		guard let video = data as? Pexels.Video else { throw Error.loadMetadataFailed }
		let format = NSLocalizedString("%@ on Pexels", tableName:"Pexels", bundle:.BXMediaBrowser, comment:"Label")
		let copyright = String(format:format, video.user.name)

		var metadata:[String:Any] = [:]
		
		metadata[.widthKey] = video.width
		metadata[.heightKey] = video.height
		metadata[.durationKey] = [video.duration]
		metadata[.whereFromsKey] = [video.url]
		metadata[.authorsKey] = [video.user.name]
		metadata[.authorAddressesKey] = [video.user.url]
		metadata[.copyrightKey] = copyright

		return metadata
	}


	/// Tranforms the metadata dictionary into an order list of human readable information (with optional click actions)
	
	@MainActor override open var localizedMetadata:[ObjectMetadataEntry]
    {
		guard let video = data as? Pexels.Video else { return [] }
		
		let openPhotoPage:()->Void =
		{
			URL(string:video.url)?.open()
		}
		
		let openUserPage:()->Void =
		{
			URL(string:video.user.url)?.open()
		}
		
		var array:[ObjectMetadataEntry] = []
		
		let photoLabel = NSLocalizedString("Video", tableName:"Pexels", bundle:.BXMediaBrowser, comment:"Label")
		array += ObjectMetadataEntry(label:photoLabel, value:"Pexels.com", action:openPhotoPage)

		let photographerLabel = NSLocalizedString("Photographer", tableName:"Pexels", bundle:.BXMediaBrowser, comment:"Label")
		array += ObjectMetadataEntry(label:photographerLabel, value:video.user.name, action:openUserPage)
		
		let imageSizeLabel = NSLocalizedString("Video Size", tableName:"Pexels", bundle:.BXMediaBrowser, comment:"Label")
		array += ObjectMetadataEntry(label:imageSizeLabel, value:"\(video.width) × \(video.height) Pixels")
		
		return array
    }
    
    
//----------------------------------------------------------------------------------------------------------------------


	// Returns the filename of the file that will be downloaded
	
	override public var localFileName:String
	{
		Self.localFileName(for:identifier, data:data)
	}
	
	// Unsplash always return movie - can we be even more specific with MP4?
	
	override public var localFileUTI:String
	{
		var uti = kUTTypeMovie as String
		
		guard let file = try? Self.bestFile(for:identifier, data:data) else { return uti }
		let mimeType = file.file_type as CFString
		if let _uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mimeType, nil)?.takeUnretainedValue()
		{
			uti = _uti as String
		}
		
		return uti
	}
	
	static func localFileName(for identifier:String, data:Any) -> String
	{
		var filename = "PexelsVideo.mp4"

		guard let file = try? Self.bestFile(for:identifier, data:data) else { return filename }
		guard let url = URL(string:file.link) else { return filename }
		filename = url.pathComponents.last ?? filename
		
		return filename
	}
	
	
	/// Return the remote URL for a Pexels Photo
	
	class func remoteURL(for identifier:String, data:Any) throws -> URL
	{
		let file = try self.bestFile(for:identifier, data:data)
		guard let url = URL(string:file.link) else { throw Error.downloadFileFailed }
		return url
	}
	
	
	/// Starts downloading an image file
	
	open class func downloadFile(for identifier:String, data:Any) async throws -> URL
	{
		Pexels.log.debug {"\(Self.self).\(#function) \(identifier)"}

		// Download the file
		
		let remoteURL = try remoteURL(for:identifier, data:data)
		let tmpURL = try await URLSession.shared.downloadFile(from:remoteURL)
		
		// Rename the file
		
		let folderURL = tmpURL.deletingLastPathComponent()
		let filename = self.localFileName(for:identifier, data:data)
		let localURL = folderURL.appendingPathComponent(filename)

		try? FileManager.default.removeItem(at:localURL)
		try FileManager.default.moveItem(at:tmpURL, to:localURL)
		
		// Register in TempFilePool
		
		TempFilePool.shared.register(localURL)
		return localURL
	}


	open class func bestFile(for identifier:String, data:Any) throws -> Pexels.Video.File
	{
		guard let video = data as? Pexels.Video else { throw Error.downloadFileFailed }

		var bestIndex = 0
		var maxPixels = 0
		
		for (i,file) in video.video_files.enumerated()
		{
			let w = file.width ?? 0
			let h = file.height ?? 0
			let n = w * h
			
			if n > maxPixels
			{
				bestIndex = i
				maxPixels = n
			}
		}
		
		guard bestIndex >= 0 && bestIndex < video.video_files.count else { throw Error.downloadFileFailed }
		
		return video.video_files[bestIndex]
	}


//----------------------------------------------------------------------------------------------------------------------


	/// QuickLook support
	
	override public var previewItemURL:URL!
    {
		guard let video = data as? Pexels.Video else { return nil }
		guard let str = video.video_files.last?.link else { return nil }
		return URL(string:str)
    }
    
	override open var previewItemTitle: String!
    {
		return self.name
    }
}


//----------------------------------------------------------------------------------------------------------------------



