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
import UIKIt
#endif


//----------------------------------------------------------------------------------------------------------------------


public class StatisticsController : ObservableObject
{
	/// The shared singleton instance of this controller
	
	public static let shared = StatisticsController()
	
	/// Subscribers or KVO observers
	
	private var observers:[Any] = []
	
	/// This notification is sent (from the main thread) whenever a statistics value was changed.
	///
	/// The BXMediaBrowser.Object is stored in notification.object.
	
	public static let didChangeNotification = Notification.Name("BXMediaBrowser.StatisticsController.didChange")
	
	public static let ratingNotification = Notification.Name("BXMediaBrowser.StatisticsController.rating")
	
	
//----------------------------------------------------------------------------------------------------------------------


	private init()
	{
		// On startup load the previous statistics
		
		self.load()
		
		// When quitting save the current statistics
		
		#if os(macOS)
		
		self.observers += NotificationCenter.default.publisher(for:NSApplication.willTerminateNotification, object:nil).sink
		{
			[weak self] _ in self?.save()
		}
		
		#else

		#warning("TODO: implement")
		
		#endif
	}
	


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Use Count
	
	
	/// Increments the use count for the specified Object
	
	@discardableResult public func incrementUseCount(for object:Object) -> Int
	{
		let n = useCount(for:object) + 1
		self.setUseCount(n, for:object)
		return n
	}

	/// Decrements the use count for the specified Object
	
	@discardableResult public func decrementUseCount(for object:Object) -> Int
	{
		let n = useCount(for:object)

		if n > 0
		{
			self.setUseCount(n-1, for:object)
			return n-1
		}
		else
		{
			self._useCount[object.identifier] = nil
			return 0
		}
	}

	/// Sets the useCount for the specified Object
	
	public func setUseCount(_ useCount:Int, for object:Object)
	{
		self._useCount[object.identifier] = useCount
		NotificationCenter.default.post(name: Self.didChangeNotification, object:object)
	}

	/// Returns the use count for the specified Object
	
	public func useCount(for object:Object) -> Int
	{
		self._useCount[object.identifier] ?? 0
	}
	
	/// Storage for use count statistics
	
	private var _useCount:[String:Int] = [:]
	
	
//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Rating
	
	
	/// Sets the rating for the specified Object
	
	public func setRating(_ rating:Int, for object:Object, sendNotifications:Bool = true )
	{
		if rating > 0
		{
			self._rating[object.identifier] = rating
		}
		else
		{
			self._rating[object.identifier] = nil
		}
		
		if sendNotifications
		{
			NotificationCenter.default.post(name: Self.didChangeNotification, object:object)
			NotificationCenter.default.post(name: Self.ratingNotification, object:object)
		}
	}

	/// Returns the rating for the specified Object
	
	public func rating(for object:Object) -> Int
	{
		max(0, self.rating(for:object.identifier))
	}
	
	/// Returns the rating for the specified Object identifier
	
	public func rating(for identifier:String) -> Int
	{
		self._rating[identifier] ?? 0
	}
	
	/// Storage for rating statistics
	
	private var _rating:[String:Int] = [:]


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Load & Save
	
	
	/// Loads statistics from storage
	
	public func load()
	{
		self._useCount = self.loadUseCountHandler()
		self._rating = self.loadRatingHandler()
	}

	/// Saves statistics to storage
	
	public func save()
	{
		self.saveUseCountHandler(_useCount)
		self.saveRatingHandler(_rating)
	}
	
	/// An externally supplied handler that loads useCount statistics from storage.
	///
	/// The default implementation uses UserDefaults, but a client application can store
	/// this information elsewhere, e.g. in a document file.
	
	public var loadUseCountHandler:()->[String:Int] =
	{
		UserDefaults.standard.dictionary(forKey:"BXMediaBrowser-useCount") as? [String:Int] ?? [:]
	}
	
	/// An externally supplied handler that saves useCount statistics to storage.
	///
	/// The default implementation uses UserDefaults, but a client application can store
	/// this information elsewhere, e.g. in a document file.
	
	public var saveUseCountHandler:([String:Int])->Void =
	{
		UserDefaults.standard.set($0, forKey:"BXMediaBrowser-useCount")
	}
	
	/// An externally supplied handler that loads rating statistics from storage.
	///
	/// The default implementation uses UserDefaults, but a client application can store
	/// this information elsewhere, e.g. in a document file.
	
	public var loadRatingHandler:()->[String:Int] =
	{
		UserDefaults.standard.dictionary(forKey:"BXMediaBrowser-rating") as? [String:Int] ?? [:]
	}
	
	/// An externally supplied handler that saves rating statistics to storage.
	///
	/// The default implementation uses UserDefaults, but a client application can store
	/// this information elsewhere, e.g. in a document file.
	
	public var saveRatingHandler:([String:Int])->Void =
	{
		UserDefaults.standard.set($0, forKey:"BXMediaBrowser-rating")
	}
	
}
	
	
//----------------------------------------------------------------------------------------------------------------------


