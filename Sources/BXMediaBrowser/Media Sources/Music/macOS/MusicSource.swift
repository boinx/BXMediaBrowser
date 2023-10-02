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
	
	static var cachedContainers = ThreadsafeDictionary<String,MusicContainer>()

	/// The known Objects are stored by identifier, so that they can be reused
	
	static var cachedObjects = ThreadsafeDictionary<String,MusicObject>()

	/// Internal observers and subscriptions
	
	private var observers:[Any] = []
	
	
//----------------------------------------------------------------------------------------------------------------------


	/// Creates a new Source for local file system directories
	
	public init(allowedMediaKinds:[ITLibMediaItemMediaKind] = [.kindSong])
	{
		MusicSource.log.verbose {"\(Self.self).\(#function) \(Self.identifier)"}

		// Instantiate the shared MusicApp
		
		_ = MusicApp.shared
		
		// Configure the Source

		let name = NSLocalizedString("Music", tableName:"Music", bundle:.BXMediaBrowser, comment:"Source Name")

//		if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier:"com.apple.Music")
//		{
//			name = FileManager.default.displayName(atPath:url.path)
//		}
		
		super.init(identifier:Self.identifier, icon:Self.icon, name:name, filter:MusicFilter())
		
		self.loader = Loader(loadHandler:Self.loadContainers)
		
		// Get reference to Music library
		
		Self.library = try? ITLibrary(apiVersion:"1.1", options:.lazyLoadData)
		Self.allowedMediaKinds = allowedMediaKinds
		
		// Store reference to this source
		
		MusicApp.shared.source = self

		// Setup observers to detect changes - well not really, since the API doesn't support it. Instead we "fake" it
		// by simply reloading EVERYTHING when the application is brought to the foreground again. In this scenario we
		// simply assume that the user went to the Music.app and made some changes.
		
		self.observers += NotificationCenter.default.publisher(for:NSApplication.didBecomeActiveNotification, object:nil).sink
		{
			[weak self] _ in self?.reload()
		}
	}


