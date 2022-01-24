//**********************************************************************************************************************
//
//  Numeric+Localized.swift
//	Adds localized methods for numeric values (Int, Float, Double)
//  Copyright ©2019 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation
import CoreGraphics


//----------------------------------------------------------------------------------------------------------------------


extension NumberFormatter
{
	/// Returns a NumberFormatter for Int numbers
	/// - Parameter numberOfDigits: The number of leading digits (filled with 0)
	/// - Returns: The localized string for the number
	
	public static func forInteger(with format: String = "#,###", numberOfDigits: Int = 0, locale: Locale? = nil) -> NumberFormatter
	{
		let formatter = NumberFormatter()
		formatter.locale = locale ?? Locale.current
		formatter.positiveFormat = format
		formatter.negativeFormat = "-\(format)"
		formatter.minimumIntegerDigits = numberOfDigits
		formatter.usesGroupingSeparator = false
//		formatter.numberStyle = .decimal
		return formatter
    }

	/// Returns a NumberFormatter for Double values
	/// - Parameter format: The format string specifying how the number is displayed
	/// - Parameter numberOfDigits: The number of digits after the decimal point
	/// - Returns: The NumberFormatter
	
	public static func forFloatingPoint(with format: String = "#.#", numberOfDigits: Int = 1, locale: Locale? = nil) -> NumberFormatter
	{
		let formatter = NumberFormatter()
		
		formatter.locale = locale ?? Locale.current
		formatter.maximumFractionDigits = numberOfDigits
		formatter.positiveFormat = format
		formatter.negativeFormat = "-\(format)"

		return formatter
    }
}


//----------------------------------------------------------------------------------------------------------------------


extension Int
{
	/// Returns a localized string for an Int value
	/// - Parameter numberOfDigits: The number of leading zeros, e.g. 1.localized(numberOfDigits:3) returns "001"
	/// - Returns: The localized string for the value
	
    public func localized(with format: String = "#,###", numberOfDigits: Int = 0, locale: Locale? = nil) -> String
	{
		let formatter = NumberFormatter.forInteger(with:format, numberOfDigits:numberOfDigits, locale:locale)
		return formatter.string(from:NSNumber(value:self)) ?? "\(self)"
    }
}


//----------------------------------------------------------------------------------------------------------------------


extension Double
{
	/// Returns a localized string for the Double value
	/// - Parameter format: The format string specifying how the number is displayed
	/// - Parameter numberOfDigits: The number of digits after the decimal point
	/// - Returns: The localized string for the number
	
    public func localized(with format: String = "#.#", numberOfDigits: Int = 1, locale: Locale? = nil) -> String
	{
		let formatter = NumberFormatter.forFloatingPoint(with:format, numberOfDigits:numberOfDigits, locale:locale)
		return formatter.string(from:NSNumber(value:self)) ?? "\(self)"
    }
}


//----------------------------------------------------------------------------------------------------------------------


extension Float
{
	/// Returns a localized string for the Double value
	/// - Parameter format: The format string specifying how the number is displayed
	/// - Parameter numberOfDigits: The number of digits after the decimal point
	/// - Returns: The localized string for the number
	
    public func localized(with format: String = "#.#", numberOfDigits: Int = 1, locale: Locale? = nil) -> String
	{
		let formatter = NumberFormatter.forFloatingPoint(with:format, numberOfDigits:numberOfDigits, locale:locale)
		return formatter.string(from:NSNumber(value:self)) ?? "\(self)"
    }
}


//----------------------------------------------------------------------------------------------------------------------


extension CGFloat
{
	/// Returns a localized string for the Double value
	/// - Parameter format: The format string specifying how the number is displayed
	/// - Parameter numberOfDigits: The number of digits after the decimal point
	/// - Returns: The localized string for the number
	
    public func localized(with format: String = "#.#", numberOfDigits: Int = 1, locale: Locale? = nil) -> String
	{
		return Double(self).localized(with:format, numberOfDigits:numberOfDigits, locale:locale)
    }
}


//----------------------------------------------------------------------------------------------------------------------


extension String
{
	
	/// Strips all non-numeric characters from a String
	/// - Parameter formatter: An optional NumberFormatter that contains localized characters for decimalSeparator and groupingSeparator
	/// - Returns: A string that contains only numeric characters and is thus easy to parse

	public func strippingNonNumericCharacters(with formatter: NumberFormatter? = nil) -> String
	{
		let decimalSeparator = formatter?.decimalSeparator ?? "."
		let groupingSeparator = formatter?.groupingSeparator ?? ","

		var allowedChars = CharacterSet.decimalDigits
		allowedChars.insert(charactersIn:decimalSeparator)
		allowedChars.insert(charactersIn:groupingSeparator)
		allowedChars.insert(charactersIn:"+-")

		let illegalChars = allowedChars.inverted

		return self.components(separatedBy:illegalChars).joined(separator:"")
	}
	
	
	/// Converts a (possibly localized) string to an Int value (using the supplied NumberFormatter)
	/// - Parameter formatter: An optional NumberFormatter that gets the first try to extract the value
	/// - Parameter defaultValue: If value extraction fails then this default value will be returned
	/// - Returns: The extracted number value

    public func intValue(with formatter: NumberFormatter?, defaultValue: Int = 0) -> Int
	{
		let string = self.strippingNonNumericCharacters(with:formatter)
		
		if let formatter = formatter
		{
			// First try parsing with the original format strings
			
			if let number = formatter.number(from:string)
			{
				return number.intValue
			}
			
			// If that failed, then try parsing with stripped format strings (i.e. without the unit suffix)
			
			let suffix = formatter.positiveSuffix ?? ""
			let originalFormat = formatter.positiveFormat ?? "#,###"
			let strippedFormat = originalFormat.replacingOccurrences(of:suffix, with:"")
			
			formatter.positiveFormat = strippedFormat
			formatter.negativeFormat = "-\(strippedFormat)"

			defer
			{
				formatter.positiveFormat = originalFormat
				formatter.negativeFormat = "-\(originalFormat)"
			}
			
			if let number = formatter.number(from:string)
			{
				return number.intValue
			}
		}
		
		// Last ditch attempt, just use type conversion
		
		return Int(string) ?? defaultValue
    }


 	/// Converts a (possibly localized) string to a Double value (using the supplied NumberFormatter)
	/// - Parameter formatter: An optional NumberFormatter that gets the first try to extract the value
	/// - Parameter defaultValue: If value extraction fails then this default value will be returned
	/// - Returns: The extracted number value

	public func doubleValue(with formatter: NumberFormatter?, defaultValue: Double = 0.0) -> Double
	{
		let string = self.strippingNonNumericCharacters(with:formatter)

		if let number = formatter?.number(from:string)
		{
			return number.doubleValue
		}

		return Double(string) ?? defaultValue
    }
	
	
 	/// Converts a (possibly localized) string to a Float value (using the supplied NumberFormatter)
	/// - Parameter formatter: An optional NumberFormatter that gets the first try to extract the value
	/// - Parameter defaultValue: If value extraction fails then this default value will be returned
	/// - Returns: The extracted number value

    public func floatValue(with formatter: NumberFormatter?, defaultValue: Float = 0.0) -> Float
	{
		let string = self.strippingNonNumericCharacters(with:formatter)

		if let number = formatter?.number(from:string)
		{
			return number.floatValue
		}

		return Float(string) ?? defaultValue
    }
}


//----------------------------------------------------------------------------------------------------------------------
