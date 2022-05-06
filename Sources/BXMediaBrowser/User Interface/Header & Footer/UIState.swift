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
	/// Width of the sidebar in the media browser window
	
	@Published public var sidebarWidth:Double = 256
	{
		didSet { self.saveToPrefs() }
	}
	
	/// Height of the LibraryView in a single media browser view
	
	@Published public var libraryHeight:Double = 256
	{
		didSet { self.saveToPrefs() }
	}
	
	/// This scale affects the display size of Object cells in a CollectionView
	
	@Published public var thumbnailSize:Double
	{
		didSet { self.saveToPrefs() }
	}
	
	/// The prefix will be used to build prefs keys for property persistence
	
	public var prefsKeyPrefix:String
	
	private var thumbnailSizeKey:String { "\(prefsKeyPrefix)-thumbnailSize"}
	private var sidebarWidthKey:String { "\(prefsKeyPrefix)-sidebarWidth"}
	private var libraryHeightKey:String { "\(prefsKeyPrefix)-libraryHeight"}
	
	/// Internal housekeeping
	
	private var observers:[Any] = []
	private var shouldSaveToPrefs = false


//----------------------------------------------------------------------------------------------------------------------


	public init(prefsKeyPrefix:String = UUID().uuidString, thumbnailSize:Double = 120)
	{
		self.prefsKeyPrefix = prefsKeyPrefix
		self.thumbnailSize = thumbnailSize
		self.loadFromPrefs()
		
		#if os(macOS)
		
		self.observers += NotificationCenter.default.publisher(for:NSApplication.willTerminateNotification, object:nil).sink
		{
			[weak self] _ in self?.saveToPrefs()
		}
		
		#else
		#warning("TODO: implement")
		#endif
	}
	
	private func loadFromPrefs()
	{
		let size = UserDefaults.standard.double(forKey:thumbnailSizeKey)
		if size > 0.0 { self.thumbnailSize = size }

		let width = UserDefaults.standard.double(forKey:sidebarWidthKey)
		if width > 0.0 { self.sidebarWidth = width }

		let height = UserDefaults.standard.double(forKey:libraryHeightKey)
		if height > 0.0 { self.libraryHeight = height }
		
		self.shouldSaveToPrefs = true
	}
	
	private func saveToPrefs()
	{
		guard shouldSaveToPrefs else { return }
		
		DispatchQueue.main.coalesce(prefsKeyPrefix)
		{
			UserDefaults.standard.set(self.thumbnailSize, forKey:self.thumbnailSizeKey)
			UserDefaults.standard.set(self.sidebarWidth, forKey:self.sidebarWidthKey)
			UserDefaults.standard.set(self.libraryHeight, forKey:self.libraryHeightKey)
		}
	}
}


//----------------------------------------------------------------------------------------------------------------------
