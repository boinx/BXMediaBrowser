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
import QuartzCore
import UniformTypeIdentifiers


//----------------------------------------------------------------------------------------------------------------------


open class ImageFolderSource : FolderSource
{
	/// Creates a Container for the folder at the specified URL
	
	override open func createContainer(for url:URL) throws -> Container?
	{
		let container = ImageFolderContainer(url:url)
		{
			[weak self] in self?.removeContainer($0)
		}
		
		return container
	}
}


//----------------------------------------------------------------------------------------------------------------------


// MARK: -

open class ImageFolderContainer : FolderContainer
{
	override open class func createObject(for url:URL) throws -> Object?
	{
		guard url.exists else { throw Object.Error.notFound }
		guard url.isImageFile else { return nil }
		return ImageFile(url:url)
	}
}


//----------------------------------------------------------------------------------------------------------------------


// MARK: -

open class ImageFile : FolderObject
{
	/// Creates a thumbnail image for the specified local file URL
	
	override open class func loadThumbnail(for identifier:String, data:Any) async throws -> CGImage
	{
		FolderSource.log.verbose {"\(Self.self).\(#function) \(identifier)"}

		guard let url = data as? URL else { throw Error.loadThumbnailFailed }
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
	
	override open class func loadMetadata(for identifier:String, data:Any) async throws -> [String:Any]
	{
		FolderSource.log.verbose {"\(Self.self).\(#function) \(identifier)"}

		guard let url = data as? URL else { throw Error.loadMetadataFailed }
		guard url.exists else { throw Error.loadMetadataFailed }
		
		var metadata = try await super.loadMetadata(for:identifier, data:data)
		
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

	
	/// Returns the UTI of the promised image file 
	
	override var localFileUTI:String
	{
		return kUTTypeImage as String
	}
}


//----------------------------------------------------------------------------------------------------------------------


