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


#if os(macOS)

import iTunesLibrary


//----------------------------------------------------------------------------------------------------------------------


open class MusicFilter : Object.Filter
{
	/// Returns true if any of the item properties contains the filter's searchString
	
	public func contains(_ item:ITLibMediaItem) -> Bool
	{
		// Is rating suffcient?
		
		let identifier = MusicSource.objectIdentifier(with:item)
		guard StatisticsController.shared.rating(for:identifier) >= self.rating else { return false }
		
		// Empty search string will accept all items
		
		let searchString = self.searchString.lowercased()
		guard !searchString.isEmpty else { return true }

		// Check item name
		
		if item.title.lowercased().contains(searchString)
		{
			return true
		}
		
		// Check artist name
		
		if let artist = item.artist, let name = artist.name, name.lowercased().contains(searchString)
		{
			return true
		}
		
		// Check composer name
		
		if item.composer.lowercased().contains(searchString)
		{
			return true
		}
		
		// Check album name
		
		if let album = item.album.title, album.lowercased().contains(searchString)
		{
			return true
		}
		
		// Check genre name
		
		if item.genre.lowercased().contains(searchString)
		{
			return true
		}

		return false
	}


//----------------------------------------------------------------------------------------------------------------------


	override open var objectComparator : ObjectComparator?
	{
		if sortType == .artist
		{
			let comparator = Self.compareArtist
			if sortDirection == .ascending { return comparator }
			return { !comparator($0,$1) }
		}
		else if sortType == .album
		{
			let comparator = Self.compareAlbum
			if sortDirection == .ascending { return comparator }
			return { !comparator($0,$1) }
		}
		else if sortType == .genre
		{
			let comparator = Self.compareGenre
			if sortDirection == .ascending { return comparator }
			return { !comparator($0,$1) }
		}
		else if sortType == .duration
		{
			let comparator = Self.compareDuration
			if sortDirection == .ascending { return comparator }
			return { !comparator($0,$1) }
		}
		
		return nil
	}


//----------------------------------------------------------------------------------------------------------------------


	public static func compareArtist(_ object1:Object,_ object2:Object) -> Bool
	{
		guard let item1 = (object1 as? MusicObject)?.data as? ITLibMediaItem else { return false }
		guard let item2 = (object2 as? MusicObject)?.data as? ITLibMediaItem else { return false }
		let artist1 = item1.artist?.name ?? ""
		let artist2 = item2.artist?.name ?? ""
		return artist1 < artist2
	}


	public static func compareAlbum(_ object1:Object,_ object2:Object) -> Bool
	{
		guard let item1 = (object1 as? MusicObject)?.data as? ITLibMediaItem else { return false }
		guard let item2 = (object2 as? MusicObject)?.data as? ITLibMediaItem else { return false }
		let album1 = item1.album.title ?? ""
		let album2 = item2.album.title ?? ""
		return album1 < album2
	}


	public static func compareGenre(_ object1:Object,_ object2:Object) -> Bool
	{
		guard let item1 = (object1 as? MusicObject)?.data as? ITLibMediaItem else { return false }
		guard let item2 = (object2 as? MusicObject)?.data as? ITLibMediaItem else { return false }
		let genre1 = item1.genre
		let genre2 = item2.genre
		return genre1 < genre2
	}


	public static func compareDuration(_ object1:Object,_ object2:Object) -> Bool
	{
		guard let item1 = (object1 as? MusicObject)?.data as? ITLibMediaItem else { return false }
		guard let item2 = (object2 as? MusicObject)?.data as? ITLibMediaItem else { return false }
		let totalTime1 = item1.totalTime
		let totalTime2 = item2.totalTime
		return totalTime1 < totalTime2
	}
}


//----------------------------------------------------------------------------------------------------------------------


extension Object.Filter.SortType
{
	public static let artist = "artist"
	public static let album = "album"
	public static let genre = "genre"
	public static let duration = "duration"
}


//----------------------------------------------------------------------------------------------------------------------


//extension ITLibMediaItem
//{
//	/// Returns true if any of the item properties contains the filter's searchString
//
//	public func contains(_ filter:MusicFilter) -> Bool
//	{
//		let searchString = filter.searchString.lowercased()
//		guard !searchString.isEmpty else { return true }
//
//		// Check item name
//
//		if self.title.lowercased().contains(searchString)
//		{
//			return true
//		}
//
//		// Check artist name
//
//		if let artist = self.artist, let name = artist.name, name.lowercased().contains(searchString)
//		{
//			return true
//		}
//
//		// Check composer name
//
//		if self.composer.lowercased().contains(searchString)
//		{
//			return true
//		}
//
//		// Check album name
//
//		if let album = self.album.title, album.lowercased().contains(searchString)
//		{
//			return true
//		}
//
//		// Check genre name
//
//		if self.genre.lowercased().contains(searchString)
//		{
//			return true
//		}
//
//		return false
//	}
//}


//----------------------------------------------------------------------------------------------------------------------


#endif
