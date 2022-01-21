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
import AppKit
import Foundation


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
	
	let library:ITLibrary?
	
	/// The list of allowed media kinds. This can be used to e.g. only display audio or only videos
	
	let allowedMediaKinds:[ITLibMediaItemMediaKind]
	
	/// Internal observers and subscriptions
	
	private var observers:[Any] = []
	
//	var folderObserver:FolderObserver? = nil
	
	
//----------------------------------------------------------------------------------------------------------------------


	/// Creates a new Source for local file system directories
	
	public init(allowedMediaKinds:[ITLibMediaItemMediaKind] = [.kindSong])
	{
		self.allowedMediaKinds = allowedMediaKinds
		
		// Get reference to Music library
		
		self.library = try? ITLibrary(apiVersion:"1.1", options:.lazyLoadData)
		
		// Configure the Source
		
		super.init(identifier:Self.identifier, icon:Self.icon, name:"Music")
		
		self.loader = Loader(identifier:self.identifier, loadHandler:self.loadContainers)

		// Setup observers to detect changes
		
		if let library = self.library
		{
			let url = library.mediaFolderLocation
			print("MusicSource: url = \(url)")
			
			self.observers += NotificationCenter.default.publisher(for:NSApplication.didBecomeActiveNotification, object:nil).sink
			{
				[weak self] _ in self?.reload()
			}
			
			self.observers += KVO(object:library, keyPath:"allMediaItems")
			{
				[weak self] _,_ in
				print("MusicSource: library has changed")
			}

			self.observers += KVO(object:library, keyPath:"allPlaylists")
			{
				[weak self] _,_ in
				print("MusicSource: library has changed")
			}

		}
		
//		// Request access to photo library if not available yet. Reload all containers once access has been granted.
//
//		if !self.hasAccess
//		{
//			self.grantAccess()
//			{
//				[weak self] isGranted in
//				if isGranted { self?.load() }
//			}
//		}
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


	/// Loads the top-level containers of this source.
	///
	/// Subclasses can override this function, e.g. to load top level folder from the preferences file
	
	private func loadContainers(with sourceState:[String:Any]? = nil) async throws -> [Container]
	{
		Swift.print("Loading \"\(name)\" - \(identifier)")

		var containers:[Container] = []
		
		guard let library = self.library else { return containers }
		let allMediaItems = library.allMediaItems.filter { self.allowedMediaKinds.contains($0.mediaKind) }
		let allPlaylists = library.allPlaylists
		let topLevelPlaylists = allPlaylists.filter { $0.parentID == nil }

		containers += MusicContainer(identifier:"MusicSource:Songs", kind:.library(allMediaItems:allMediaItems), icon:"music.note", name:"Songs")
		
		containers += MusicContainer(identifier:"MusicSource:Artists", kind:.artistFolder(allMediaItems:allMediaItems), icon:"music.mic", name:"Artists")

		containers += MusicContainer(identifier:"MusicSource:Albums", kind:.albumFolder(allMediaItems:allMediaItems), icon:"square.stack", name:"Albums")

		containers += MusicContainer(identifier:"MusicSource:Playlists", kind:.playlistFolder(playlists:topLevelPlaylists, allPlaylists:allPlaylists), icon:"music.note.list", name:"Playlists")
		
		return containers
	}
	
	
	private func reload()
	{
		print("\(Self.self).\(#function)")

		Task
		{
			// First reload the ITLibrary. Unfortunately this has to be done manually and it is monolithic.
			// We cannot detect granular changes to individual playlists.

			self.library?.reloadData()

			// Get the current expanded state of all Containers
			
			let state = await self.state()
			
			// Now reload the complete Source and all its Containers, but try to preserve the existing state
			
			await MainActor.run
			{
				self.load(with:state)
			}
		}
	}
}


//----------------------------------------------------------------------------------------------------------------------


#endif
