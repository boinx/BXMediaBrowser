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


public struct Config
{
	public struct RemoteFile
	{
		/// Determines whether remote files should be displayed in the media browser
		
		public static var isVisible = true
		
		/// Determines whether remote files should be enabled (usable) in the media browser
		
		public static var isEnabled = true
	}

	public struct DRMProtectedFile
	{
		/// Determines whether DRM protected files should be displayed in the media browser
		
		public static var isVisible = true
		
		/// Determines whether DRM protected files should be enabled (usable) in the media browser
		
		public static var isEnabled = false
		
		/// This warning message will be displayed for DRM protected files if they are not enabled
		
		public static var warningMessage = NSLocalizedString("DRM.warning", bundle:.BXMediaBrowser, comment:"Warning Message")
	}

	public struct CorruptedAppleLoops
	{
		/// Determines whether incomplete Apple Loops files should be displayed in the media browser
		
		public static var isVisible = true
		
		/// Determines whether incomplete Apple Loops files should be enabled (usable) in the media browser
		
		public static var isEnabled = false
		
		/// This warning message will be displayed for incomplete Apple Loops files if they are not enabled
		
		public static var warningMessage = NSLocalizedString("AppleLoops.warning", bundle:.BXMediaBrowser, comment:"Warning Message")
	}
}


//----------------------------------------------------------------------------------------------------------------------
