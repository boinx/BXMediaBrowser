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
import QuickLookUI
import Foundation
import ImageIO

#if os(macOS)
import AppKit
#else
import UIKit
#endif


//----------------------------------------------------------------------------------------------------------------------


open class LightroomCCObject : Object
{
	/// Creates a new Object for the file at the specified URL

	public required init(with asset:LightroomCC.Asset)
	{
		super.init(
			identifier: "LightroomCC:Asset:\(asset.id)",
			name: asset.name,
			data: asset,
			loadThumbnailHandler: Self.loadThumbnail,
			loadMetadataHandler: Self.loadMetadata,
			downloadFileHandler: Self.downloadFile)
		
		// If we received a rating from Lightroom, then store it in our database
		
		if let rating = asset.rating, rating > StatisticsController.shared.rating(for:self)
		{
			StatisticsController.shared.setRating(rating, for:self)
		}
	}

	override nonisolated public var mediaType:MediaType
	{
		return .image
	}


//----------------------------------------------------------------------------------------------------------------------


	/// Downloads the thumbnail image for the specified Lightroom asset

	open class func loadThumbnail(for identifier:String, data:Any) async throws -> CGImage
	{
		guard let asset = data as? LightroomCC.Asset else { throw Error.loadThumbnailFailed }

		let catalogID = LightroomCC.shared.catalogID
		let assetID = asset.id
		let image = try await LightroomCC.shared.image(from:"https://lr.adobe.io/v2/catalogs/\(catalogID)/assets/\(assetID)/renditions/thumbnail2x")

		return image
	}


//----------------------------------------------------------------------------------------------------------------------


	/// Loads the metadata dictionary for the specified local file URL

	open class func loadMetadata(for identifier:String, data:Any) async throws -> [String:Any]
	{
		LightroomCC.log.verbose {"\(Self.self).\(#function) \(identifier)"}

		guard let asset = data as? LightroomCC.Asset else { throw Error.loadThumbnailFailed }

		var metadata:[String:Any] = [:]

		metadata[.titleKey] = asset.name
		metadata[.widthKey] = asset.width
		metadata[.heightKey] = asset.height
		metadata[.fileSizeKey] = asset.fileSize
		
		if let captureDate = asset.payload?.captureDate
		{
			metadata[.exifCaptureDateKey] = captureDate
		}
		
		if let aperture = asset.payload?.xmp?.exif?.FNumber
		{
			metadata[.exifApertureKey] = Double(aperture[0]) / Double(aperture[1])
		}
		
		if let exposureTime = asset.payload?.xmp?.exif?.ExposureTime
		{
			metadata[.exifExposureTimeKey] = Double(exposureTime[0]) / Double(exposureTime[1])
		}
		
		if let focalLength = asset.payload?.xmp?.exif?.FocalLengthIn35mmFilm
		{
			metadata[.exifFocalLengthKey] = focalLength
		}
		
		if let model = asset.payload?.xmp?.tiff?.Model
		{
			metadata[.modelKey] = model
		}

		return metadata
	}


	/// Transforms the metadata dictionary into an ordered list of human readable information (with optional click actions)

	@MainActor override open var localizedMetadata:[ObjectMetadataEntry]
    {
		guard let asset = data as? LightroomCC.Asset else { return [] }

		var array:[ObjectMetadataEntry] = []

		let photoLabel = NSLocalizedString("File", tableName:"LightroomCC", bundle:.BXMediaBrowser, comment:"Label")
		array += ObjectMetadataEntry(label:photoLabel, value:asset.name)

		let imageSizeLabel = NSLocalizedString("Image Size", tableName:"LightroomCC", bundle:.BXMediaBrowser, comment:"Label")
		array += ObjectMetadataEntry(label:imageSizeLabel, value:"\(asset.width) × \(asset.height) Pixels")
		
		let fileSizeLabel = NSLocalizedString("File Size", tableName:"LightroomCC", bundle:.BXMediaBrowser, comment:"Label")
		array += ObjectMetadataEntry(label:fileSizeLabel, value:asset.fileSize.fileSizeDescription)

		if let value = asset.payload?.xmp?.tiff?.Model
		{
			var str = value
			if let make = asset.payload?.xmp?.tiff?.Make, !str.hasPrefix(make) { str = make + " " + str }
			let label = NSLocalizedString("Camera", tableName:"LightroomCC", bundle:.BXMediaBrowser, comment:"Label")
			array += ObjectMetadataEntry(label:label, value:str)
		}
		
		if let value = asset.payload?.xmp?.exif?.ApertureValue
		{
			let aperture = ceil(Double(value[0]) / Double(value[1]) * 10) / 10
			let label = NSLocalizedString("Aperture", tableName:"LightroomCC", bundle:.BXMediaBrowser, comment:"Label")
			array += ObjectMetadataEntry(label:label, value:"f\(aperture)")
		}
		
		if let value = asset.payload?.xmp?.exif?.ExposureTime
		{
			let time = Double(value[0]) / Double(value[1])
			let str = Formatter.exposureTimeFormatter.string(for:time) ?? "\(time)s"
			let label = NSLocalizedString("Exposure Time", tableName:"LightroomCC", bundle:.BXMediaBrowser, comment:"Label")
			array += ObjectMetadataEntry(label:label, value:str)
		}
		
		if let value = asset.payload?.xmp?.exif?.FocalLengthIn35mmFilm
		{
			let mm = Int(value)
			let label = NSLocalizedString("Focal Length", tableName:"LightroomCC", bundle:.BXMediaBrowser, comment:"Label")
			array += ObjectMetadataEntry(label:label, value:"\(mm)mm")
		}

		return array
    }
    
    
//----------------------------------------------------------------------------------------------------------------------


