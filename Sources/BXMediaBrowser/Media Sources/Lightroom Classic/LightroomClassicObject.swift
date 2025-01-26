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


#if canImport(iMedia) && os(macOS)

import iMedia
import BXSwiftUtils
import BXSwiftUI
import CoreGraphics
import Foundation
import QuickLookUI


//----------------------------------------------------------------------------------------------------------------------


open class LightroomClassicObject : Object, AppLifecycleMixin
{
	struct LRCData
	{
		let imbObject:IMBLightroomObject
		let mediaType:Object.MediaType
		let parserMessenger:IMBLightroomParserMessenger
	}

	/// Notification subscribers
	
	public var observers:[Any] = []
	

//----------------------------------------------------------------------------------------------------------------------


	/// Creates a new Object for the file at the specified URL

	public required init(with imbObject:IMBLightroomObject, mediaType:Object.MediaType, parserMessenger:IMBLightroomParserMessenger, in library:Library?)
	{
		super.init(
			library: library,
			identifier: Self.identifier(for:imbObject),
			name: imbObject.name,
			data: LRCData(imbObject:imbObject, mediaType:mediaType, parserMessenger:parserMessenger),
			loadThumbnailHandler: Self.loadThumbnail,
			loadMetadataHandler: Self.loadMetadata,
			downloadFileHandler: Self.downloadFile)
	}

	static func identifier(for imbObject:IMBLightroomObject) -> String
	{
		imbObject.persistentResourceIdentifier
	}


//----------------------------------------------------------------------------------------------------------------------


	/// Downloads the thumbnail image for the specified Lightroom asset

	open class func loadThumbnail(for identifier:String, data:Any) async throws -> CGImage
	{
		try await Tasks.canContinue()
		
		guard let data = data as? LRCData else { throw Error.loadThumbnailFailed }
		let parserMessenger = data.parserMessenger
		let imbObject = data.imbObject
		
		let object = try parserMessenger.loadThumbnail(for:imbObject)
		guard let image = object.imageRepresentation() as? AnyObject else { throw Error.loadThumbnailFailed }
		
		if CFGetTypeID(image) == CGImage.typeID
		{
			return image as! CGImage
		}

		throw Error.loadThumbnailFailed
	}


//----------------------------------------------------------------------------------------------------------------------


	open class func loadMetadata(for identifier:String, data:Any) async throws -> [String:Any]
	{
		try await Tasks.canContinue()
		
		// Load metadata from IMBObject via iMedia framework
		
		guard let data = data as? LRCData else { throw Error.loadThumbnailFailed }
		let parserMessenger = data.parserMessenger
		let imbObject = data.imbObject

		let object = try parserMessenger.loadMetadata(for:imbObject)
		guard var metadata = object.metadata as? [String:Any] else { throw Error.loadMetadataFailed }

		// Copy some existing key/value pairs to standard keys that are expected by BXMediaBrowser
		
		if let w = metadata["width"] as? NSNumber
		{
			metadata[.widthKey] = w.intValue
		}

		if let h = metadata["height"] as? NSNumber
		{
			metadata[.heightKey] = h.intValue
		}

		if let name = metadata["name"] as? String
		{
			metadata[.titleKey] = name
		}

		if let str1 = metadata["dateTime"] as? String
		{
			metadata[.captureDateKey] = str1.date
		}

		if let duration = metadata["duration"] as? Double
		{
			metadata[.durationKey] = duration
		}

		return metadata
	}

	// Convert metadata to ordered human-readable form that is ssuitable for display in the UI
	
