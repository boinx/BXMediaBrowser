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


public protocol UseCountDataSource : AnyObject
{
	func useCount(for identifier:String) -> Int
}


//----------------------------------------------------------------------------------------------------------------------


// MARK: -

public class StatisticsController : ObservableObject
{
	/// The shared singleton instance of this controller
	
	public static let shared = StatisticsController()
	
	/// Subscribers or KVO observers
	
	private var observers:[Any] = []
	

//----------------------------------------------------------------------------------------------------------------------

	
	/// Storage for rating statistics
	
	private var _rating:[String:Int] = [:]

	/// This notification is sent when a ratings value was changed.
	///
	/// The BXMediaBrowser.Object is stored in notification.object.

	public static let ratingNotification = Notification.Name("BXMediaBrowser.StatisticsController.rating")

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
	

//----------------------------------------------------------------------------------------------------------------------


	/// This notification is sent (from the main thread) whenever a statistics value was changed.
	///
	/// The identifier of the changed Object is stored in notification.object. If all Objects are changed at once,
	/// then notification.object will be nil.
	
	public static let didChangeNotification = Notification.Name("BXMediaBrowser.StatisticsController.didChange")
	
		
//----------------------------------------------------------------------------------------------------------------------


	private init()
	{
		// On startup load the previous statistics
		
		self.loadRatings()
		
		// When quitting save the current statistics
		
		#if os(macOS)
		
		self.observers += NotificationCenter.default.publisher(for:NSApplication.willTerminateNotification, object:nil).sink
		{
			[weak self] _ in self?.saveRatings()
		}
		
		#else

		#warning("TODO: implement")
		
		#endif
	}
	


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Use Count
	
	
	public func useCount(for object:Object) -> Int
	{
		self.useCount(for:object.identifier)
	}
	
	public func useCount(for identifier:String) -> Int
	{
		self.useCountDataSource?.useCount(for:identifier) ?? 0
	}

	public weak var useCountDataSource:UseCountDataSource? = nil
	
	
//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Rating
	
	
	/// Loads statistics from storage
	
	public func loadRatings()
	{
		self._rating = self.loadRatingHandler()
	}

	/// Saves statistics to storage
	
	public func saveRatings()
	{
		self.saveRatingHandler(_rating)
	}
	
	
//----------------------------------------------------------------------------------------------------------------------


	/// Sets the rating for the specified Object
	
	public func setRating(_ rating:Int, for object:Object, sendNotifications:Bool = true)
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
			NotificationCenter.default.post(name: Self.ratingNotification, object:object)
			NotificationCenter.default.post(name: Self.didChangeNotification, object:object.identifier)
		}
	}


//----------------------------------------------------------------------------------------------------------------------


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

}
	
	
//----------------------------------------------------------------------------------------------------------------------


