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

import BXSwiftUtils
import iTunesLibrary


//----------------------------------------------------------------------------------------------------------------------


public class MusicContainer : Container
{
	/// The data property is stored via a enum that is carrying associated data
	
	public enum MusicData
	{
		case library(allMediaItems:[ITLibMediaItem])
		case albumFolder(allMediaItems:[ITLibMediaItem])
		case artistFolder(allMediaItems:[ITLibMediaItem])
		case playlistFolder(playlists:[ITLibPlaylist], allPlaylists:[ITLibPlaylist])
		case album(album:ITLibAlbum, allMediaItems:[ITLibMediaItem])
		case artist(artist:ITLibArtist, allMediaItems:[ITLibMediaItem])
		case playlist(playlist:ITLibPlaylist)
	}


//----------------------------------------------------------------------------------------------------------------------


	/// Creates a new MusicContainer. The data argument carries essential information about this Container
	
 	public init(identifier:String, icon:String?, name:String, data:MusicData)
	{
		super.init(
			identifier:identifier,
			icon:icon,
			name:name,
			data:data,
			filter:MusicFilter(),
			loadHandler:Self.loadContents)
	}
	

	/// Returns true if this Container can be expanded. Depends on the type of Container.
	
	override var canExpand:Bool
	{
		guard let musicData = data as? MusicData else { return true }

		switch musicData
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
		
		guard let musicData = data as? MusicData else { throw Error.loadContentsFailed }
		guard let musicFilter = filter as? MusicFilter else { throw Error.loadContentsFailed }
		
		switch musicData
		{
			// Loads the objects (tracks) for the top-level "Library"
			
			case .library(let allMediaItems):

				for item in Self.tracks(with:allMediaItems)
				{
					if item.contains(filter)
					{
						objects += MusicSource.makeMusicObject(with:item)
					}
				}

			// Loads the sub-containers for the top-level "Albums" folder
			
			case .albumFolder(let allMediaItems):
			
				for album in Self.albums(with:allMediaItems)
				{
					containers += MusicSource.makeMusicContainer(
						identifier:"MusicSource:Album:\(album.persistentID)",
						icon:"square",
						name:album.title ?? "Album",
						data:.album(album:album, allMediaItems:allMediaItems),
						allowedSortKinds:[.artist,.genre,.duration])
				}
			
			// Loads the sub-containers for the top-level "Artists" folder
			
			case .artistFolder(let allMediaItems):
			
				for artist in Self.artists(with:allMediaItems)
				{
					containers += MusicSource.makeMusicContainer(
						identifier:"MusicSource:Artist:\(artist.persistentID)",
						icon:"person",
						name:artist.name ?? "Artist",
						data:.artist(artist:artist, allMediaItems:allMediaItems),
						allowedSortKinds:[.album,.genre,.duration])
				}
				
			// Loads the sub-containers for a playlist folder
			
			case .playlistFolder(let playlists, let allPlaylists):
			
				for playlist in playlists
				{
					if #available(macOS 12,*)
					{
						guard !playlist.isPrimary else { continue }
					}
					else
					{
						guard !playlist.isMaster else { continue }
					}
					
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
						
						containers += MusicSource.makeMusicContainer(
								identifier:"MusicSource:Playlist:\(playlist.persistentID)",
								icon:"folder",
								name:playlist.name,
								data:.playlistFolder(playlists:childPlaylists, allPlaylists:allPlaylists),
								allowedSortKinds:[])
					}
				}
				
			// Load the objects (tracks) of an album
			
			case .album(let album, let allMediaItems):
			
				for item in Self.mediaItems(for:album, allMediaItems:allMediaItems)
				{
					if item.contains(filter)
					{
						objects += MusicSource.makeMusicObject(with:item)
					}
				}

			// Load the objects (tracks) of an artist
			
			case .artist(let artist, let allMediaItems):
			
				for item in Self.mediaItems(for:artist, allMediaItems:allMediaItems)
				{
					if item.contains(filter)
					{
						objects += MusicSource.makeMusicObject(with:item)
					}
				}

			// Load the objects (tracks) of a playlist
			
			case .playlist(let playlist):
			
				for item in playlist.items
				{
					if item.contains(filter)
					{
						objects += MusicSource.makeMusicObject(with:item)
					}
				}
		}

		// Sort according to specified sort order
		
		let comparator = SortController.shared.currentComparator
		objects.sort(by:comparator)
		
		// Return contents
		
		return (containers,objects)
	}


	/// Loads this Container again if it was loaded before

	func reload() async
	{
		if await self.isLoaded
		{
			self.load()
		}
	}


    @MainActor override var localizedObjectCount:String
    {
		let n = self.objects.count
		let str = n.localizedFilesString
		return str
    }


	/// This property determines in which group the shared sort parameters are stored
	
	override open var sortGroupKey:String { "MusicContainer" }
	
	/// Returns the list of allowed sort Kinds for this Container
		
	override open var allowedSortKinds:[SortController.Kind] { _allowedSortKinds }
	
	internal var _allowedSortKinds:[SortController.Kind] = [.artist,.album,.genre,.duration]
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
		
		return MusicSource.makeMusicContainer(
			identifier:"MusicSource:Playlist:\(playlist.persistentID)",
			icon:icon,
			name:playlist.name,
			data:.playlist(playlist:playlist),
			allowedSortKinds:[])
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
		let tracks = allMediaItems.filter
		{
			(track:ITLibMediaItem)->Bool in
			guard let name = track.artist?.name else { return false }
			return !name.isEmpty
		}
		
		let tracksByArtist = Dictionary(grouping:tracks, by:{ $0.artist })
		let artists = tracksByArtist.keys.compactMap { $0 }
		return artists.sorted { ($0.name ?? "") < ($1.name ?? "") }
	}
	
	
	/// Returns a alphabetically sorted array of albums
	
	class func albums(with allMediaItems:[ITLibMediaItem]) -> [ITLibAlbum]
	{
		let tracks = allMediaItems.filter
		{
			(track:ITLibMediaItem)->Bool in
			guard let title = track.album.title else { return false }
			return !title.isEmpty
		}
		
		let tracksByAlbum = Dictionary(grouping:tracks, by:{ $0.album })
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
