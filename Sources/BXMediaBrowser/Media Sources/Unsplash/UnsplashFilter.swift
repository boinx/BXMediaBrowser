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


import SwiftUI


//----------------------------------------------------------------------------------------------------------------------


/// This struct bundles all parameters for a photo search on Unsplash.com

public class UnsplashFilter : Object.Filter //, Codable
{
	/// If non-nil then search results will be restricted to the specified Orientation
	
	@Published public var orientation:Orientation = .any
	
	/// If non-nil then search results will be restricted to the specified Color style
	
	@Published public var color:Color = .any

	// To make the compiler happy, we have to have a public init here
	
	override public init()
	{
		super.init()
	}
	
	// Unfortunately the Codable stuff cannot be put in an extension:
	
	private enum Key : String, CodingKey
	{
		case orientation
		case color
	}

	override public func encode(to encoder:Encoder) throws
	{
		try super.encode(to:encoder)
		
		var container = encoder.container(keyedBy:Key.self)
		try container.encode(self.orientation, forKey:.orientation)
		try container.encode(self.color, forKey:.color)
	}

	public required init(from decoder:Decoder) throws
	{
		try super.init(from:decoder)
		
		let container = try decoder.container(keyedBy:Key.self)
		self.orientation  = try container.decode(Orientation.self, forKey:.orientation)
		self.color  = try container.decode(Color.self, forKey:.color)
	}
}


//----------------------------------------------------------------------------------------------------------------------


extension UnsplashFilter : Equatable
{
	public static func == (lhs:UnsplashFilter, rhs:UnsplashFilter) -> Bool
	{
		lhs.searchString == rhs.searchString &&
		lhs.orientation == rhs.orientation &&
		lhs.color == rhs.color &&
		lhs.rating == rhs.rating
	}

	public var copy: UnsplashFilter
	{
		let copy = UnsplashFilter()
		copy.searchString = self.searchString
		copy.orientation = self.orientation
		copy.color = self.color
		return copy
	}
}


//----------------------------------------------------------------------------------------------------------------------


extension UnsplashFilter
{
	public enum Orientation : String, CaseIterable, Equatable, Codable
	{
		case any = ""
		case landscape
		case portrait
		case squarish
		
		var identifier:String
		{
			self.rawValue
		}
		
		static var allIdentifiers:[String]
		{
			self.allCases.map { $0.rawValue }
		}
		
		var localizedName:String
		{
			if self == .any
			{
				return NSLocalizedString("any", tableName:"Unsplash", bundle:.BXMediaBrowser, comment:"Orientation Name")
			}
			
			return NSLocalizedString(identifier, tableName:"Unsplash", bundle:.BXMediaBrowser, comment:"Orientation Name")
		}
		
		var icon:String
		{
			switch self
			{
				case .any: return "rectangle.3.group"
				case .landscape: return "rectangle"
				case .portrait: return "rectangle.portrait"
				case .squarish: return "square"
			}
		}
	}
}


//----------------------------------------------------------------------------------------------------------------------


extension UnsplashFilter
{
	public enum Color : String, CaseIterable, Equatable, Codable
	{
		case any = ""
		case black_and_white
		case black
		case white
		case yellow
		case orange
		case red
		case purple
		case magenta
		case green
		case teal
		case blue

		var identifier:String
		{
			self.rawValue
		}
		
		static var allIdentifiers:[String]
		{
			self.allCases.map { $0.identifier }
		}
		
		var localizedName:String
		{
			if self == .any
			{
				return NSLocalizedString("any", tableName:"Unsplash", bundle:.BXMediaBrowser, comment:"Color Name")
			}
			
			return NSLocalizedString(identifier, tableName:"Unsplash", bundle:.BXMediaBrowser, comment:"Color Name")
		}
		
		var color:SwiftUI.Color
		{
			switch self
			{
				case .black_and_white : return .gray
				case .black : 			return .black
				case .white : 			return .white
				case .yellow : 			return .yellow
				case .orange : 			return .orange
				case .red : 			return .red
				case .purple : 			return .purple
				case .magenta : 		return .pink
				case .green : 			return .green
				case .teal : 			return SwiftUI.Color(red:0.0, green:0.66, blue:0.66)
				case .blue : 			return .blue
				default: 				return .clear
			}
		}
	}
}


//----------------------------------------------------------------------------------------------------------------------
