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


import Photos


//----------------------------------------------------------------------------------------------------------------------


public class PhotosObject : Object
{
	private static var thumbnailOptions:PHImageRequestOptions =
	{
		let options = PHImageRequestOptions()
		options.isNetworkAccessAllowed = true
		options.isSynchronous = true
		options.resizeMode = .fast
		return options
	}()

	private static let thumbnailSize = CGSize(width:256, height:256)


//----------------------------------------------------------------------------------------------------------------------


	public init(with asset:PHAsset)
	{
		let identifier = "PhotosSource:\(asset.localIdentifier)"
		let name = asset.originalFilename ?? ""
		
		super.init(
			identifier: identifier,
			name: name,
			data: asset,
			loadThumbnailHandler: Self.loadThumbnail,
			loadMetadataHandler: Self.loadMetadata,
			downloadFileHandler: Self.downloadFile)
	}


//----------------------------------------------------------------------------------------------------------------------


	/// Creates a thumbnail image for the PHAsset with the specified identifier
	
	class func loadThumbnail(for identifier:String, data:Any) async throws -> CGImage
	{
		PhotosSource.log.verbose {"\(Self.self).\(#function) \(identifier)"}

        return try await withCheckedThrowingContinuation
        {
			continuation in

			guard let asset = data as? PHAsset else
			{
				return continuation.resume(throwing:Object.Error.notFound)
			}
		
			PhotosSource.imageManager.requestImage(for:asset, targetSize:self.thumbnailSize, contentMode:.aspectFit, options:Self.thumbnailOptions)
			{
				image,_ in
				
				if let image = image, let thumbnail = image.cgImage(forProposedRect:nil, context:nil, hints:nil)
				{
					continuation.resume(returning:thumbnail)
				}
				else
				{
					continuation.resume(throwing:Object.Error.loadThumbnailFailed)
				}
			}
		}
	}


//----------------------------------------------------------------------------------------------------------------------


	/// Loads the metadata dictionary for the specified local file URL
	
	class func loadMetadata(for identifier:String, data:Any) async throws -> [String:Any]
	{
		PhotosSource.log.verbose {"\(Self.self).\(#function) \(identifier)"}

		var metadata:[String:Any] = [:]
		
		guard let asset = data as? PHAsset else
		{
			throw Object.Error.loadMetadataFailed
		}
		
		metadata["PixelWidth"] = asset.pixelWidth
		metadata["PixelHeight"] = asset.pixelHeight
		metadata["duration"] = asset.duration
		metadata["mediaType"] = asset.mediaType.rawValue
		metadata["creationDate"] = asset.creationDate
		metadata["modificationDate"] = asset.modificationDate
	
		return metadata
	}


//					if let w = metadata["PixelWidth"] as? Int, let h = metadata["PixelHeight"] as? Int
//					{
//						Text("Size: \(w) x \(h) pixels")
//							.lineLimit(1)
//							.opacity(0.5)
//					}
//
//					if let model = metadata["ColorModel"] as? String
//					{
//						Text("Type: \(model)")
//							.lineLimit(1)
//							.opacity(0.5)
//					}
//					if let profile = metadata["ProfileName"] as? String
//					{
//						Text("Colorspace: \(profile)")
//							.lineLimit(1)
//							.opacity(0.5)
//					}


//----------------------------------------------------------------------------------------------------------------------


	/// Returns the UTI of the promised local file
	
	override public var localFileUTI:String
	{
		guard let asset = data as? PHAsset else { return String.imageUTI }
		return asset.uti
	}


	/// Returns the filename of the local file
	
	override public var localFileName:String
	{
		// Try to get the original filename from the PHAsset
		
		if let asset = data as? PHAsset, let filename = asset.originalFilename
		{
			return filename
		}
		
		// Otherwise return a default fallback filename, which could be wrong, since
		// the image might not be a JPEG file, but could be HEIF, TIFF, PNG, etc...
		
		return "Image.jpg"
	}
	
	
	// Request the URL of an Object. Apple really doesn't want us to work with URLs of PHAssets, so we have to resort
	// to various tricks. In case of an image we'll pretend to want edit an image file in-place to get the URL. In the
	// case of a video, we'll pretend we want to play an AVURLAsset with an AVPlayer.
	// Taken from https://stackoverflow.com/questions/38183613/how-to-get-url-for-a-phasset
	
	class func downloadFile(for identifier:String, data:Any) async throws -> URL
	{
		PhotosSource.log.verbose {"\(Self.self).\(#function) \(identifier)"}

