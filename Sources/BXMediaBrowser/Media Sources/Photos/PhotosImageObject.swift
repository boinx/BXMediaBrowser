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
import BXSwiftUtils


//----------------------------------------------------------------------------------------------------------------------


public class PhotosImageObject : PhotosObject
{
	override nonisolated public var mediaType:MediaType
	{
		return .image
	}


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Metadata
	
	/// Transforms the metadata dictionary into an ordered list of human readable information (with optional click actions)

	@MainActor override open var localizedMetadata:[ObjectMetadataEntry]
    {
		guard let asset = data as? PHAsset else { return [] }

		var array:[ObjectMetadataEntry] = []

		if let name = asset.originalFilename
		{
			let photoLabel = NSLocalizedString("File", tableName:"Photos", bundle:.BXMediaBrowser, comment:"Label")
			array += ObjectMetadataEntry(label:photoLabel, value:name)
		}
		
		let imageSizeLabel = NSLocalizedString("Image Size", tableName:"Photos", bundle:.BXMediaBrowser, comment:"Label")
		array += ObjectMetadataEntry(label:imageSizeLabel, value:"\(asset.pixelWidth) × \(asset.pixelHeight) Pixels")
		
//		let fileSizeLabel = NSLocalizedString("File Size", tableName:"Photos", bundle:.BXMediaBrowser, comment:"Label")
//		array += ObjectMetadataEntry(label:fileSizeLabel, value:asset.fileSize.fileSizeDescription)

		if let date = asset.creationDate
		{
			let creationDateLabel = NSLocalizedString("Creation Date", tableName:"Photos", bundle:.BXMediaBrowser, comment:"Label")
			array += ObjectMetadataEntry(label:creationDateLabel, value:String(with:date) )
		}

		return array
    }
    

//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Download
	
	/// Returns the UTI of the promised local file
	
	override public var localFileUTI:String
	{
		guard let asset = data as? PHAsset else { return String.imageUTI }
		return asset.uti
	}


	/// Returns the filename of the local file. This is a surprisingly expensive operation, so use sparingly.
	
	override public var localFileName:String
	{
		if let asset = data as? PHAsset, let filename = asset.originalFilename
		{
			return filename
		}

		return "Image.jpg"
	}
	
	
	// Request the URL of an Object. Apple really doesn't want us to work with URLs of PHAssets, so we have to resort
	// to various tricks. In case of an image we'll pretend to want edit an image file in-place to get the URL. In the
	// case of a video, we'll pretend we want to play an AVURLAsset with an AVPlayer.
	// Taken from https://stackoverflow.com/questions/38183613/how-to-get-url-for-a-phasset
	
	override class func downloadFile(for identifier:String, data:Any) async throws -> URL
	{
		Photos.log.verbose {"\(Self.self).\(#function) \(identifier)"}

		guard let asset = data as? PHAsset else { throw Object.Error.downloadFileFailed }
		
		var isCancelled = false
		let progress = Progress(parent:nil)
		progress.totalUnitCount = 100
		progress.completedUnitCount = 0
		Progress.globalParent?.addChild(progress, withPendingUnitCount:1)

        #if os(macOS)
		DraggingProgress.message = NSLocalizedString("Downloading", bundle:.BXMediaBrowser, comment:"Progress Message")
        #endif
        
		let options = PHContentEditingInputRequestOptions()
		options.isNetworkAccessAllowed = true
		options.progressHandler =
		{
			fraction,outStop in
			progress.completedUnitCount = Int64(fraction*100.0)
			if progress.isCancelled
			{
				outStop.pointee = true
				isCancelled = true
			}
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
					let error = isCancelled ? Object.Error.downloadFileCancelled : Object.Error.downloadFileFailed
					continuation.resume(throwing:error)
				}
			}
		}
	}
	
}


//----------------------------------------------------------------------------------------------------------------------


