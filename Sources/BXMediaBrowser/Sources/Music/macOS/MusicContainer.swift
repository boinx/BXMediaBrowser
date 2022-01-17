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


public class MusicContainer : Container
{
	public enum Kind
	{
		case library(allMediaItems:[ITLibMediaItem])
		case albumFolder(allMediaItems:[ITLibMediaItem])
		case album(album:ITLibAlbum, allMediaItems:[ITLibMediaItem])
		case artistFolder(allMediaItems:[ITLibMediaItem])
		case artist(artist:ITLibArtist, allMediaItems:[ITLibMediaItem])
		case playlistFolder(playlists:[ITLibPlaylist], allPlaylists:[ITLibPlaylist])
		case playlist(playlist:ITLibPlaylist)
	}


//----------------------------------------------------------------------------------------------------------------------


 	public init(identifier:String, kind:Kind, icon:String?, name:String)
	{
		super.init(
			identifier:identifier,
			data:kind,
			icon:icon,
			name:name,
			loadHandler:Self.loadContents)

		if case .playlist(let playlist) = kind
		{
			self.observers += KVO(object:playlist, keyPath:"items")
			{
				[weak self] _,_ in
				print("MusicContainer: items has changed")
			}
		}
	}
	

	override var canExpand:Bool
	{
		guard let kind = data as? Kind else { return true }

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
	
	class func loadContents(for identifier:String, data:Any, filter:Any?) async throws -> Loader.Contents
	{
		var containers:[Container] = []
		var objects:[Object] = []
		
		guard let kind = data as? Kind else { throw Error.loadContentsFailed }
		
		switch kind
		{
			// Loads the objects (tracks) for the top-level "Library"
			
			case .library(let allMediaItems):

				for item in Self.tracks(with:allMediaItems)
				{
					if item.contains(filter)
					{
						objects += MusicObject(with:item)
					}
				}

			// Loads the sub-containers for the top-level "Albums" folder
			
			case .albumFolder(let allMediaItems):
			
				for album in Self.albums(with:allMediaItems)
				{
					containers += MusicContainer(
						identifier:"MusicSource:Album:\(album.persistentID)",
						kind:.album(album:album, allMediaItems:allMediaItems),
						icon:"square",
						name:album.title ?? "Album")
				}
			
			// Loads the sub-containers for the top-level "Artists" folder
			
			case .artistFolder(let allMediaItems):
			
				for artist in Self.artists(with:allMediaItems)
				{
					containers += MusicContainer(
						identifier:"MusicSource:Artist:\(artist.persistentID)",
						kind:.artist(artist:artist, allMediaItems:allMediaItems),
						icon:"person",
						name:artist.name ?? "Artist")
				}
				
			// Loads the sub-containers for a playlist folder
			
			case .playlistFolder(let playlists, let allPlaylists):
			
				for playlist in playlists
				{
					guard !playlist.isPrimary else { continue }
					let kind = playlist.kind
					let distinguishedKind = playlist.distinguishedKind
					
					if kind == .regular	// Accept regular user playlists
					{
						containers += Self.container(for:playlist)
					}
					else if kind == .smart && distinguishedKind == .kindNone // Accept user smart playlists
					{
						containers += Self.container(for:playlist)
					}
					else if kind == .folder	// Accept sub-folders
					{
						let childPlaylists = Self.childPlaylists(for:playlist, allPlaylists:allPlaylists)
						
						containers += MusicContainer(
							identifier:"MusicSource:Playlist:\(playlist.persistentID)",
							kind:.playlistFolder(playlists:childPlaylists, allPlaylists:allPlaylists),
							icon:"folder",
							name:playlist.name)
					}
				}
				
			// Load the objects (tracks) of an album
			
			case .album(let album, let allMediaItems):
			
				for item in Self.mediaItems(for:album, allMediaItems:allMediaItems)
				{
					if item.contains(filter)
					{
						objects += MusicObject(with:item)
					}
				}

			// Load the objects (tracks) of an artist
			
			case .artist(let artist, let allMediaItems):
			
				for item in Self.mediaItems(for:artist, allMediaItems:allMediaItems)
				{
					if item.contains(filter)
					{
						objects += MusicObject(with:item)
					}
				}

			// Load the objects (tracks) of a playlist
			
			case .playlist(let playlist):
			
				for item in playlist.items
				{
					if item.contains(filter)
					{
						objects += MusicObject(with:item)
					}
				}
		}

		return (containers,objects)
	}
}


//----------------------------------------------------------------------------------------------------------------------


extension MusicContainer
{
	/// Creates a Container for the specified playlist
	
	class func container(for playlist:ITLibPlaylist) -> MusicContainer
	{
		var icon = "music.note.list"
		
		switch playlist.kind
		{
			case .folder: icon = "folder"
			case .smart: icon = "gearshape"
			default: icon = "music.note.list"
		}
		
		return MusicContainer(
			identifier:"MusicSource:Playlist:\(playlist.persistentID)",
			kind:.playlist(playlist:playlist),
			icon:icon,
			name:playlist.name)
	}

	/// Returns an array of tracks sorted by name
	
	class func tracks(with allMediaItems:[ITLibMediaItem]) -> [ITLibMediaItem]
	{
		allMediaItems
			.sorted { $0.title < $1.title }
	}
	

	/// Returns a alphabetically sorted array of artists
	
	class func artists(with allMediaItems:[ITLibMediaItem]) -> [ITLibArtist]
	{
		let tracksByArtist = Dictionary(grouping:allMediaItems, by: { $0.artist })
		let artists = tracksByArtist.keys.compactMap { $0 }
		return artists.sorted { ($0.name ?? "") < ($1.name ?? "") }
	}
	
	
	/// Returns a alphabetically sorted array of albums
	
	class func albums(with allMediaItems:[ITLibMediaItem]) -> [ITLibAlbum]
	{
		let tracksByAlbum = Dictionary(grouping:allMediaItems, by: { $0.album })
		let albums = tracksByAlbum.keys
		return albums.sorted { ($0.title ?? "") < ($1.title ?? "") }
	}
	
	
	/// Returns an array of tracks for the specified album (sorted by track number)
	
	class func mediaItems(for album:ITLibAlbum, allMediaItems:[ITLibMediaItem]) -> [ITLibMediaItem]
	{
		allMediaItems
			.filter { $0.album == album }
			.sorted { $0.trackNumber < $1.trackNumber }
	}
	
	
	/// Returns an array of tracks for the specified artist
	
	class func mediaItems(for artist:ITLibArtist, allMediaItems:[ITLibMediaItem]) -> [ITLibMediaItem]
	{
		allMediaItems
			.filter { $0.artist == artist }
			.sorted { $0.title < $1.title }
	}
	
	
	/// Returns the array of children for the specified playlist - given the flat array of allPlaylists
	
	class func childPlaylists(for playlist:ITLibPlaylist, allPlaylists:[ITLibPlaylist]) -> [ITLibPlaylist]
	{
		allPlaylists
			.filter({ $0.parentID == playlist.persistentID })
    }
}


//----------------------------------------------------------------------------------------------------------------------


#endif
