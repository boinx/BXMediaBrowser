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


import Photos
import iTunesLibrary


//----------------------------------------------------------------------------------------------------------------------


public class MusicContainer : Container
{
	public enum Kind
	{
		case library(mediaItems:[ITLibMediaItem])
		case albumFolder(mediaItems:[ITLibMediaItem])
		case album(album:ITLibAlbum, mediaItems:[ITLibMediaItem])
		case artistFolder(mediaItems:[ITLibMediaItem])
		case artist(artist:ITLibArtist, mediaItems:[ITLibMediaItem])
		case playlistFolder(playlists:[ITLibPlaylist])
		case playlist(playlist:ITLibPlaylist)
	}


 	public init(identifier:String, kind:Kind, icon:String?, name:String)
	{
		super.init(
			identifier:identifier,
			info:kind,
			icon:icon,
			name:name,
			loadHandler:Self.loadContents)
	}
	

	override var canExpand:Bool
	{
		guard let kind = info as? Kind else { return true }

		switch kind
		{
			case .library: return false
			case .album: return false
			case .artist: return false
			case .playlist: return false
			default: return true
		}
	}
	
	
//----------------------------------------------------------------------------------------------------------------------


	/// Loads the (shallow) contents of this folder
	
	class func loadContents(for identifier:String, info:Any, filter:String) async throws -> Loader.Contents
	{
		var containers:[Container] = []
		var objects:[Object] = []
		
		guard let kind = info as? Kind else { throw Error.loadContentsFailed }
		
		switch kind
		{
			case .library(let mediaItems):

				for item in songs(with:mediaItems)
				{
					objects += MusicObject(with:item)
				}

			case .albumFolder(let mediaItems):
			
				let albums = Self.albums(with:mediaItems)
				
				for album in albums
				{
					containers += MusicContainer(
						identifier:"MusicSource:Album:\(album.persistentID)",
						kind:.album(album:album, mediaItems:mediaItems),
						icon:"square",
						name:album.title ?? "Album")
				}
				
			case .album(let album, let mediaItems):
			
				for item in Self.mediaItems(for:album, allMediaItems:mediaItems)
				{
					objects += MusicObject(with:item)
				}

			case .artistFolder(let mediaItems):
			
				let artists = Self.artists(with:mediaItems)
				
				for artist in artists
				{
					containers += MusicContainer(
						identifier:"MusicSource:Artist:\(artist.persistentID)",
						kind:.artist(artist:artist, mediaItems:mediaItems),
						icon:"person",
						name:artist.name ?? "Artist")
				}
				
			case .artist(let artist, let mediaItems):
			
				for item in Self.mediaItems(for:artist, allMediaItems:mediaItems)
				{
					objects += MusicObject(with:item)
				}

			case .playlistFolder(let playlists):
			
				for playlist in playlists
				{
					guard playlist.kind == .regular else { continue }
					guard !playlist.isPrimary else { continue }
					containers += Self.container(for:playlist)
				}
				
			case .playlist(let playlist):
			
				for item in playlist.items
				{
					objects += MusicObject(with:item)
				}
		}

		return (containers,objects)
	}


	class func container(for playlist:ITLibPlaylist) -> MusicContainer
	{
		MusicContainer(
			identifier:"MusicSource:Playlist:\(playlist.persistentID)",
			kind:.playlist(playlist:playlist),
			icon:"music.note.list",
			name:playlist.name)
	}
	
	
	class func albums(with mediaItems:[ITLibMediaItem]) -> [ITLibAlbum]
	{
		var albums = Set<ITLibAlbum>()
		
		for mediaItem in mediaItems
		{
			albums.insert(mediaItem.album)
		}
		
		return albums.sorted { ($0.title ?? "") < ($1.title ?? "") }
	}
	
	
	class func artists(with mediaItems:[ITLibMediaItem]) -> [ITLibArtist]
	{
		var artists = Set<ITLibArtist>()
		
		for mediaItem in mediaItems
		{
			guard let artist = mediaItem.artist else { continue }
			artists.insert(artist)
		}
		
		return artists.sorted { ($0.name ?? "") < ($1.name ?? "") }
	}
	
	
	class func songs(with mediaItems:[ITLibMediaItem]) -> [ITLibMediaItem]
	{
		mediaItems
			.filter { $0.mediaKind == .kindSong }
	}
	
	
	class func mediaItems(for album:ITLibAlbum, allMediaItems:[ITLibMediaItem]) -> [ITLibMediaItem]
	{
		allMediaItems
			.filter { $0.album == album }
			.sorted { $0.trackNumber < $1.trackNumber }
	}
	
	
	class func mediaItems(for artist:ITLibArtist, allMediaItems:[ITLibMediaItem]) -> [ITLibMediaItem]
	{
		allMediaItems
			.filter { $0.artist == artist }
	}
}


//----------------------------------------------------------------------------------------------------------------------


extension ITLibArtist
{
	override public var hash:Int
	{
		self.persistentID.hash
	}

	public static func ==(lhs:ITLibArtist, rhs:ITLibArtist) -> Bool
	{
		lhs.persistentID == rhs.persistentID
	}

	override public func isEqual(_ object:Any?) -> Bool
	{
		guard let other = object as? ITLibArtist else { return false }
		return self == other
	}
}


//----------------------------------------------------------------------------------------------------------------------


extension ITLibAlbum
{
	override public var hash:Int
	{
		self.persistentID.hash
	}
	
	public static func ==(lhs:ITLibAlbum, rhs:ITLibAlbum) -> Bool
	{
		lhs.persistentID == rhs.persistentID
	}

	override public func isEqual(_ object:Any?) -> Bool
	{
		guard let other = object as? ITLibAlbum else { return false }
		return self == other
	}
}


//----------------------------------------------------------------------------------------------------------------------
