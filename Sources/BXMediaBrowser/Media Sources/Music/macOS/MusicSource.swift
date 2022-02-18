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
import Foundation
import AppKit


//----------------------------------------------------------------------------------------------------------------------


public class MusicSource : Source, AccessControl
{
	/// The unique identifier of this source must always remain the same. Do not change this
	/// identifier, even if the class name changes due to refactoring, because the identifier
	/// might be stored in a preferences file or user documents.
	
	static let identifier = "MusicSource:"
	
	// Get icon of Music.app
	
	static let icon = NSImage.icon(for:"com.apple.Music")?.CGImage


//----------------------------------------------------------------------------------------------------------------------


	/// Reference to the Music library
	
	static var library:ITLibrary? = nil
	
	/// The list of allowed media kinds. This can be used to e.g. only display audio or only videos
	
	static var allowedMediaKinds:[ITLibMediaItemMediaKind] = [.kindSong]
	
	
//----------------------------------------------------------------------------------------------------------------------


	/// The known Container are stored by identifier, so that they can be reused
	
	static var cachedContainers:[String:MusicContainer] = [:]

	/// The known Objects are stored by identifier, so that they can be reused
	
	static var cachedObjects:[String:MusicObject] = [:]

	/// Internal observers and subscriptions
	
	private var observers:[Any] = []
	
	
//----------------------------------------------------------------------------------------------------------------------


	/// Creates a new Source for local file system directories
	
	public init(allowedMediaKinds:[ITLibMediaItemMediaKind] = [.kindSong])
	{
		MusicSource.log.verbose {"\(Self.self).\(#function) \(Self.identifier)"}

		// Configure the Source
		
		super.init(identifier:Self.identifier, icon:Self.icon, name:"Music", filter:MusicFilter())
		
		self.loader = Loader(loadHandler:Self.loadContainers)
		
		// Get reference to Music library
		
		Self.library = try? ITLibrary(apiVersion:"1.1", options:.lazyLoadData)
		Self.allowedMediaKinds = allowedMediaKinds
		
		// Setup observers to detect changes - well not really, since the API doesn't support it. Instead we "fake" it
		// by simply reloading EVERYTHING when the application is brought to the foreground again. In this scenario we
		// simply assume that the user went to the Music.app and made some changes.
		
		self.observers += NotificationCenter.default.publisher(for:NSApplication.didBecomeActiveNotification, object:nil).sink
		{
			[weak self] _ in self?.reload()
		}

		// Register sorting Kinds
		
		SortController.shared.register(
			kind: .artist,
			comparator: SortController.compareArtist)
		
		SortController.shared.register(
			kind: .album,
			comparator: SortController.compareAlbum)
		
		SortController.shared.register(
			kind: .genre,
			comparator: SortController.compareGenre)
		
		SortController.shared.register(
			kind: .duration,
			comparator: SortController.compareDuration)
	}


//----------------------------------------------------------------------------------------------------------------------


	/// Returns true if we have access to the Photos library
	
	public var hasAccess:Bool
	{
		true
	}
	
	/// Calling this function prompts the user to grant access to the Photos library
	
	public func grantAccess(_ completionHandler:@escaping (Bool)->Void)
	{

	}


//----------------------------------------------------------------------------------------------------------------------


	/// This function is called the the app is brought to the foreground again in this case the whole
	/// Source will be reloaded with updated data from the iTunesLibrary framework, while preserving
	/// the expanded state of each Container.
	
	private func reload()
	{
		Task
		{
			// Only reload if it was already loaded before
			
			guard await self.isLoaded else { return }
			
			MusicSource.log.debug {"\(Self.self).\(#function) \(Self.identifier)"}
			
			// First reload the ITLibrary. Unfortunately this has to be done manually and it is monolithic.
			// We cannot detect granular changes to individual playlists.

			Self.library?.reloadData()

			// Get the current expanded state of all Containers
			
			let state = await self.state()
			
			// Now reload the complete Source and all its Containers, but try to preserve the existing state
			
			await MainActor.run
			{
				self.load(with:state)
			}
		}
	}


	/// Loads the top-level containers of this source.
	///
	/// Subclasses can override this function, e.g. to load top level folder from the preferences file
	
	private class func loadContainers(with sourceState:[String:Any]? = nil, filter:Object.Filter) async throws -> [Container]
	{
		MusicSource.log.debug {"\(Self.self).\(#function) \(identifier)"}

		var containers:[Container] = []
		
		guard let library = Self.library else { return containers }
		let allMediaItems = library.allMediaItems.filter { Self.allowedMediaKinds.contains($0.mediaKind) }
		let allPlaylists = library.allPlaylists
		let topLevelPlaylists = allPlaylists.filter { $0.parentID == nil }
		
		containers += Self.makeMusicContainer(identifier:"MusicSource:Songs", icon:"music.note", name:"Songs", data:MusicContainer.MusicData.library(allMediaItems:allMediaItems), allowedSortKinds:[.never,.artist,.album,.genre,.duration])

