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
import Foundation


//----------------------------------------------------------------------------------------------------------------------


// MARK: -

public class LegacyDataController
{
	/// Updates legacy identifiers to more modern versions. This includes changes during the development of
	/// BXMediaBrowser, as well as conversion of old iMedia persistentResourceIdentifiers into something
	/// that BXMediaBrowser sources understand.
	
	@discardableResult public static func updatedIdentifier(for identifier:String?) -> String?
	{
		guard let identifier = identifier else { return nil }

		// These were changed late in development, while already being used by customers
			
		if identifier.hasPrefix("FolderSource:")
		{
			return identifier
				.replacingOccurrences(of:"FolderSource:", with:"") 					 // FolderSource: -> file://
		}

//		if identifier.hasPrefix("Photos:")
//		{
//			return identifier
//
//				.replacingOccurrences(of:"Photos:Recents", with:"photos://recents")
//				.replacingOccurrences(of:"Photos:Albums", with:"photos://albums")
//				.replacingOccurrences(of:"Photos:Years", with:"photos://years")
//				.replacingOccurrences(of:"Photos:SmartAlbums", with:"photos://smartalbums")
//
//				.replacingOccurrences(of:"Photos:Folder:", with:"photos://folder/")
//				.replacingOccurrences(of:"Photos:Album:", with:"photos://album/")
//				.replacingOccurrences(of:"Photos:Date:", with:"photos://date/")
//				.replacingOccurrences(of:"Photos:Asset:", with:"photos://asset/")	// Photos:Asset: -> photos://asset/
//		}
//
//		if identifier.hasPrefix("MusicSource:")										// MusicSource:ITLibMediaItem: -> music://ITLibMediaItem/
//		{
//			return identifier
//
//				.replacingOccurrences(of:"MusicSource:Songs", with:"music://songs")
//				.replacingOccurrences(of:"MusicSource:Artists", with:"music://artists")
//				.replacingOccurrences(of:"MusicSource:Albums", with:"music://albums")
//				.replacingOccurrences(of:"MusicSource:Genres", with:"music://genres")
//				.replacingOccurrences(of:"MusicSource:Playlists", with:"music://playlists")
//
//				.replacingOccurrences(of:"MusicSource:Artist:", with:"music://artist/")
//				.replacingOccurrences(of:"MusicSource:Album:", with:"music://album/")
//				.replacingOccurrences(of:"MusicSource:Genre:", with:"music://Genre/")
//				.replacingOccurrences(of:"MusicSource:Playlist:", with:"music://playlist/")
//
//				.replacingOccurrences(of:"MusicSource:ITLibMediaItem:", with:"music://ITLibMediaItem/")
//		}
//
//		if identifier.hasPrefix("Unsplash:")
//		{
//			return identifier
//
//				.replacingOccurrences(of:"Unsplash:Search", with:"unsplash://search")
//				.replacingOccurrences(of:"Unsplash:Photo:", with:"unsplash://photo/")
//				.replacingOccurrences(of:"Unsplash:", with:"unsplash://")
//		}


		return identifier
	}

}
	
	
//----------------------------------------------------------------------------------------------------------------------


