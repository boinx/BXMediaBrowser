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
		
		super.init(
			identifier: identifier,
			name: "", 								// Photos framework does not offer names for PHAssets
			info: asset,
			loadThumbnailHandler: Self.loadThumbnail,
			loadMetadataHandler: Self.loadMetadata,
			downloadFileHandler: Self.downloadFile)
	}


//----------------------------------------------------------------------------------------------------------------------


	/// Creates a thumbnail image for the PHAsset with the specified identifier
	
	class func loadThumbnail(for identifier:String, info:Any) async throws -> CGImage
	{
        try await withCheckedThrowingContinuation
        {
			continuation in

			guard let asset = info as? PHAsset else
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
	
	class func loadMetadata(for identifier:String, info:Any) async throws -> [String:Any]
	{
		var metadata:[String:Any] = [:]
		
		guard let asset = info as? PHAsset else
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


	/// Since we are already dealing with a local media file, this function simply returns the specified file URL
	
	class func downloadFile(for identifier:String, info:Any) async throws -> URL
	{
		return URL(fileURLWithPath:"/")
	}
}


//----------------------------------------------------------------------------------------------------------------------


