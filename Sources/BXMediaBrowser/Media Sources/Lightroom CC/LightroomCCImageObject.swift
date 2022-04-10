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


//----------------------------------------------------------------------------------------------------------------------


open class LightroomCCImageObject : LightroomCCObject
{
	override nonisolated public var mediaType:MediaType
	{
		return .image
	}


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Metadata
	
	/// Loads the metadata dictionary for the specified local file URL

	override open class func loadMetadata(for identifier:String, data:Any) async throws -> [String:Any]
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
		
		let exposureTime = asset.payload?.xmp?.exif?.ExposureTime
		let aperture = asset.payload?.xmp?.exif?.ApertureValue
		
		if exposureTime != nil || aperture != nil
		{
			var string = ""
			
			if let aperture = aperture
			{
				let f = ceil(Double(aperture[0]) / Double(aperture[1]) * 10) / 10
				string += "f\(f)"
			}
			
			if let exposureTime = exposureTime
			{
				let t = Double(exposureTime[0]) / Double(exposureTime[1])
				let str = Formatter.exposureTimeFormatter.string(for:t) ?? "\(t)s"
				if !string.isEmpty { string += " @ " }
				string += str
			}
			
			let label = NSLocalizedString("Exposure", tableName:"LightroomCC", bundle:.BXMediaBrowser, comment:"Label")
			array += ObjectMetadataEntry(label:label, value:string)
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


	// MARK: - Download
	
	// Returns the filename of the file that will be downloaded

	override public var localFileName:String
	{
		Self.localFileName(for:identifier, data:data)
	}

	override class func localFileName(for identifier:String, data:Any) -> String
	{
		"\(identifier).jpg"
	}

	// LightroomCC always returns JPEG files

	override public var localFileUTI:String
	{
		kUTTypeJPEG as String
	}

	/// Starts downloading an image file

	override open class func downloadFile(for identifier:String, data:Any) async throws -> URL
	{
		LightroomCC.log.debug {"\(Self.self).\(#function) \(identifier)"}

		guard let asset = data as? LightroomCC.Asset else { throw Error.downloadFileFailed }
		
		let catalogID = LightroomCC.shared.catalogID
		let assetID = asset.id
		
		// Show indeterminate progress
		
		Self.showProgress()
		
		// Request the server side generation of the fullsize file

		let generateAPI = "https://lr.adobe.io/v2/catalogs/\(catalogID)/assets/\(assetID)/renditions"
		var generateRequest = try LightroomCC.shared.request(for:generateAPI, httpMethod:"POST")
		generateRequest.setValue("fullsize", forHTTPHeaderField:"X-Generate-Renditions")
		_ = try await URLSession.shared.data(with:generateRequest)
		
		// Poll until the fullsize image is available for downloading

		var shouldRetry = true
		var retryCount = 0
		var isAvailable = false
		var delay:UInt64 = 1_000_000_000
		let downloadAPI = "https://lr.adobe.io/v2/catalogs/\(catalogID)/assets/\(assetID)/renditions/fullsize"
		
		while shouldRetry
		{
			do
			{
				try? await Task.sleep(nanoseconds:delay)
				let pollRequest = try LightroomCC.shared.request(for:downloadAPI, httpMethod:"HEAD")
				_ = try await URLSession.shared.data(with:pollRequest)
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


	// MARK: - QuickLook
	
	override public var previewAccessPoint:String
	{
		guard let asset = data as? LightroomCC.Asset else { return "" }
		let catalogID = LightroomCC.shared.catalogID
		let assetID = asset.id
		return "https://lr.adobe.io/v2/catalogs/\(catalogID)/assets/\(assetID)/renditions/1280"
	}
}


//----------------------------------------------------------------------------------------------------------------------