	// Returns the filename of the file that will be downloaded

	override public var localFileName:String
	{
		Self.localFileName(for:identifier, data:data)
	}

	// LightroomCC always returns JPEG files

	override public var localFileUTI:String
	{
		kUTTypeJPEG as String
	}

	static func localFileName(for identifier:String, data:Any) -> String
	{
		"\(identifier).jpg"
	}


	/// Starts downloading an image file

	open class func downloadFile(for identifier:String, data:Any) async throws -> URL
	{
		LightroomCC.log.debug {"\(Self.self).\(#function) \(identifier)"}

		guard let asset = data as? LightroomCC.Asset else { throw Error.downloadFileFailed }
		
		let catalogID = LightroomCC.shared.catalogID
		let assetID = asset.id
		let generateAPI = "https://lr.adobe.io/v2/catalogs/\(catalogID)/assets/\(assetID)/renditions"
		let downloadAPI = "https://lr.adobe.io/v2/catalogs/\(catalogID)/assets/\(assetID)/renditions/fullsize"
		
		// Request the server side generatation of the fullsize file

		var generateRequest = try LightroomCC.shared.request(for:generateAPI, httpMethod:"POST")
		generateRequest.setValue("fullsize", forHTTPHeaderField:"X-Generate-Renditions")
		
		// Poll until the fullsize image is available for downloading

		var shouldRetry = true
		var retryCount = 0
		var isAvailable = false
		var delay:UInt64 = 1_000_000_000
		
		while shouldRetry
		{
			do
			{
				try? await Task.sleep(nanoseconds:delay)
				try LightroomCC.shared.request(for:downloadAPI, httpMethod:"HEAD")
				shouldRetry = false
				isAvailable = true
			}
			catch
			{
				delay *= 2
				retryCount += 1
				if retryCount > 8 { shouldRetry = false }
			}
		}
		
		// Download the fullsize image file

		guard isAvailable else { throw Error.downloadFileFailed }
		let downloadRequest = try LightroomCC.shared.request(for:downloadAPI, httpMethod:"GET")
		let tmpURL = try await URLSession.shared.downloadFile(with:downloadRequest)

		// Rename the file

		let folderURL = tmpURL.deletingLastPathComponent()
		let filename = self.localFileName(for:identifier, data:data)
		let localURL = folderURL.appendingPathComponent(filename)
		try FileManager.default.moveItem(at:tmpURL, to:localURL)

		// Register in TempFilePool

		TempFilePool.shared.register(localURL)
		return localURL
	}


//----------------------------------------------------------------------------------------------------------------------


	/// QuickLook support
	
	private var _previewItemURL:URL? = nil
	
	override public var previewItemURL:URL!
    {
		if self._previewItemURL == nil, let asset = data as? LightroomCC.Asset
		{
			Task
			{
				// Download the 1280 version of the image
				
				let catalogID = LightroomCC.shared.catalogID
				let assetID = asset.id
				let downloadAPI = "https://lr.adobe.io/v2/catalogs/\(catalogID)/assets/\(assetID)/renditions/1280"
				let request = try LightroomCC.shared.request(for:downloadAPI, httpMethod:"GET")
				let tmpURL = try await URLSession.shared.downloadFile(with:request)
				
				// Rename the file
				
				let folderURL = tmpURL.deletingLastPathComponent()
				let filename = Self.localFileName(for:identifier, data:data).replacingOccurrences(of:".jpg", with:".preview.jpg")
				let localURL = folderURL.appendingPathComponent(filename)
				try? FileManager.default.removeItem(at:localURL)
				try? FileManager.default.moveItem(at:tmpURL, to:localURL)
				
				// Store it in the TempFilePool and update the QLPreviewPanel
				
				await MainActor.run
				{
					TempFilePool.shared.register(localURL)
					self._previewItemURL = localURL
					QLPreviewPanel.shared().refreshCurrentPreviewItem()
					QLPreviewPanel.shared().reloadData()
				}
			}
 		}
 		
 		return self._previewItemURL
   }

	override open var previewItemTitle: String!
    {
		self.localFileName
    }
}


//----------------------------------------------------------------------------------------------------------------------