	@MainActor override open var localizedMetadata:[ObjectMetadataEntry]
    {
		guard let data = data as? LRCData else { return [] }
		let mediaType = data.mediaType
		let dict = self.metadata ?? [:]
		var action:(()->Void)? = nil
		var array:[ObjectMetadataEntry] = []
		
		if let path = dict["MasterPath"] as? String
		{
			let url = URL(fileURLWithPath:path)
			action = { url.reveal() }
		}
		
		let label = NSLocalizedString("Metadata.label.file", bundle:.BXMediaBrowser, comment:"Metadata Label")
		array += ObjectMetadataEntry(label:label, value:self.name, action:action)
		
		if let w = dict[.widthKey] as? Int, let h = dict[.heightKey] as? Int
		{
			let label = mediaType == .image ?
				NSLocalizedString("Metadata.label.imageSize", bundle:.BXMediaBrowser, comment:"Metadata Label") :
				NSLocalizedString("Metadata.label.videoSize", bundle:.BXMediaBrowser, comment:"Metadata Label")
				
			array += ObjectMetadataEntry(label:label, value:"\(w) × \(h) Pixels")
		}

		if let value = dict[.durationKey] as? Double
		{
			let label = NSLocalizedString("Metadata.label.duration", bundle:.BXMediaBrowser, comment:"Metadata Label")
			array += ObjectMetadataEntry(label:label, value:value.shortTimecodeString())
		}
		
		if let value = dict[.captureDateKey] as? Date
		{
			let label = NSLocalizedString("Metadata.label.captureDate", bundle:.BXMediaBrowser, comment:"Metadata Label")
			array += ObjectMetadataEntry(label:label, value:String(with:value))
		}
		else if let value = dict[.creationDateKey] as? Date
		{
			let label = NSLocalizedString("Metadata.label.creationDate", bundle:.BXMediaBrowser, comment:"Metadata Label")
			array += ObjectMetadataEntry(label:label, value:String(with:value))
		}

		return array
    }
    
    
//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Downloading
	
	
	// Returns the filename of the file that will be downloaded

	override public var localFileName:String
	{
		let filename = "\(identifier).jpg"
		guard let data = data as? LRCData else { return filename }
		return data.imbObject.location.lastPathComponent
	}

	// LightroomClassic always returns JPEG files

	override public var localFileUTI:String
	{
		kUTTypeJPEG as String
	}

	// To be overridden in subclasses

	open class func downloadFile(for identifier:String, data:Any) async throws -> URL
	{
		LightroomClassic.log.debug {"\(Self.self).\(#function)"}
		guard let data = data as? LRCData else { throw Error.downloadFileFailed }
		let imbObject = data.imbObject

		do
		{
			guard let url = Self.previewItemURL(for:data) else { throw Error.downloadFileFailed }
			
			if LightroomClassic.shared.showPreviewSizeWarning
			{
				LightroomClassic.shared.showPreviewSizeWarningAlert(for:imbObject, with:url)
			}
			
			return url
		}
		catch
		{
			LightroomClassic.log.error {"\(Self.self).\(#function) ERROR \(error)"}
			throw error
		}
	}
	
	
//----------------------------------------------------------------------------------------------------------------------


	// MARK: - QuickLook
	

	/// Returns the filename for the QuickLook panel
	
	public var previewFilename:String
    {
		self.localFileName
	}
	
	/// Returns the title for the QuickLook panel
	
	override open var previewItemTitle: String!
    {
		self.localFileName
    }
	
	/// Returns the URL for the QuickLook panel
	
	override public var previewItemURL:URL!
    {
		if let url = self._previewItemURL
		{
			return url
		}
		
		self._previewItemURL = Self.previewItemURL(for:data)
		return _previewItemURL
	}
	
	private var _previewItemURL:URL? = nil
	
	/// Returns the local file URL to the preview file. This creates a temp JPEG file from the pyramid data.
	/// The resolution of the JPEG file depends on the catalog settings inside Lightroom Classic
	
	class func previewItemURL(for data:Any) -> URL?
    {
		guard let data = data as? LRCData else { return nil }
		let parserMessenger = data.parserMessenger
		let imbObject = data.imbObject
		
		var isStale = false
		guard let bookmark = try? parserMessenger.bookmark(for:imbObject) else { return nil }
		guard let url = try? URL(resolvingBookmarkData:bookmark, options:[], relativeTo:nil, bookmarkDataIsStale:&isStale) else { return nil }

		return url
	}
}


//----------------------------------------------------------------------------------------------------------------------


#endif
