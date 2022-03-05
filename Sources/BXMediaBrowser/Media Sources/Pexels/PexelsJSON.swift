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

//#if os(macOS)
//import AppKit
//#else
//import UIKit
//#endif


//----------------------------------------------------------------------------------------------------------------------


/// The JSON for a single photo on pexels.com

public struct PexelsPhoto : Codable
{
    public let id:Int
    public let height:Int
    public let width:Int
    public let url:String
    public let photographer:String
    public let photographer_url:String
    public let photographer_id:Int
    public let avg_color:String
    public let src:PexelsPhotoSrc
    public let alt:String
}

/// The JSON that contains the URLs to the different variants of a Pexels photo

public struct PexelsPhotoSrc : Codable
{
    public let original:String
    public let large2x:String
    public let large:String
    public let medium:String
    public let small:String
    public let portrait:String
    public let landscape:String
    public let tiny:String
}


//----------------------------------------------------------------------------------------------------------------------


/// The JSON for a single video on pexels.com

public struct PexelsVideo : Codable
{
    public let id:Int
    public let width:Int								// in pixels
    public let height:Int								// in pixels
    public let url:String								// URL to main page of the video
    public let image:String 							// URL to a posterframe
    public let duration:Int 							// in seconds
    public let user:PexelsUser							// Info about the author
    public let video_files:[PexelsVideoFile]			// The variants of this video
}

/// The JSON for a Pexels User

public struct PexelsUser : Codable
{
    public let id:Int
    public let name:String								// Name of the author
    public let url:String 								// URL to user profile page
}

/// The JSON for a single video file variant

public struct PexelsVideoFile : Codable
{
    public let id:Int
    public let quality:String
    public let file_type:String 						// mime type
    public let width:Int								// in pixels
    public let height:Int								// in pixels
    public let link:String 								// URL to file
}

/// The JSON for a video preview picture

public struct PexelsVideoPreview : Codable
{
    public let id:Int
    public let picture:String 							// URL to preview image
    public let nr:Int
}


//----------------------------------------------------------------------------------------------------------------------


/// The results JSON for a photo search on pexels.com

public struct PexelsPhotoSearchResults : Codable
{
	public let photos:[PexelsPhoto]
	public let page:Int
	public let per_page:Int
	public let total_results:Int
	public let prev_page:String?
	public let next_page:String?
}

/// The results JSON for a video search on pexels.com

public struct PexelsVideoSearchResults : Codable
{
	public let videos:[PexelsVideo]
	public let url:String
	public let page:Int
	public let per_page:Int
	public let total_results:Int
	public let prev_page:String?
	public let next_page:String?
}


//----------------------------------------------------------------------------------------------------------------------


