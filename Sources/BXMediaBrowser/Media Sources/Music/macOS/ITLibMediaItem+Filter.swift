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


extension ITLibMediaItem
{
	/// Returns true if any of the item properties contains the filter's searchString
	
	public func contains(_ filter:Any?) -> Bool
	{
		guard let musicFilter = filter as? MusicFilter else { return true }
		let searchString = musicFilter.searchString.lowercased()
		guard !searchString.isEmpty else { return true }

		// Check item name
		
		if self.title.lowercased().contains(searchString)
		{
			return true
		}
		
		// Check artist name
		
		if let artist = self.artist, let name = artist.name, name.lowercased().contains(searchString)
		{
			return true
		}
		
		// Check composer name
		
		if self.composer.lowercased().contains(searchString)
		{
			return true
		}
		
		// Check album name
		
		if let album = self.album.title, album.lowercased().contains(searchString)
		{
			return true
		}
		
		// Check genre name
		
		if self.genre.lowercased().contains(searchString)
		{
			return true
		}

		return false
	}
}


//----------------------------------------------------------------------------------------------------------------------


#endif
