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


import SwiftUI

//----------------------------------------------------------------------------------------------------------------------


extension Library
{
	open class UIState : ObservableObject
	{
		/// This scale affects the display size of Object cells in a CollectionView
		
		@Published public var thumbnailScale:Double = 0.25
	}
	
	/// Returns the localized name for the Images Library
	
	public static var localizedNameImages:String
	{
		NSLocalizedString("Images", tableName:"Library", bundle:.module, comment:"Library Name")
	}
	
	/// Returns the localized name for the Videos Library
	
	public static var localizedNameVideos:String
	{
		NSLocalizedString("Videos", tableName:"Library", bundle:.module, comment:"Library Name")
	}
	
	/// Returns the localized name for the Audio Library
	
	public static var localizedNameAudio:String
	{
		NSLocalizedString("Audio", tableName:"Library", bundle:.module, comment:"Library Name")
	}
}


//----------------------------------------------------------------------------------------------------------------------
