//**********************************************************************************************************************
//
//  Synchronized.swift
//	Simulates the @synchronized directive of Objective-C
//  Copyright ©2016 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation


//----------------------------------------------------------------------------------------------------------------------

/**

 This global functions simulates the @synchronized feature of Objective-C.
 Use just like in Objective-C, but without the @ character.
 
 The block may also return some value, wich is useful for implementing getter methods:

     synchronized(self)
     {
         return _someUnsafeProperty
     }

 - Parameter lock: The object that is used for locking.
 - Parameter closure: The closure that is executed when the lock is acquired.
 - Returns: The return value of the block is returned to the caller.
 - Throws: Re-throws if the given block throws.
*/
public func synchronized<T>(_ lock: AnyObject, _ closure: () throws -> T) rethrows -> T
{
    objc_sync_enter(lock)
    defer { objc_sync_exit(lock) }

    return try closure()
}


//----------------------------------------------------------------------------------------------------------------------
