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


import BXSwiftUtils
import SwiftUI


//----------------------------------------------------------------------------------------------------------------------


extension Object
{
	/// An Filter is an abstract base class that can be used for filtering down and sorting a list of Objects in a Container.
	///
	/// Create a contrete subclass that has published properties for filtering and/or sorting.
	
	open class Filter : ObservableObject
	{
		public enum SortOrder : Equatable,Hashable
		{
			/// The Direction applies to all SortOrder cases below
			
			public enum Direction : Equatable,Hashable
			{
				case ascending
				case descending
			}

			/// Sorts Objects alphabetically (by name)
			
			case alphabetical(direction:Direction)
			
			/// Sorts Objects by file creation date
			
			case creationDate(direction:Direction)

			/// Sorts Objects by capture date (which is more appropriate for image files as capture date might be earlier than file creation date)
			
			case captureDate(direction:Direction)

			/// Sorts Objects by pixel size (width x height)
			
			case pixelSize(direction:Direction)

			/// Sorts Objects by duration (appropriate for audio or video files)
			
			case duration(direction:Direction)

			/// Sorts Objects by artist (appropriate for audio content)
			
			case artist(direction:Direction)

			/// Sorts Objects by album (appropriate for audio content)
			
			case album(direction:Direction)

			/// Sorts Objects by genre (appropriate for audio content)
			
			case genre(direction:Direction)
		}
	}
}


//----------------------------------------------------------------------------------------------------------------------


extension Object.Filter.SortOrder
{
	public var localizedName:String
	{
		switch self
		{
			case .alphabetical(let direction):
				
				switch direction
				{
					case .ascending: 	return "Alphabetical △"
					case .descending:	return "Alphabetical ▽"
				}
				
			case .creationDate(let direction):
			
				switch direction
				{
					case .ascending: 	return "Creation Date △"
					case .descending:	return "Creation Date ▽"
				}

			case .captureDate(let direction):
			
				switch direction
				{
					case .ascending: 	return "Capture Date △"
					case .descending:	return "Capture Date ▽"
				}

			case .pixelSize(let direction):
			
				switch direction
				{
					case .ascending: 	return "Size △"
					case .descending:	return "Size ▽"
				}

			case .duration(let direction):
			
				switch direction
				{
					case .ascending: 	return "Duration △"
					case .descending:	return "Duration ▽"
				}

			case .artist(let direction):
			
				switch direction
				{
					case .ascending: 	return "Artist △"
					case .descending:	return "Artist ▽"
				}

			case .album(let direction):
			
				switch direction
				{
					case .ascending: 	return "Album △"
					case .descending:	return "Album ▽"
				}

			case .genre(let direction):
			
				switch direction
				{
					case .ascending: 	return "Genre △"
					case .descending:	return "Genre ▽"
				}
		}
	}
}

	
//----------------------------------------------------------------------------------------------------------------------


extension Object.Filter.SortOrder
{
	public var compare:(_ object1:Object,_ object2:Object) -> Bool
	{
		switch self
		{
			case .alphabetical(let direction):
				
				switch direction
				{
					case .ascending: 	return Self.sortAlphabeticalAscending
					case .descending:	return Self.sortAlphabeticalDescending
				}
				
			case .creationDate(let direction):
			
				switch direction
				{
					case .ascending: 	return Self.sortCreationDateAscending
					case .descending:	return Self.sortCreationDateDescending
				}
				
			default:
			
				#warning("TODO: implement other cases ")
				return { _,_ in false }
		}
	}
	
	
	public static func sortAlphabeticalAscending(_ object1:Object,_ object2:Object) -> Bool
	{
		let name1 = object1.name as NSString
		let name2 = object2.name //as NSString
		return name1.localizedStandardCompare(name2) == .orderedAscending
//		return name1 < name2
	}
	
	
	public static func sortAlphabeticalDescending(_ object1:Object,_ object2:Object) -> Bool
	{
		let name1 = object1.name as NSString
		let name2 = object2.name //as NSString
		return name1.localizedStandardCompare(name2) == .orderedDescending
//		return name1 > name2
	}
	
	
	public static func sortCreationDateAscending(_ object1:Object,_ object2:Object) -> Bool
	{
		guard let url1 = object1.data as? URL else { return false }
		guard let url2 = object2.data as? URL else { return false }
		guard let date1 = url1.creationDate else { return false }
		guard let date2 = url2.creationDate else { return false }
		return date1 < date2
	}
	
	
	public static func sortCreationDateDescending(_ object1:Object,_ object2:Object) -> Bool
	{
		guard let url1 = object1.data as? URL else { return false }
		guard let url2 = object2.data as? URL else { return false }
		guard let date1 = url1.creationDate else { return false }
		guard let date2 = url2.creationDate else { return false }
		return date1 > date2
	}
}


//----------------------------------------------------------------------------------------------------------------------
