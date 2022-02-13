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
import UIKIt
#endif


//----------------------------------------------------------------------------------------------------------------------


@MainActor public class StatisticsController
{
	/// The shared singleton instance of this controller
	
	public static let shared = StatisticsController()
	
	/// Subscribers or KVO observers
	
	private var observers:[Any] = []
	
	/// This notification is sent (from the main thread) whenever a statistics value was changed.
	///
	/// The BXMediaBrowser.Object is stored in notification.object.
	
	public static let didChangeNotification = Notification.Name("BXMediaBrowser.StatisticsController.didChange")
	
	
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
		let identifier = object.identifier
		
		var n = useCount[identifier] ?? 0
		n += 1
		useCount[identifier] = n
		
		NotificationCenter.default.post(name: Self.didChangeNotification, object:object)
		
		return n
	}

	/// Decrements the use count for the specified Object
	
	@discardableResult public func decrementUseCount(for object:Object) -> Int
	{
		let identifier = object.identifier
		var n = useCount[identifier] ?? 0
		
		if n > 0
		{
			n -= 1
			self.useCount[identifier] = n
		}
		else
		{
			self.useCount[identifier] = nil
		}
		
		NotificationCenter.default.post(name: Self.didChangeNotification, object:object)

		return n
	}

	/// Returns the use count for the specified Object
	
	public func useCount(for object:Object) -> Int
	{
		self.useCount[object.identifier] ?? 0
	}
	
	/// Storage for use count statistics
	
	private var useCount:[String:Int] = [:]
	
	
//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Rating
	
	
	/// Sets the rating for the specified Object
	
	public func setRating(_ rating:Int, for object:Object)
	{
		self.rating[object.identifier] = rating
		NotificationCenter.default.post(name: Self.didChangeNotification, object:object)
	}

	/// Returns the rating for the specified Object
	
	public func rating(for object:Object) -> Int
	{
		self.rating[object.identifier] ?? 0
	}
	
	/// Storage for rating statistics
	
	private var rating:[String:Int] = [:]
	
	
//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Load & Save
	
	
	/// Loads statistics from storage
	
	public func load()
	{
		self.useCount = self.loadUseCountHandler()
		self.rating = self.loadRatingHandler()
	}

	/// Saves statistics to storage
	
	public func save()
	{
		self.saveUseCountHandler(useCount)
		self.saveRatingHandler(rating)
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


