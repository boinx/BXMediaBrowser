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


open class LightroomCCVideoObject : LightroomCCObject
{
	override nonisolated public var mediaType:MediaType
	{
		return .video
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
		
		if let value = asset.payload?.video?.duration
		{
			metadata[.durationKey] = Double(value[0]) / Double(value[1])
		}
		
		if let value = asset.payload?.video?.frameRate
		{
			metadata[.fpsKey] = Double(value[0]) / Double(value[1])
		}
		
		if let value = asset.payload?.video?.videoCodec
		{
			metadata[.videoCodecKey] = value
		}
		
		if let value = asset.payload?.video?.audioCodec
		{
			metadata[.audioCodecKey] = value
		}
		
		if let value = asset.payload?.captureDate
		{
			metadata[.exifCaptureDateKey] = value
		}
		
		if let value = asset.payload?.xmp?.tiff?.Model
		{
			metadata[.modelKey] = value
		}

		return metadata
	}


	/// Transforms the metadata dictionary into an ordered list of human readable information (with optional click actions)

	@MainActor override open var localizedMetadata:[ObjectMetadataEntry]
    {
		guard let asset = data as? LightroomCC.Asset else { return [] }
		guard let metadata = self.metadata else { return [] }
		
		var array:[ObjectMetadataEntry] = []

		let photoLabel = NSLocalizedString("File", tableName:"LightroomCC", bundle:.BXMediaBrowser, comment:"Label")
		array += ObjectMetadataEntry(label:photoLabel, value:asset.name)

		if let w = metadata[.widthKey] as? Int, let h = metadata[.heightKey] as? Int
		{
			let label = NSLocalizedString("Video Size", tableName:"LightroomCC", bundle:.BXMediaBrowser, comment:"Label")
			var str = "\(w) × \(h) Pixels"
			if let ratio = asset.payload?.video?.displayAspectRatio { str += " (\(ratio[0]):\(ratio[1]))" }
			array += ObjectMetadataEntry(label:label, value:str)
		}
		
		if let value = metadata[.durationKey] as? Double
		{
			let label = NSLocalizedString("Duration", tableName:"LightroomCC", bundle:.BXMediaBrowser, comment:"Label")
			array += ObjectMetadataEntry(label:label, value:value.shortTimecodeString())
		}
		
		if let value = metadata[.fpsKey] as? Double
		{
			let label = NSLocalizedString("Framerate", tableName:"LightroomCC", bundle:.BXMediaBrowser, comment:"Label")
			array += ObjectMetadataEntry(label:label, value:"\(value.string(for:"#.##",digits:2)) fps")
		}
		
		let fileSizeLabel = NSLocalizedString("File Size", tableName:"LightroomCC", bundle:.BXMediaBrowser, comment:"Label")
		array += ObjectMetadataEntry(label:fileSizeLabel, value:asset.fileSize.fileSizeDescription)
		
		if let value = asset.payload?.xmp?.tiff?.Model
		{
			var str = value
			if let make = asset.payload?.xmp?.tiff?.Make, !str.hasPrefix(make) { str = make + " " + str }
			let label = NSLocalizedString("Camera", tableName:"LightroomCC", bundle:.BXMediaBrowser, comment:"Label")
			array += ObjectMetadataEntry(label:label, value:str)
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
		var filename = "\(identifier).mov"
		
		if let asset = data as? LightroomCC.Asset, let name = asset.payload?.importSource.fileName
		{
			filename = name
		}
		
		return filename
	}


	// LightroomCC always returns JPEG files

	override public var localFileUTI:String
	{
		kUTTypeMovie as String
	}

	/// Starts downloading an image file

	override open class func downloadFile(for identifier:String, data:Any) async throws -> URL
	{
		LightroomCC.log.debug {"\(Self.self).\(#function) \(identifier)"}

		guard let asset = data as? LightroomCC.Asset else { throw Error.downloadFileFailed }
		
		let catalogID = LightroomCC.shared.catalogID
		let assetID = asset.id
		let downloadAPI = "https://lr.adobe.io/v2/catalogs/\(catalogID)/assets/\(assetID)/renditions/720p"

		// Show indeterminate progress
		
//		if !BXProgressWindowController.shared.isVisible
//		{
//			BXProgressWindowController.shared.isIndeterminate = true
//			BXProgressWindowController.shared.show()
//		}
		
		// Download the fullsize image file

		let downloadRequest = try LightroomCC.shared.request(for:downloadAPI, httpMethod:"GET")
		let tmpURL = try await URLSession.shared.downloadFile(with:downloadRequest)

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


	// MARK: - QuickLook
	
	override public var previewAccessPoint:String
	{
		guard let asset = data as? LightroomCC.Asset else { return "" }
		let catalogID = LightroomCC.shared.catalogID
		let assetID = asset.id
		return "https://lr.adobe.io/v2/catalogs/\(catalogID)/assets/\(assetID)/renditions/720p"
	}
}


//----------------------------------------------------------------------------------------------------------------------
