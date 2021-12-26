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


import Foundation
import QuartzCore
import UniformTypeIdentifiers


//----------------------------------------------------------------------------------------------------------------------


open class AudioFolderSource : FolderSource
{

}


//----------------------------------------------------------------------------------------------------------------------


// MARK: -

open class AudioFolderContainer : FolderContainer
{
	override open class func createObject(for url:URL) throws -> Object?
	{
		guard url.exists else { throw Object.Error.notFound }
		guard url.isAudioFile else { return nil }
		return AudioFile(url:url)
	}
}


//----------------------------------------------------------------------------------------------------------------------


open class AudioFile : FolderObject
{
	/// Loads the metadata dictionary for the specified local file URL
	
	override open class func loadMetadata(for identifier:String, info:Any) async throws -> [String:Any]
	{
		guard let url = info as? URL else { throw Error.loadMetadataFailed }
		guard url.exists else { throw Error.loadMetadataFailed }
		
		var metadata = try await super.loadMetadata(for:identifier, info:info)
		
//		if let source = CGImageSourceCreateWithURL(url as CFURL,nil),
//		   let properties = CGImageSourceCopyPropertiesAtIndex(source,0,nil),
//		   let dict = properties as? [String:Any]
//		{
//			for (key,value) in dict
//			{
//				metadata[key] = value
//			}
//		}
		
		return metadata
	}
}


//----------------------------------------------------------------------------------------------------------------------


