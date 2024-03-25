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


open class PexelsPhotoObject : Object
{
	/// Creates a new Object for the file at the specified URL
	
	public required init(with photo:Pexels.Photo)
	{
		super.init(
			identifier: "PexelsSource:Photo:\(photo.id)",
			name: photo.alt,
			data: photo,
			loadThumbnailHandler: Self.loadThumbnail,
			loadMetadataHandler: Self.loadMetadata,
			downloadFileHandler: Self.downloadFile)
	}

	override nonisolated public var mediaType:MediaType
	{
		return .image
	}


//----------------------------------------------------------------------------------------------------------------------


	/// Creates a thumbnail image for the specified local file URL
	
	open class func loadThumbnail(for identifier:String, data:Any) async throws -> CGImage
	{
		guard let photo = data as? Pexels.Photo else { throw Error.loadThumbnailFailed }
		guard let url = URL(string:photo.src.small) else { throw Error.loadThumbnailFailed }
		
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

		guard let photo = data as? Pexels.Photo else { throw Error.loadMetadataFailed }
		let format = NSLocalizedString("%@ on Pexels", tableName:"Pexels", bundle:.BXMediaBrowser, comment:"Label")
		let copyright = String(format:format, photo.photographer)

		var metadata:[String:Any] = [:]
		
		metadata[.widthKey] = photo.width
		metadata[.heightKey] = photo.height
		metadata[.descriptionKey] = photo.alt
		metadata[.authorsKey] = [photo.photographer]
		metadata[.whereFromsKey] = [photo.url]
		metadata[.authorAddressesKey] = [photo.photographer_url]
		metadata[.copyrightKey] = copyright
		
		return metadata
	}


	/// Tranforms the metadata dictionary into an order list of human readable information (with optional click actions)
	
	@MainActor override open var localizedMetadata:[ObjectMetadataEntry]
    {
		guard let photo = data as? Pexels.Photo else { return [] }
		
		let openPhotoPage:()->Void =
		{
			URL(string:photo.url)?.open()
		}
		
		let openUserPage:()->Void =
		{
			URL(string:photo.photographer_url)?.open()
		}
		
		var array:[ObjectMetadataEntry] = []
		
		let photoLabel = NSLocalizedString("Photo", tableName:"Pexels", bundle:.BXMediaBrowser, comment:"Label")
		array += ObjectMetadataEntry(label:photoLabel, value:photo.alt, action:openPhotoPage)

		let photographerLabel = NSLocalizedString("Photographer", tableName:"Pexels", bundle:.BXMediaBrowser, comment:"Label")
		array += ObjectMetadataEntry(label:photographerLabel, value:photo.photographer, action:openUserPage)
		
		let imageSizeLabel = NSLocalizedString("Image Size", tableName:"Pexels", bundle:.BXMediaBrowser, comment:"Label")
		array += ObjectMetadataEntry(label:imageSizeLabel, value:"\(photo.width) × \(photo.height) Pixels")
		
		return array
    }
    
    
//----------------------------------------------------------------------------------------------------------------------


	// Returns the filename of the file that will be downloaded
	
	override public var localFileName:String
	{
		Self.localFileName(for:identifier, data:data)
	}
	
	// Unsplash always return image - can we be even more specific with JPEG?
	
	override public var localFileUTI:String
	{
		kUTTypeJPEG as String
	}
	
	static func localFileName(for identifier:String, data:Any) -> String
	{
		var filename = "PexelsPhoto.jpg"
		guard let photo = data as? Pexels.Photo else { return filename }
		filename = "Pexels.\(photo.id).jpg"
		return filename
	}
	
	
	/// Return the remote URL for a Pexels Photo
	
	class func remoteURL(for identifier:String, data:Any) throws -> URL
	{
		guard let photo = data as? Pexels.Photo else { throw Error.downloadFileFailed }
		let str = photo.src.original
		guard let url = URL(string:str) else { throw Error.downloadFileFailed }
		return url
	}
	
	
	/// Starts downloading an image file
	
	open class func downloadFile(for identifier:String, data:Any) async throws -> URL
	{
		Pexels.log.debug {"\(Self.self).\(#function) \(identifier)"}

		DraggingProgress.message = NSLocalizedString("Downloading", bundle:.BXMediaBrowser, comment:"Progress Message")
		
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


//----------------------------------------------------------------------------------------------------------------------


	/// QuickLook support
	
	override public var previewItemURL:URL!
    {
		guard let photo = data as? Pexels.Photo else { return nil }
		return URL(string:photo.src.large2x)
    }
    
	override open var previewItemTitle: String!
    {
		guard let photo = data as? Pexels.Photo else { return self.name }
		return photo.alt
    }
}


//----------------------------------------------------------------------------------------------------------------------
