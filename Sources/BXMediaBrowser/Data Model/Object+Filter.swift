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


extension Object
{
	/// An Filter is an abstract base class that can be used for filtering a list of Objects in a Container.
	///
	/// Commonly needed filtering properties are available in this base class. Create subclasses if you need
	/// addtional filtering properties.
	
	open class Filter : ObservableObject, Codable
	{
		/// The search string is used for Object filtering
		
		@Published var searchString:String = ""
		
		/// 5-Star rating value

		@Published var rating:Int = 0

		// To make the compiler happy, we have to have a public init here
		
		public init() { }

		// Codable support
		
		private enum Key : String, CodingKey
		{
			case searchString
			case rating
		}

		public func encode(to encoder:Encoder) throws
		{
			var container = encoder.container(keyedBy:Key.self)
			try container.encode(self.searchString, forKey:.searchString)
			try container.encode(self.rating, forKey:.rating)
		}

		public required init(from decoder:Decoder) throws
		{
			let container = try decoder.container(keyedBy:Key.self)
			self.searchString  = try container.decode(String.self, forKey:.searchString)
			self.rating  = try container.decode(Int.self, forKey:.rating)
		}
		
		/// Returns a copy of this Filter
		
		open func copy() throws -> Self
		{
			let data = try JSONEncoder().encode(self)
			let copy = try JSONDecoder().decode(Self.self, from:data)
			return copy
		}
	}
}


//----------------------------------------------------------------------------------------------------------------------

