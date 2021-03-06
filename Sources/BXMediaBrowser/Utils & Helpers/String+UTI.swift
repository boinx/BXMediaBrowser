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

#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif

#if canImport(MobileCoreServices)
import MobileCoreServices
#endif


//----------------------------------------------------------------------------------------------------------------------


public extension String
{
	static var fileUTI:String
	{
		if #available(macOS 11, iOS 14, *)
		{
			return UTType.fileURL.identifier
		}
		else
		{
			return kUTTypeFileURL as String
		}
	}

	static var imageUTI:String
	{
		if #available(macOS 11, iOS 14, *)
		{
			return UTType.image.identifier
		}
		else
		{
			return kUTTypeImage as String
		}
	}

	static var movieUTI:String
	{
		if #available(macOS 11, iOS 14, *)
		{
			return UTType.movie.identifier
		}
		else
		{
			return kUTTypeMovie as String
		}
	}

	static var audioUTI:String
	{
		if #available(macOS 11, iOS 14, *)
		{
			return UTType.audio.identifier
		}
		else
		{
			return kUTTypeAudio as String
		}
	}
}


//----------------------------------------------------------------------------------------------------------------------
