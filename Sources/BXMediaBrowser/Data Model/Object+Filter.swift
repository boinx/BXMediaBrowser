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
	
		public var sortDirection:SortDirection
		{
			set
			{
				self.objectWillChange.send()
				_sortDirection[sortType] = newValue
			}
			
			get
			{
				_sortDirection[sortType] ?? .ascending
			}
		}
		
		private var _sortDirection:[SortType:SortDirection] = Object.Filter.defaultSortDirections()

		/// The SortDirection determines whether Objects are sorted ascending or descending
	
		public enum SortDirection : Int,Equatable,Hashable,Codable
		{
			case ascending
			case descending
		}
		
		
//----------------------------------------------------------------------------------------------------------------------


		// MARK: -
	
		/// Creates a new Filter instance
		
		public init()
		{

		}

		/// Returns a copy of this Filter instance
		
		open func copy() throws -> Self
		{
			let data = try JSONEncoder().encode(self)
			let copy = try JSONDecoder().decode(Self.self, from:data)
			return copy
		}


//----------------------------------------------------------------------------------------------------------------------


		// MARK: - Sorting
	
		/// A ObjectComparator is a closure that determines if two Objects are ordered ascending (return true)
		/// or descending (returns false).
		
		public typealias ObjectComparator = (Object,Object) -> Bool
		
		/// Returns the correct ObjectComparator for the specified Container. Subclasses should
		/// override this method to return ObjectComparator depending on SortType and SortDirection.
		
		open var objectComparator : ObjectComparator?
		{
			return nil
		}
	
		/// Sorts the specified array of Objects according to the current sorting parameters
		
		open func sort(_ objects:inout [Object])
		{
			let token = self.beginSignpost(in:"Object.Filter","sort")
			defer { self.endSignpost(with:token, in:"Object.Filter","sort") }
			
			if let comparator = self.objectComparator
			{
				objects.sort(by:comparator)
			}
		}

	
//----------------------------------------------------------------------------------------------------------------------


		// MARK: - Coding
	
		private enum Key : String, CodingKey
		{
			case searchString
			case rating
			case sortType
			case sortDirection
			case sortDirectionByType
		}

		public func encode(to encoder:Encoder) throws
		{
			var container = encoder.container(keyedBy:Key.self)
			
			try container.encode(self.searchString, forKey:.searchString)
			try container.encode(self.rating, forKey:.rating)
			try container.encode(self.sortType, forKey:.sortType)
			try container.encode(self._sortDirection, forKey:.sortDirectionByType)
		}

		public required init(from decoder:Decoder) throws
		{
			let container = try decoder.container(keyedBy:Key.self)
			
			self.searchString  = try container.decodeIfPresent(String.self, forKey:.searchString) ?? ""
			self.rating  = try container.decodeIfPresent(Int.self, forKey:.rating) ?? 0
			self.sortType  = try container.decodeIfPresent(SortType.self, forKey:.sortType) ?? .never
//			self.sortDirection  = try container.decodeIfPresent(SortDirection.self, forKey:.sortDirection) ?? .ascending
			self._sortDirection  = try container.decodeIfPresent([SortType:SortDirection].self, forKey:.sortDirectionByType) ?? Object.Filter.defaultSortDirections()
		}
	}
}


//----------------------------------------------------------------------------------------------------------------------


// MARK: - Sorting
	
extension Object.Filter
{
	/// Defines the default SortDirection for each SortType
	
	private static func defaultSortDirections() -> [SortType:SortDirection]
	{
		[
			.never : .ascending,
			.rating : .descending,
			.useCount : .descending,
			.captureDate : .ascending,
			.creationDate : .ascending,
			.alphabetical : .ascending,
			.duration : .ascending,
			.artist : .ascending,
			.album : .ascending,
			.genre : .ascending,
		]
	}

	/// Toggles the current SortDirection
	
	public func toggleSortDirection()
	{
		self.sortDirection = sortDirection == .ascending ?
			.descending :
			.ascending
	}

	/// Compares Object ratings
	
	public static func compareRating(_ object1:Object,_ object2:Object) -> Bool
	{
		let rating1 = StatisticsController.shared.rating(for:object1)
		let rating2 = StatisticsController.shared.rating(for:object2)
		
		if rating1 == rating2
		{
			return FolderFilter.compareAlphabetical(object1,object2)
		}
		
		return rating1 < rating2
	}

	/// Sorts Objects by useCount
	
	public static func compareUseCount(_ object1:Object,_ object2:Object) -> Bool
	{
		let useCount1 = StatisticsController.shared.useCount(for:object1)
		let useCount2 = StatisticsController.shared.useCount(for:object2)
		
		if useCount1 == useCount2
		{
			return FolderFilter.compareAlphabetical(object1,object2)
		}
		
		return useCount1 < useCount2
	}
}


//----------------------------------------------------------------------------------------------------------------------


extension Object.Filter.SortType
{
	/// Special SortType that does not modify the ordering of Objects
	
	public static let never = "never"

	/// Sort Objects by rating
	
	public static let rating = "rating"

	/// Sort Objects by useCount
	
	public static let useCount = "useCount"

	/// Returns a localized string for displaying the sorting Kind in the user interface
	
	public var localizedName:String
	{
		NSLocalizedString(self, tableName:"Object.Filter", bundle:Bundle.BXMediaBrowser, comment:"Sorting Kind Name")
	}
}


//----------------------------------------------------------------------------------------------------------------------
