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

public struct UnsplashFilter : Equatable,Codable
{
	/// The search string for looking up images on Unsplash.com
	
	public var searchString:String = ""
	
	/// If non-nil then search results will be restricted to the specified Orientation
	
	public var orientation:Orientation? = nil
	
	/// If non-nil then search results will be restricted to the specified Color style
	
	public var color:Color? = nil
}


//----------------------------------------------------------------------------------------------------------------------


extension UnsplashFilter
{
	public enum Orientation : String,Equatable,CaseIterable,Codable
	{
		case any = ""
		case landscape
		case portrait
		case squarish
		
		var identifier:String
		{
			self.rawValue
		}
		
		var localizedName:String
		{
			switch self
			{
				case .any : return "Any"
				case .landscape : return "Horizontal"
				case .portrait : return "Vertical"
				case .squarish : return "Square"
			}
		}
		
		static var allValues:[String]
		{
			self.allCases.map { $0.rawValue }
		}
	}
}


//----------------------------------------------------------------------------------------------------------------------


extension UnsplashFilter
{
	public enum Color : String,Equatable,CaseIterable,Codable
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
		
		var localizedName:String
		{
			switch self
			{
				case .any : return "Any"
				case .black_and_white : return "B&W"
				case .black : return "Dark"
				case .white : return "Bright"
				case .yellow : return "Yellow"
				case .orange : return "Orange"
				case .red : return "Red"
				case .purple : return "Purple"
				case .magenta : return "Pink"
				case .green : return "Green"
				case .teal : return "Teal"
				case .blue : return "Blue"
			}
		}
		
		var color:SwiftUI.Color
		{
			switch self
			{
				case .black_and_white : return .gray
				case .black : return .black
				case .white : return .white
				case .yellow : return .yellow
				case .orange : return .orange
				case .red : return .red
				case .purple : return .purple
				case .magenta : return .pink
				case .green : return .green
				case .teal : return SwiftUI.Color(red:0.0, green:0.66, blue:0.66)
				case .blue : return .blue
				default: return .clear
			}
		}
		
		static var allIdentifiers:[String]
		{
			self.allCases.map { $0.identifier }
		}
	}
}


//----------------------------------------------------------------------------------------------------------------------