		containers += Self.makeMusicContainer(identifier:"MusicSource:Artists", icon:"music.mic", name:"Artists", data:MusicContainer.MusicData.artistFolder(allMediaItems:allMediaItems), allowedSortKinds:[.never,.album,.genre,.duration])

		containers += Self.makeMusicContainer(identifier:"MusicSource:Albums", icon:"square.stack", name:"Albums", data:MusicContainer.MusicData.albumFolder(allMediaItems:allMediaItems), allowedSortKinds:[.never,.artist,.genre,.duration])

		containers += Self.makeMusicContainer(identifier:"MusicSource:Genres", icon:"guitars", name:"Genres", data:MusicContainer.MusicData.genreFolder(allMediaItems:allMediaItems), allowedSortKinds:[.never,.artist,.album,.duration])

		containers += Self.makeMusicContainer(identifier:"MusicSource:Playlists", icon:"music.note.list", name:"Playlists", data:MusicContainer.MusicData.playlistFolder(playlists:topLevelPlaylists, allPlaylists:allPlaylists), allowedSortKinds:[])

		return containers
	}


//----------------------------------------------------------------------------------------------------------------------


	/// Tries to reuse an existing Container from the cache before creating a new one and storing it in the cache.
	
	class func makeMusicContainer(identifier:String, icon:String?, name:String, data:MusicContainer.MusicData, allowedSortKinds:[SortController.Kind]) -> MusicContainer
	{
		MusicSource.log.verbose {"\(Self.self).\(#function) \(identifier)"}

		if let container = Self.cachedContainers[identifier]
		{
			container.data = data

			Task
			{
				await container.reload()
			}
			
			return container
		}
		else
		{
			let container = MusicContainer(
				identifier:identifier,
				icon:icon,
				name:name,
				data:data)
			
			container._allowedSortKinds = allowedSortKinds
			
			Self.cachedContainers[identifier] = container

			return container
		}
	}


	/// Tries to reuse an existing Object from the cache before creating a new one and storing it in the cache.
	
	class func makeMusicObject(with item:ITLibMediaItem) -> MusicObject
	{
		let identifier = "MusicSource:ITLibMediaItem:\(item.persistentID)"

		if let object = Self.cachedObjects[identifier]
		{
			return object
		}
		else
		{
			let object = MusicObject(with:item)
			Self.cachedObjects[identifier] = object
			return object
		}
	}
	
	
//----------------------------------------------------------------------------------------------------------------------


	public static var log:BXLogger =
	{
		()->BXLogger in
		
		var logger = BXLogger()

		logger.addDestination
		{
			(level:BXLogger.Level,string:String)->() in
			BXMediaBrowser.log.print(level:level, force:true) { string }
		}
		
		return logger
	}()
}
	
	
//----------------------------------------------------------------------------------------------------------------------


extension SortController.Kind
{
	public static let never = "never"
}


extension SortController
{
	public static func compareNever(_ object1:Object,_ object2:Object) -> Bool
	{
		false
	}
}


//----------------------------------------------------------------------------------------------------------------------


extension SortController.Kind
{
	public static let artist = "artist"
}


extension SortController
{
	public static func compareArtist(_ object1:Object,_ object2:Object) -> Bool
	{
		guard let item1 = (object1 as? MusicObject)?.data as? ITLibMediaItem else { return false }
		guard let item2 = (object2 as? MusicObject)?.data as? ITLibMediaItem else { return false }
		let artist1 = item1.artist?.name ?? ""
		let artist2 = item2.artist?.name ?? ""
		return artist1 < artist2
	}
}


//----------------------------------------------------------------------------------------------------------------------


extension SortController.Kind
{
	public static let album = "album"
}


extension SortController
{
	public static func compareAlbum(_ object1:Object,_ object2:Object) -> Bool
	{
		guard let item1 = (object1 as? MusicObject)?.data as? ITLibMediaItem else { return false }
		guard let item2 = (object2 as? MusicObject)?.data as? ITLibMediaItem else { return false }
		let album1 = item1.album.title ?? ""
		let album2 = item2.album.title ?? ""
		return album1 < album2
	}
}


//----------------------------------------------------------------------------------------------------------------------


extension SortController.Kind
{
	public static let genre = "genre"
}


extension SortController
{
	public static func compareGenre(_ object1:Object,_ object2:Object) -> Bool
	{
		guard let item1 = (object1 as? MusicObject)?.data as? ITLibMediaItem else { return false }
		guard let item2 = (object2 as? MusicObject)?.data as? ITLibMediaItem else { return false }
		let genre1 = item1.genre
		let genre2 = item2.genre
		return genre1 < genre2
	}
}


//----------------------------------------------------------------------------------------------------------------------


extension SortController.Kind
{
	public static let duration = "duration"
}


extension SortController
{
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


#endif
