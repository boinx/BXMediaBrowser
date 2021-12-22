//
//  Array+Concatenation.swift
//  BXSwiftUtils
//
//  Created by Stefan Fochler on 08.03.18.
//  Copyright © 2018 Boinx Software Ltd. All rights reserved.
//

import Foundation



/// These extensions ease concatenation opertaions of an array and a single element.
/// See the individual operators for more information.

extension Array where Element: Any
{
	/// Convenient syntax around `Array.append(element)` that allows append one element to an array.
	/// If the added element is an optional that happens to be `nil`, then this operator has no effect.
	///
	/// ## Example
	///
	///	var myArray = [1, 2, 3]
	///	myArray += 4
	///	// myArray is now [1, 2, 3, 4]

    public static func +=(lhs: inout [Element], rhs: Element?)
    {
        if let rhs = rhs
        {
            lhs.append(rhs)
        }
    }
    
	#if !compiler(>=5)
	// Note: The `not >=` is necessary because the Swift-4-compiler don't understand `<`
	
	/// Convenient syntax around `Array.append(contentsOf:)` that allows appending an array to an array.
	
	public static func +=(lhs: inout [Element], rhs: [Element])
	{
        lhs.append(contentsOf:rhs)
	}
	
	/// Convenient syntax around `Array.append(contentsOf:)` that allows appending an optional array to an array.
	
	public static func +=(lhs: inout [Element], rhs: [Element]?)
	{
		guard let rhs = rhs else { return }
        lhs.append(contentsOf:rhs)
	}
	
	#endif


	/// Returns a new array that has `rhs` appended to the end of the `lhs` array.
	/// If the added element is an optional that happens to be `nil`, then this operator stil returns a copy of the array.
	///
	/// ## Example
	///
	///	let myArray = [1, 2, 3]
	///	let newArray = myArray + 4
	///	// myArray is still [1, 2, 3]
	///	// newArray is [1, 2, 3, 4]

    public static func +(lhs: [Element], rhs: Element?) -> [Element]
    {
        var copy = lhs
        if let rhs = rhs
        {
            copy.append(rhs)
        }
        return copy
    }
    
    
	/// Returns a new array that has the `lhs` element prepended to the front of the `rhs` array.
	/// If the added element is an optional that evaluates to `nil`, then this operator stil returns a copy of the array.
	///
	/// ## Example
	///
	///	let myArray = [1, 2, 3]
	///	let newArray = 0 + myArray
	///	// myArray is still [1, 2, 3]
	///	// newArray is [0, 1, 2, 3]

    public static func +(lhs: Element?, rhs: [Element]) -> [Element]
    {
        var copy = rhs
        if let lhs = lhs
        {
            copy.insert(lhs, at: 0)
        }
        return copy
    }
}
