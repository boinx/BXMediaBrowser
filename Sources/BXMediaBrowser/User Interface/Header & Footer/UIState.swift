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
import SwiftUI

#if os(macOS)
import AppKit
#else
import UIKit
#endif


//----------------------------------------------------------------------------------------------------------------------


open class UIState : ObservableObject
{
	/// This scale affects the display size of Object cells in a CollectionView
	
	@Published public var thumbnailScale:Double = 0.25
	
	/// The prefix will be used to build prefs keys for property persistence
	
	private let prefsKeyPrefix:String
	private var thumbnailKey:String { "\(prefsKeyPrefix)-thumbnailScale"}
	
	/// Internal housekeeping
	
	private var observers:[Any] = []


//----------------------------------------------------------------------------------------------------------------------


	public init(prefsKeyPrefix:String)
	{
		self.prefsKeyPrefix = prefsKeyPrefix
		
		let scale = UserDefaults.standard.double(forKey:thumbnailKey)
		if scale > 0.0 { self.thumbnailScale = scale }
		
		#if os(macOS)
		
		self.observers += NotificationCenter.default.publisher(for:NSApplication.willTerminateNotification, object:nil).sink
		{
			[weak self] _ in
			guard let self = self else { return }
			UserDefaults.standard.set(self.thumbnailScale, forKey:self.thumbnailKey)
		}
		
		#else
		#warning("TODO: implement")
		#endif
	}
}


//----------------------------------------------------------------------------------------------------------------------
