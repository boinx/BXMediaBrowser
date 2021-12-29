//**********************************************************************************************************************
//
//  NSObject+Coalescing.swift
//	Adds new perform methods to NSObject
//  Copyright ©2016-2018 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation


//----------------------------------------------------------------------------------------------------------------------


public extension NSObject
{
	/// Performs a method call after the specified delay. If multiple requests are queued up, the method will be
	/// called only once after the delay has elapsed. Please note that both the method selector and the argument
	/// need to be the same for coalescing to take effect.
	///
	/// - parameter selector: The single argument method to be called
	/// - parameter argument: The object argument to this method
	/// - parameter delay: This method will only be called after this optional delay has elapsed. If the delay is
	/// 0.0 it will be called during the next runloop cycle.
	
	func performCoalesced(_ selector: Selector, argument: AnyObject?=nil, delay: TimeInterval=0.0)
	{
		NSObject.cancelPreviousPerformRequests(withTarget:self, selector:selector, object:argument)
        #if swift(>=4.2)
        let modes = [RunLoop.Mode.common]
        #else
        let modes = [RunLoopMode.commonModes]
        #endif
		self.perform(selector, with:argument, afterDelay:delay, inModes:modes)
	}


	/// Cancel a specific outstanding perform request for the specified method and argument. Please note that the
	/// combination of selector and argument is important here. Using the same selector with a different argument
	/// will not cancel anything.
	///
	/// - parameter selector: The method to be canceled
	/// - parameter argument: The object argument to this method
	
	func cancelDelayedPerform(_ selector: Selector, argument: AnyObject?=nil)
	{
		NSObject.cancelPreviousPerformRequests(withTarget:self, selector:selector, object:argument)
	}


	/// Cancel all outstanding perform requests for the receiving object.
	
	func cancelAllDelayedPerforms()
	{
		NSObject.cancelPreviousPerformRequests(withTarget:self)
		RunLoop.current.cancelPerformSelectors(withTarget:self)
	}
}


//----------------------------------------------------------------------------------------------------------------------