//----------------------------------------------------------------------------------------------------------------------


	// MARK: -
	
	/// This function is called the the app is brought to the foreground again in this case the whole
	/// Source will be reloaded with updated data from the iTunesLibrary framework, while preserving
	/// the expanded state of each Container.
	
	private func reload()
	{
		Task
		{
			try await Tasks.canContinue()

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
		try await Tasks.canContinue()
		
		MusicSource.log.debug {"\(Self.self).\(#function) \(identifier)"}

		guard let library = Self.library else { throw Container.Error.loadContentsFailed }
		guard let filter = filter as? MusicFilter else { throw Container.Error.loadContentsFailed }
		
		let allMediaItems = library.allMediaItems.filter { Self.allowedMediaKinds.contains($0.mediaKind) }
		let allPlaylists = library.allPlaylists
		let topLevelPlaylists = allPlaylists.filter { $0.parentID == nil }
		var containers:[Container] = []
		
		// Restore read access rights to rootFolder (if it has been previously granted by the user)
		
		if let bookmark = sourceState?[Self.rootFolderBookmarkKey] as? Data,
		   let rootFolderURL = URL(with:bookmark),
		   rootFolderURL.exists && rootFolderURL.isDirectory,
		   rootFolderURL.startAccessingSecurityScopedResource()
		{
			await MainActor.run
			{
				MusicApp.shared.rootFolderURL = rootFolderURL
				MusicApp.shared.grantedFolderURL = rootFolderURL
			}
		}
		
		// Create top-level Containers
		
		try await Tasks.canContinue()
		
		let songs = NSLocalizedString("Songs", tableName:"Music", bundle:.BXMediaBrowser, comment:"Container Name")
		containers += Self.makeMusicContainer(identifier:"MusicSource:Songs", icon:"music.note", name:songs, data:MusicContainer.MusicData.library(allMediaItems:allMediaItems), filter:filter, allowedSortTypes:[.never,.artist,.album,.genre,.duration])

		try await Tasks.canContinue()
		
		let artists = NSLocalizedString("Artists", tableName:"Music", bundle:.BXMediaBrowser, comment:"Container Name")
		containers += Self.makeMusicContainer(identifier:"MusicSource:Artists", icon:"music.mic", name:artists, data:MusicContainer.MusicData.artistFolder(allMediaItems:allMediaItems), filter:filter, allowedSortTypes:[.never,.album,.genre,.duration])

		try await Tasks.canContinue()
		
		let albums = NSLocalizedString("Albums", tableName:"Music", bundle:.BXMediaBrowser, comment:"Container Name")
		containers += Self.makeMusicContainer(identifier:"MusicSource:Albums", icon:"square.stack", name:albums, data:MusicContainer.MusicData.albumFolder(allMediaItems:allMediaItems), filter:filter, allowedSortTypes:[.never,.artist,.genre,.duration])

		try await Tasks.canContinue()
		
		let genres = NSLocalizedString("Genres", tableName:"Music", bundle:.BXMediaBrowser, comment:"Container Name")
		containers += Self.makeMusicContainer(identifier:"MusicSource:Genres", icon:"guitars", name:genres, data:MusicContainer.MusicData.genreFolder(allMediaItems:allMediaItems), filter:filter, allowedSortTypes:[.never,.artist,.album,.duration])

		try await Tasks.canContinue()
		
		let playlists = NSLocalizedString("Playlists", tableName:"Music", bundle:.BXMediaBrowser, comment:"Container Name")
		containers += Self.makeMusicContainer(identifier:"MusicSource:Playlists", icon:"music.note.list", name:playlists, data:MusicContainer.MusicData.playlistFolder(playlists:topLevelPlaylists, allPlaylists:allPlaylists), filter:filter, allowedSortTypes:[])

		return containers
	}


//----------------------------------------------------------------------------------------------------------------------


	/// Tries to reuse an existing Container from the cache before creating a new one and storing it in the cache.
	
	class func makeMusicContainer(identifier:String, icon:String?, name:String, data:MusicContainer.MusicData, filter:MusicFilter, allowedSortTypes:[Object.Filter.SortType]) -> MusicContainer
	{
		MusicSource.log.verbose {"\(Self.self).\(#function) \(identifier)"}

		if let container = Self.cachedContainers[identifier]
		{
			synchronized(container)
			{
				container.data = data

				Task
				{
					await container.reload()
				}
			}
			
			return container
		}
		else
		{
			let container = MusicContainer(
				identifier:identifier,
				icon:icon,
				name:name,
				data:data,
				filter:filter)
			
			container._allowedSortTypes = allowedSortTypes
			
			Self.cachedContainers[identifier] = container

			return container
		}
	}


	/// Returns an Object for the specified ITLibMediaItem. Tries to reuse an existing Object from the cache
	/// before creating a new one and storing it in the cache.
	
	class func makeMusicObject(with item:ITLibMediaItem) -> MusicObject?
	{
		if Config.DRMProtectedFile.isVisible == false && item.isDRMProtected
		{
			return nil
		}
		
		let identifier = objectIdentifier(with:item)

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
	
	class func objectIdentifier(with item:ITLibMediaItem) -> String
	{
		"MusicSource:ITLibMediaItem:\(item.persistentID)"
	}
	
	
//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Access Rights
	
	@MainActor public func grantAccess(_ completionHandler:@escaping (Bool)->Void = { _ in })
	{
		if let url = MusicApp.shared.rootFolderURL
		{
			MusicSource.log.warning {"\(Self.self).\(#function) rootFolder = \(url.path)"}
			
			MusicApp.shared.requestReadAccessRights(for:url)
			
			if url.isReadable
			{
				MusicApp.shared.isReadable = true
			}
		}
		
		completionHandler(hasAccess)
	}


	@MainActor public func revokeAccess(_ completionHandler:@escaping (Bool)->Void = { _ in })
	{
		completionHandler(hasAccess)
	}
	
	
	@MainActor public var hasAccess:Bool
	{
		MusicApp.shared.isReadable
	}
	
	
//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Persistence
	
	override public func state() async -> [String:Any]
	{
		var state = await super.state()
		
		if let url = MusicApp.shared.grantedFolderURL, let bookmark = try? url.bookmarkData()
		{
			state[Self.rootFolderBookmarkKey] = bookmark
		}

		return state
	}

	internal static var rootFolderBookmarkKey:String { "rootFolderBookmark" }


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Debugging
	
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


#endif
