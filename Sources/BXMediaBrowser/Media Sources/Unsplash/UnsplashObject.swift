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
		let format = NSLocalizedString("%@ on Unsplash", tableName:"Unsplash", bundle:.BXMediaBrowser, comment:"Value String")
		let username = photo.user.name ?? photo.user.username
		let name = String(format:format, username)
		
		super.init(
			identifier: "Unsplash:Photo:\(photo.id)",
			name: name,
			data: photo,
			loadThumbnailHandler: Self.loadThumbnail,
			loadMetadataHandler: Self.loadMetadata,
			downloadFileHandler: Self.downloadFile)
	}

	override nonisolated open var mediaType:MediaType
	{
		return .image
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
		Unsplash.log.verbose {"\(Self.self).\(#function) \(identifier)"}

		guard let photo = data as? UnsplashPhoto else { throw Error.loadMetadataFailed }
		let format = NSLocalizedString("%@ on Unsplash", tableName:"Unsplash", bundle:.BXMediaBrowser, comment:"Value String")
		let username = photo.user.name ?? photo.user.username
		let copyright = String(format:format, username)
		
		var metadata:[String:Any] = [:]
		
		metadata[.widthKey] = photo.width
		metadata[.heightKey] = photo.height
		metadata[.descriptionKey] = photo.description
		metadata[.creationDateKey] = photo.created_at
		metadata[.authorsKey] = [username]
		metadata[.copyrightKey] = copyright
	
		if let url = photo.photoPageURL(for:nil)
		{
			metadata[.whereFromsKey] = [url.absoluteString]
		}
		
		if let url = photo.user.profileURL
		{
			metadata[.authorAddressesKey] = [url.absoluteString]
		}
		
		if let exif = photo.exif
		{
			metadata[.exifApertureKey] = exif.aperture
			metadata[.exifExposureTimeKey] = exif.exposure_time
			metadata[.exifFocalLengthKey] = exif.focal_length
			metadata[.exifISOSpeedKey] = exif.iso
		}
		
		return metadata
	}


	/// Transforms the metadata dictionary into an ordered list of human readable information (with optional click actions)
	
	@MainActor override open var localizedMetadata:[ObjectMetadataEntry]
    {
		guard let photo = data as? UnsplashPhoto else { return [] }
		let user = photo.user
		let exif = photo.exif
		let location = photo.location
		let metadata = self.metadata ?? [:]
		
		let openPhotoPage =
		{
			guard let url = photo.photoPageURL(for:Unsplash.shared.appName) else { return }
			url.open()
		}

		var array:[ObjectMetadataEntry] = []

		let sourceLabel = NSLocalizedString("Source", tableName:"Unsplash", bundle:.BXMediaBrowser, comment:"Label")
		array += ObjectMetadataEntry(label:sourceLabel, value:"Unsplash.com")

		let photoLabel = NSLocalizedString("Photo", tableName:"Unsplash", bundle:.BXMediaBrowser, comment:"Label")
		array += ObjectMetadataEntry(label:photoLabel, value:"\(photo.id)", action:openPhotoPage)

		let photographerLabel = NSLocalizedString("Photographer", tableName:"Unsplash", bundle:.BXMediaBrowser, comment:"Label")
		array += ObjectMetadataEntry(label:photographerLabel, value:user.displayName , action:user.openProfileURL)
		
		let imageSizeLabel = NSLocalizedString("Image Size", tableName:"Unsplash", bundle:.BXMediaBrowser, comment:"Label")
		array += ObjectMetadataEntry(label:imageSizeLabel, value:"\(photo.width) × \(photo.height) Pixels")
		
		if let date = photo.created_at?.date
		{
			let label = NSLocalizedString("Capture Date", tableName:"Unsplash", bundle:.BXMediaBrowser, comment:"Label")
			array += ObjectMetadataEntry(label:label, value:String(with:date))
		}
		else if let value = metadata[.creationDateKey] as? Date
		{
			let label = NSLocalizedString("Creation Date", tableName:"Unsplash", bundle:.BXMediaBrowser, comment:"Label")
			array += ObjectMetadataEntry(label:label, value:String(with:value))
		}

		if let exif = exif
		{
			let apertureLabel = NSLocalizedString("Aperture", tableName:"Unsplash", bundle:.BXMediaBrowser, comment:"Label")
			array += ObjectMetadataEntry(label:apertureLabel, value:"f\(exif.aperture.string())")
			
			let exposureTimeLabel = NSLocalizedString("Exposure Time", tableName:"Unsplash", bundle:.BXMediaBrowser, comment:"Label")
			array += ObjectMetadataEntry(label:exposureTimeLabel, value:"\(exif.exposure_time.string())s")
			
			let focalLengthLabel = NSLocalizedString("Focal Length", tableName:"Unsplash", bundle:.BXMediaBrowser, comment:"Label")
			array += ObjectMetadataEntry(label:focalLengthLabel, value:"\(exif.focal_length)mm")
		}
		
		if let location = location
		{
			let label = NSLocalizedString("Location", tableName:"Unsplash", bundle:.BXMediaBrowser, comment:"Label")

			if let city = location.city, let country = location.country
			{
				array += ObjectMetadataEntry(label:label, value:"\(city), \(country)")
			}
			else if let city = location.city
			{
				array += ObjectMetadataEntry(label:label, value:city)
			}
			else if let country = location.country
			{
				array += ObjectMetadataEntry(label:label, value:country)
			}
		}
		
		if let description = photo.description
		{
			let label = NSLocalizedString("Description", tableName:"Unsplash", bundle:.BXMediaBrowser, comment:"Label")
			array += ObjectMetadataEntry(label:label, value:description.trimmingCharacters(in:.whitespacesAndNewlines))
		}
		
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
		String.imageUTI
	}
	
	static func localFileName(for identifier:String, data:Any) -> String
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
		Unsplash.log.debug {"\(Self.self).\(#function) \(identifier)"}

		// Download the file
		
		let remoteURL = try remoteURL(for:identifier, data:data)
		let tmpURL = try await URLSession.shared.downloadFile(from:remoteURL)
		
		// Don't forget to increment download count statistics, or Unsplash won't let your accessKey go into production!
		
		try? await self.incrementDownloadCount(for:data)
		
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


	/// Returns the URL for QLPreviewPanel
	
	override public var previewItemURL:URL!
    {
		guard let photo = data as? UnsplashPhoto else { return nil }
		guard let remoteURL = photo.urls["regular"] else { return nil }
		return remoteURL
    }


	/// Sends a GET request to the download_location link

	class func incrementDownloadCount(for data:Any) async throws
	{
		guard let photo = data as? UnsplashPhoto else { throw Error.downloadFileFailed }
		guard let downloadLink = photo.links.download_location else { throw Error.downloadFileFailed }
		guard let url = URL(string:downloadLink) else { throw Error.downloadFileFailed }
		
		// Build a request with the provided link
		
		let accessKey = Unsplash.shared.accessKey
		let authorization = "Client-ID \(accessKey)"
		var request = URLRequest(url:url)
		request.httpMethod = "GET"
		request.setValue(authorization, forHTTPHeaderField:"Authorization")
		
		// Send the GET request - this increments the download counter for this photo on the Unsplash server
		
		let _ = try await URLSession.shared.data(with:request)
	}
}


//----------------------------------------------------------------------------------------------------------------------