		guard let asset = data as? PHAsset else { throw Object.Error.downloadFileFailed }
		
		if asset.mediaType == .image
		{
			return try await self.downloadImageFile(for:asset)
		}
		else
		{
			return try await self.downloadVideoFile(for:asset)
		}
	}
	
	
	// For image files request the full size image URL for "editing"

	class func downloadImageFile(for asset:PHAsset) async throws -> URL
	{
//		var continueDownloading = true

		let options = PHContentEditingInputRequestOptions()
		options.isNetworkAccessAllowed = true
		options.progressHandler =
		{
			progress,outStop in

//			continueDownloading = iOSMediaBrowser.downloadProgressHandler?(self,progress,nil) ?? true
//			if !continueDownloading { outStop.pointee = true }
		}

        return try await withCheckedThrowingContinuation
        {
			continuation in

			asset.requestContentEditingInput(with:options)
			{
				(input:PHContentEditingInput?,_) in
				
				if let url = input?.fullSizeImageURL
				{
					continuation.resume(returning:url)
				}
				else
				{
					continuation.resume(throwing:Object.Error.downloadFileFailed)
				}
			}
		}
	}
	
	
	// For video and audio request an AVURLAsset, which we can query for its URL

	class func downloadVideoFile(for asset:PHAsset) async throws -> URL
	{
//		var continueDownloading = true
	
		let options = PHVideoRequestOptions()
		options.version = .original
		options.isNetworkAccessAllowed = true
		options.progressHandler =
		{
			progress,error,outStop,_ in
//			continueDownloading = iOSMediaBrowser.downloadProgressHandler?(self,progress,error) ?? true
//			if !continueDownloading { outStop.pointee = true }
		}
			
        return try await withCheckedThrowingContinuation
        {
			continuation in

			PhotosSource.imageManager.requestAVAsset(forVideo:asset, options:options)
			{
				(avasset:AVAsset?,_,_) in

				if let urlAsset = avasset as? AVURLAsset
				{
					let url = urlAsset.url
					continuation.resume(returning:url)
				}
				else
				{
					continuation.resume(throwing:Object.Error.downloadFileFailed)
				}
			}
		}
	}
	
	
/*

	// Request the URL of an iOSMediaBrowserItem. Apple really doesn't want us to work with URLs of PHAssets,
	// so we have to resort to various tricks. In case of an image we'll pretend to want edit an image file in-place
	// to get the URL. In the case of a video, we'll pretend we want to play an AVURLAsset with an AVPlayer.
	// Taken from https://stackoverflow.com/questions/38183613/how-to-get-url-for-a-phasset
	
	public func requestMediaFileURL(type:iOSMediaBrowserItemURLType = .file,completionHandler:@escaping (URL?,iOSMediaBrowserError?)->())
	{
		var continueDownloading = true
		
		// For image files request the full size image URL for "editing"

		if self.asset.mediaType == .image
		{
			let options = PHContentEditingInputRequestOptions()
			options.isNetworkAccessAllowed = true
    		options.progressHandler =
    		{
    			progress,outStop in

				continueDownloading = iOSMediaBrowser.downloadProgressHandler?(self,progress,nil) ?? true
				if !continueDownloading { outStop.pointee = true }
     		}

			self.asset.requestContentEditingInput(with:options)
			{
				(input:PHContentEditingInput?,_) in
				
				if let url = input?.fullSizeImageURL
				{
					completionHandler(url,nil)
				}
				else
				{
					completionHandler(nil,.accessDenied)
 				}
			}
		}

		// For video and audio request an AVURLAsset, which we can query for its URL

		else
		{
			let options = PHVideoRequestOptions()
			options.version = .original
			options.isNetworkAccessAllowed = true
			options.progressHandler =
			{
				progress,error,outStop,_ in
				continueDownloading = iOSMediaBrowser.downloadProgressHandler?(self,progress,error) ?? true
				if !continueDownloading { outStop.pointee = true }
			}
			
			iOSMediaBrowserSourcePhotosApp.imageManager.requestAVAsset(forVideo:self.asset,options:options)
			{
				(avasset:AVAsset?,_,_) in

				if let urlAsset = avasset as? AVURLAsset
				{
					completionHandler(urlAsset.url,nil)
				}
				else
				{
					completionHandler(nil,.accessDenied)
				}
			}
		}
	}

*/
	
}


//----------------------------------------------------------------------------------------------------------------------


