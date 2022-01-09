//**********************************************************************************************************************
//
//  String+Timecode.swift
//	Extension for displaying and parsing time codes
//  Copyright ©2018 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation


//----------------------------------------------------------------------------------------------------------------------


extension Double
{
	/// Converts the number of seconds into a timecode string of format "HH:MM:SS.ff"
	
	public func timecodeString(fps: Int = 1000) -> String
	{
		var value = self
		let ff = Int(value.truncatingRemainder(dividingBy:1.0) * Double(fps))
		let SS = Int(value.truncatingRemainder(dividingBy:60.0))
		
		value -= Double(SS)
		value /= 60.0
		let MM = Int(value.truncatingRemainder(dividingBy:60.0))
		
		value -= Double(MM)
		value /= 60.0
		let HH = Int(value)
		
		let format = fps > 100 ? "%i:%02i:%02i.%03i" : "%i:%02i:%02i.%02i"
		return NSString(format:format as NSString,HH,MM,SS,ff) as String
	}


	/// Converts the number of seconds into a timecode string of format "HH:MM:SS"
	
	public func shortTimecodeString() -> String
	{
		var value = floor(self)
		let SS = Int(value.truncatingRemainder(dividingBy:60.0))
		
		value -= Double(SS)
		value /= 60.0
		let MM = Int(value.truncatingRemainder(dividingBy:60.0))
		
		value -= Double(MM)
		value /= 60.0
		let HH = Int(value)
		
		if HH > 0
		{
			return NSString(format:"%i:%02i:%02i",HH,MM,SS) as String
		}
		else
		{
			return NSString(format:"%02i:%02i",MM,SS) as String
		}
	}
}


//----------------------------------------------------------------------------------------------------------------------


extension String
{
	/// Converts a timecode string of format "HH:MM:SS.sss" to the time in seconds (as a Double)
	
	public func timecodeValueInSeconds() -> Double
	{
		var value = 0.0
		var factor = 1.0
		let components = self.components(separatedBy:":").reversed()

		for component in components
		{
			if let v = Double(component)
			{
				value += factor * v
			}
			
			factor *= 60.0
		}
		
		return value
	}
}


//----------------------------------------------------------------------------------------------------------------------

