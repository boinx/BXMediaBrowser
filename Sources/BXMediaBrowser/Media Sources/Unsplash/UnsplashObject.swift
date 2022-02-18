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
import AppKit


//----------------------------------------------------------------------------------------------------------------------


open class UnsplashObject : Object
{
	/// Creates a new Object for the file at the specified URL
	
	public init(with photo:UnsplashPhoto)
	{
		super.init(
			identifier: "UnsplashSource:Photo:\(photo.id)",
			name: photo.description ?? "",
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
		
		let data = try await URLSession.shared.data(with:url)
		guard let source = CGImageSourceCreateWithData(data as CFData,nil) else { throw Error.loadThumbnailFailed }
		guard let image = CGImageSourceCreateImageAtIndex(source,0,nil) else { throw Error.loadThumbnailFailed }
		
		return image
	}


//----------------------------------------------------------------------------------------------------------------------


	/// Loads the metadata dictionary for the specified local file URL
	
	open class func loadMetadata(for identifier:String, data:Any) async throws -> [String:Any]
	{
		UnsplashSource.log.verbose {"\(Self.self).\(#function) \(identifier)"}

		guard let photo = data as? UnsplashPhoto else { throw Error.loadMetadataFailed }

		var metadata:[String:Any] = [:]
		
		metadata["PixelWidth"] = photo.width
		metadata["PixelHeight"] = photo.height
		metadata["creationDate"] = photo.created_at
		metadata["created_at"] = photo.created_at
		metadata["description"] = photo.description
		metadata["location"] = photo.location
		metadata["urls"] = photo.urls
		metadata["public_domain"] = photo.public_domain
		metadata["user"] = photo.user
		
		return metadata
	}


	/// Tranforms the metadata dictionary into an order list of human readable information (with optional click actions)
	
	@MainActor override var localizedMetadata:[ObjectMetadataEntry]
    {
		guard let photo = data as? UnsplashPhoto else { return [] }
		let user = photo.user
		let links = photo.links
		let exif = photo.exif
		let location = photo.location
		let metadata = self.metadata ?? [:]
		
		let openPhotoPage =
		{
			guard let str = links.html else { return }
			guard let url = URL(string:str) else { return }
			url.open()
		}
		
		var array:[ObjectMetadataEntry] = []
		
		array += ObjectMetadataEntry(label:"Photo", value:"\(photo.id)", action:openPhotoPage)

		array += ObjectMetadataEntry(label:"Photographer", value:user.displayName, action:user.openProfileURL)
		
		array += ObjectMetadataEntry(label:"Image Size", value:"\(photo.width) × \(photo.height) Pixels")
		
		if let date = photo.created_at?.date
		{
			array += ObjectMetadataEntry(label:"Capture Date", value:String(with:date))
		}
		else if let value = metadata["creationDate"] as? Date
		{
			array += ObjectMetadataEntry(label:"Creation Date", value:String(with:value))
		}

		if let exif = exif
		{
			array += ObjectMetadataEntry(label:"Aperture", value:"f\(exif.aperture.string())")
			array += ObjectMetadataEntry(label:"Exposure Time", value:"\(exif.exposure_time.string())s")
			array += ObjectMetadataEntry(label:"Focal Length", value:"\(exif.focal_length)mm")
		}
		
		if let location = location
		{
			if let city = location.city, let country = location.country
			{
				array += ObjectMetadataEntry(label:"Location", value:"\(city), \(country)")
			}
			else if let city = location.city
			{
				array += ObjectMetadataEntry(label:"Location", value:city)
			}
			else if let country = location.country
			{
				array += ObjectMetadataEntry(label:"Location", value:country)
			}
		}
		
		if let description = photo.description
		{
			array += ObjectMetadataEntry(label:"Description", value:description.trimmingCharacters(in:.whitespacesAndNewlines))
		}
		
		return array
    }
    
    
//----------------------------------------------------------------------------------------------------------------------


	// Returns the filename of the file that will be downloaded
	
	override var localFileName:String
	{
		// Fallback filename
		
		var name = "UnsplashPhoto"
		var ext = "jpg"
		
		do
		{
			// Unfortunately the remote URL is not simple. To get the file extension, we need to parse the URL query
			
			let remoteURL = try Self.remoteURL(for:identifier, data:data)
			let components = URLComponents(url:remoteURL, resolvingAgainstBaseURL:false)
			let queryItems = components?.queryItems ?? []
			
			name = components?.path.replacingOccurrences(of:"/", with:"") ?? name
			
			for queryItem in queryItems
			{
				if queryItem.name == "fm", let value = queryItem.value
				{
					ext = value
					break
				}
			}
		}
		catch let error
		{
			logDataModel.error {"\(Self.self).\(#function) ERROR \(error)"}
		}
		
		return "\(name).\(ext)"
	}
	
	
	/// Return the remote URL for an Unsplash Photo
	
	class func remoteURL(for identifier:String, data:Any) throws -> URL
	{
		guard let photo = data as? UnsplashPhoto else { throw Error.downloadFileFailed }
		guard let remoteURL = photo.urls["full"] else { throw Error.downloadFileFailed }
		return remoteURL
	}
	
	
	/// Starts downloading an image file
	
	open class func downloadFile(for identifier:String, data:Any) async throws -> URL
	{
		UnsplashSource.log.debug {"\(Self.self).\(#function) \(identifier)"}

		let remoteURL = try remoteURL(for:identifier, data:data)
		let localURL = try await URLSession.shared.downloadFile(from:remoteURL)
		TempFilePool.shared.register(localURL)
		return localURL
	}


	/// Returns the URL for QLPreviewPanel
	
	override public var previewItemURL:URL!
    {
		guard let photo = data as? UnsplashPhoto else { return nil }
		guard let remoteURL = photo.urls["regular"] else { return nil }
		return remoteURL
    }
}


//----------------------------------------------------------------------------------------------------------------------



