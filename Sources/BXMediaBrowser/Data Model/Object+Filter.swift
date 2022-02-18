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
import BXSwiftUtils


//----------------------------------------------------------------------------------------------------------------------


extension Object
{
	/// An Filter is an abstract base class that can be used for filtering a list of Objects in a Container.
	///
	/// Commonly needed filtering properties are available in this base class. Create subclasses if you need
	/// addtional filtering properties.
	
	open class Filter : ObservableObject, Codable, BXSignpostMixin
	{

		/// The search string is used for Object filtering
		
		@Published public var searchString:String = ""
		
		/// 5-Star rating value

		@Published public var rating:Int = 0

		/// The kind determines how Objects are sorted
	
		@Published public var sortType:SortType = .never

		public typealias SortType = String

		/// The SortDirection determines whether Objects are sorted ascending or descending
	
		@Published public var sortDirection:SortDirection = .ascending
	
		public enum SortDirection : Equatable, Hashable, Codable
		{
			case ascending
			case descending
		}


//----------------------------------------------------------------------------------------------------------------------


		// MARK: -
	
		/// Creates a new Filter instance
		
		public init() { }

		/// Returns a copy of this Filter instance
		
		open func copy() throws -> Self
		{
			let data = try JSONEncoder().encode(self)
			let copy = try JSONDecoder().decode(Self.self, from:data)
			return copy
		}


//----------------------------------------------------------------------------------------------------------------------


		/// A ObjectComparator is a closure that determines if two Objects are ordered ascending (return true)
		/// or descending (returns false).
		
		public typealias ObjectComparator = (Object,Object) -> Bool
		
		/// Returns the correct ObjectComparator for the specified Container. Subclasses should
		/// override this method to return ObjectComparator depending on SortType and SortDirection.
		
		open var objectComparator : ObjectComparator?
		{
			return nil
		}
	
	
//----------------------------------------------------------------------------------------------------------------------


		// MARK: -
	
		private enum Key : String, CodingKey
		{
			case searchString
			case rating
			case sortType
			case sortDirection
		}

		public func encode(to encoder:Encoder) throws
		{
			var container = encoder.container(keyedBy:Key.self)
			
			try container.encode(self.searchString, forKey:.searchString)
			try container.encode(self.rating, forKey:.rating)
			try container.encode(self.sortType, forKey:.sortType)
			try container.encode(self.sortDirection, forKey:.sortDirection)
		}

		public required init(from decoder:Decoder) throws
		{
			let container = try decoder.container(keyedBy:Key.self)
			
			self.searchString  = try container.decodeIfPresent(String.self, forKey:.searchString) ?? ""
			self.rating  = try container.decodeIfPresent(Int.self, forKey:.rating) ?? 0
			self.sortType  = try container.decodeIfPresent(SortType.self, forKey:.sortType) ?? .never
			self.sortDirection  = try container.decodeIfPresent(SortDirection.self, forKey:.sortDirection) ?? .ascending
		}
	}
}


//----------------------------------------------------------------------------------------------------------------------


// MARK: - Sorting
	
extension Object.Filter
{
	/// Sorts the specified array of Objects according to the current sorting parameters
	
	public func sort(_ objects:inout [Object])
	{
		let token = self.beginSignpost(in:"Object.Filter","sort")
		defer { self.endSignpost(with:token, in:"Object.Filter","sort") }
		
		if let comparator = self.objectComparator
		{
			objects.sort(by:comparator)
		}
	}

	/// Toggles the current SortDirection
	
	public func toggleSortDirection()
	{
		self.sortDirection = sortDirection == .ascending ?
			.descending :
			.ascending
	}
}


//----------------------------------------------------------------------------------------------------------------------


extension Object.Filter.SortType
{
	/// Special SortType that does not modify the ordering of Objects
	
	public static let never = "never"

	/// Returns a localized string for displaying the sorting Kind in the user interface
	
	public var localizedName:String
	{
		NSLocalizedString(self, tableName:"SortController", bundle:Bundle.module, comment:"Sorting Kind Name")
	}
}


//----------------------------------------------------------------------------------------------------------------------
