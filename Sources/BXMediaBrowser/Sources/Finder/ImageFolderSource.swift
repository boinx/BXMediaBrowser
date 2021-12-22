//
//  ImageFolderSource.swift
//  MediaBrowserTest
//  Created by Peter Baumgartner on 04.12.21.
//

//----------------------------------------------------------------------------------------------------------------------


import Foundation
import QuartzCore
import UniformTypeIdentifiers


//----------------------------------------------------------------------------------------------------------------------


open class ImageFolderSource : FolderSource
{

}


//----------------------------------------------------------------------------------------------------------------------


// MARK: -

open class ImageFolderContainer : FolderContainer
{
	override open class func createContainer(for url:URL) throws -> Container?
	{
		guard url.exists else { throw Container.Error.notFound }
		guard url.isDirectory else { throw Container.Error.notFound }
		return ImageFolderContainer(url:url)
	}


	override open class func createObject(for url:URL) throws -> Object?
	{
//		guard url.conforms(to:kUTTypeImage) else { return nil }

		let uti = url.uti ?? ""
		
		if #available(macOS 12,*)
		{
			guard let type = UTType(uti) else { return nil }
			guard type.conforms(to:.image) else { return nil }
		}
		else
		{
			guard UTTypeConformsTo(uti as CFString,kUTTypeImage) else { return nil }
		}
		
		let object = ImageFile(url:url)
		return object
	}
}


//----------------------------------------------------------------------------------------------------------------------


// MARK: -

open class ImageFile : AnyFile
{
	/// Creates a thumbnail image for the specified local file URL
	
	override open class func loadThumbnail(for identifier:String, info:Any) async throws -> CGImage
	{
		guard let url = info as? URL else { throw Error.loadThumbnailFailed }
		guard url.exists else { throw Error.loadThumbnailFailed }

		let options:[CFString:AnyObject] =
		[
			kCGImageSourceCreateThumbnailFromImageIfAbsent : kCFBooleanTrue,
			kCGImageSourceCreateThumbnailFromImageAlways : kCFBooleanFalse,
			kCGImageSourceThumbnailMaxPixelSize : NSNumber(value:256.0),
			kCGImageSourceCreateThumbnailWithTransform : kCFBooleanTrue
		]

		guard let source = CGImageSourceCreateWithURL(url as CFURL,nil) else { throw Error.loadThumbnailFailed }
		guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(source,0,options as CFDictionary) else { throw Error.loadThumbnailFailed }
		return thumbnail
	}


	/// Loads the metadata dictionary for the specified local file URL
	
	override open class func loadMetadata(for identifier:String, info:Any) async throws -> [String:Any]
	{
		guard let url = info as? URL else { throw Error.loadMetadataFailed }
		guard url.exists else { throw Error.loadMetadataFailed }
		
		var metadata = try await super.loadMetadata(for:identifier, info:info)
		
		if let source = CGImageSourceCreateWithURL(url as CFURL,nil),
		   let properties = CGImageSourceCopyPropertiesAtIndex(source,0,nil),
		   let dict = properties as? [String:Any]
		{
			for (key,value) in dict
			{
				metadata[key] = value
			}
		}
		
		return metadata
	}
}


//----------------------------------------------------------------------------------------------------------------------


