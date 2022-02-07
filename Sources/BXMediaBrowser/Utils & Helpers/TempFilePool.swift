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

#if os(macOS)
import AppKit
#else
import UIKit
#endif


//----------------------------------------------------------------------------------------------------------------------


public class TempFilePool
{
	/// Shared singleton instance
	
	public static let shared = TempFilePool()
	
	/// The list of temp files that should be deleted when the app terminates
	
    private var urls:[URL] = []
    
    /// This lock is used to ensure thread-safe access to the array of urls
	
    private var lock = NSRecursiveLock()
    
    /// Notification observers
	
    private var observers:[Any] = []
    

//----------------------------------------------------------------------------------------------------------------------


    /// Registers for the app willTerminate notification to trigger the temp file cleanup
	
    private init()
    {
		#if os(macOS)
		
		self.observers += NotificationCenter.default.publisher(for:NSApplication.willTerminateNotification, object:nil).sink
		{
			[weak self] _ in
			self?.cleanup()
		}
		
		#else
		
		self.observers += NotificationCenter.default.publisher(for:UIApplication.willTerminateNotification, object:nil).sink
		{
			[weak self] _ in
			self?.cleanup()
		}
		
		#endif
    }
    

	/// Removes all registered temp files
	
	public func cleanup()
	{
		lock.lock()
		
		for url in urls
		{
			try? FileManager.default.removeItem(at:url)
		}
		
		self.urls.removeAll()
		
		lock.unlock()
	}


//----------------------------------------------------------------------------------------------------------------------


    /// Registers the specified url as a temp file that should be deleted up when the app terminates
	
    public func register(_ url:URL)
	{
		lock.lock()
		self.urls += url
		lock.unlock()
	}
}


//----------------------------------------------------------------------------------------------------------------------
