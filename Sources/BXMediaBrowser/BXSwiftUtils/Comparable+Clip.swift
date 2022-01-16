//
//  Comparable+Clip.swift
//  BXSwiftUtils
//
//  Created by Benjamin Federer on 21.11.18.
//  Copyright © 2018 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

import Foundation

extension Comparable
{
	/**
	 Clips a value into the closed range `[min, max]` without modifying the original value.
	
	 - Parameter minValue: The minimum allowed value.
	 - Parameter maxValue: The maximum allowed value.
	 - Returns: A new value that lies within the closed range `[min, max]`.
	 */
	public func clipped(min minValue: Self, max maxValue: Self) -> Self
	{
		var copy = self
		copy.clip(min: minValue, max: maxValue)
		return copy
	}
	
	/**
	 Clips a value into the closed range `[min, max]` by modifying the original value.
	
	 - Parameter minValue: The minimum allowed value.
	 - Parameter maxValue: The maximum allowed value.
	 */
	public mutating func clip(min minValue: Self, max maxValue: Self)
	{
		if minValue > maxValue
		{
			NSException.raise(.invalidArgumentException, format: "Can't clip value \(self) with maxValue \(maxValue) being larger than minValue \(minValue)", arguments: getVaList([]))
		}
		
		if self < minValue
		{
			self = minValue
		}
		else if self > maxValue
		{
			self = maxValue
		}
	}
	
	/**
	 Clips a value into the given closed range without modifying the original value.
	
	 - Parameter range: Closed range that conveys the minimum and maximum allowed value.
	 - Returns: New value that lies within the closed range `range`.
	 */
	public func clipped(to range: ClosedRange<Self>) -> Self
	{
		var copy = self
		copy.clip(min: range.lowerBound, max: range.upperBound)
		return copy
	}
	
	/**
	 Clips a value into the given closed range by modifying the original value.
	
	 - Parameter range: Closed range that conveys the minimum and maximum allowed value.
	 */
	public mutating func clip(to range: ClosedRange<Self>)
	{
		self.clip(min: range.lowerBound, max: range.upperBound)
	}
}
