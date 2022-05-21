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


#if os(macOS)
import AppKit
#else
import UIKit
#endif

import BXSwiftUtils


//----------------------------------------------------------------------------------------------------------------------


public protocol ScrollToBottomMixin : AnyObject
{
	/// Registers a handler that will be called when the CollectionView is scrolled to the bottom

	func registerScrollToBottomHandler(_ handler:@escaping ()->Void)
	
	/// This array must be provided to store the subscribers
	
	var observers:[Any] { set get }
}


//----------------------------------------------------------------------------------------------------------------------


public extension ScrollToBottomMixin
{
	func registerScrollToBottomHandler(_ handler:@escaping ()->Void)
	{
		#if os(macOS)
		
		self.observers += NotificationCenter.default.publisher(for:NSCollectionView.didScrollToEnd, object:self).sink
		{
			_ in handler()
		}
		
		#else
		
		self.observers += NotificationCenter.default.publisher(for:UICollectionView.didScrollToEnd, object:self).sink
		{
			_ in handler()
		}
		
		#endif
	}
}


//----------------------------------------------------------------------------------------------------------------------
