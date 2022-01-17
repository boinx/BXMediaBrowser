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


import Foundation
import ImageIO


//----------------------------------------------------------------------------------------------------------------------


open class UnsplashObject : Object
{
	/// Creates a new Object for the file at the specified URL
	
	public init(with photo:UnsplashPhoto)
	{
		super.init(
			identifier: "UnsplashSource:Photo:\(photo.id)",
			name: photo.description ?? "Photo",
			data: photo,
			loadThumbnailHandler: Self.loadThumbnail,
			loadMetadataHandler: Self.loadMetadata,
			downloadFileHandler: Self.downloadFile)
	}


//----------------------------------------------------------------------------------------------------------------------


	/// Creates a thumbnail image for the specified local file URL
	
	open class func loadThumbnail(for identifier:String, data:Any) async throws -> CGImage
	{
		guard let photo = data as? UnsplashPhoto else { throw Error.loadThumbnailFailed }
		guard let url = photo.urls["thumb"] else { throw Error.loadThumbnailFailed }
		
		let (data,_) = try await URLSession.shared.data(with:url)
		guard let source = CGImageSourceCreateWithData(data as CFData,nil) else { throw Error.loadThumbnailFailed }
		guard let image = CGImageSourceCreateImageAtIndex(source,0,nil) else { throw Error.loadThumbnailFailed }
		
		return image
	}


//----------------------------------------------------------------------------------------------------------------------


	/// Loads the metadata dictionary for the specified local file URL
	
	open class func loadMetadata(for identifier:String, data:Any) async throws -> [String:Any]
	{
		guard let photo = data as? UnsplashPhoto else { throw Error.loadMetadataFailed }

		var metadata:[String:Any] = [:]
		
		metadata["PixelWidth"] = photo.width
		metadata["PixelHeight"] = photo.height

		if let created_at = photo.created_at, let creationDate = DateFormatter().date(from:created_at)
		{
			metadata["creationDate"] = creationDate
		}
		
//		if let fileSize = url.fileSize
//		{
//			metadata["fileSize"] = fileSize
//		}
//
//		if let creationDate = url.creationDate
//		{
//			metadata["creationDate"] = creationDate
//		}
//
//		if let modificationDate = url.modificationDate
//		{
//			metadata["modificationDate"] = modificationDate
//		}
		
		return metadata
	}


//----------------------------------------------------------------------------------------------------------------------


	// Get the filename of the downloaded file
	
	override var localFileName:String
	{
//		do
//		{
//			guard let photo = data as? UnsplashPhoto else { throw Error.downloadFileFailed }
//			guard let url = photo.urls[.full] else { throw Error.downloadFileFailed }
//			return url.lastPathComponent
//		}
//		catch
//		{
			return "Unsplash Photo"
//		}
	}
	
	
	open class func downloadFile(for identifier:String, data:Any) async throws -> URL
	{
		guard let photo = data as? UnsplashPhoto else { throw Error.downloadFileFailed }
		guard let url = photo.urls["full"] else { throw Error.downloadFileFailed }
		
		// TODO
		
		
		return url
	}


}


//----------------------------------------------------------------------------------------------------------------------



