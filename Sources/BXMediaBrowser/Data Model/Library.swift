//
//  Library.swift
//  MediaBrowserTest
//  Created by Peter Baumgartner on 04.12.21.
//

import SwiftUI


//----------------------------------------------------------------------------------------------------------------------


//	BXMediaBrowser.Library							IMBLibrary
//		[BXMediaBrowser.Section]
//			[BXMediaBrowser.Source]        			IMBParser			e.g. Lightroom, Photos, Music, Finder
//				[BXMediaBrowser.Container]			IMBNode				e.g. Album, Playlist, Folder
//					[BXMediaBrowser.Container]		IMBNode
//					[BXMediaBrowser.Object]			IMBObject			e.g. Image, Video, Audio file


//----------------------------------------------------------------------------------------------------------------------


/// A Library is the top level object in a BXMediaBrowser object graph. You can create multiple libraries for
/// different purposes, e.g. an image library, and audio library, etc.

open class Library : ObservableObject
{
	/// A unique identifier for this Library
	
	public let identifier:String
	
	/// A library has one or more sections, which can be named.
	
	@Published public private(set) var sections:[Section] = []
	
	/// The Objects of the currently selected Container are displayed in the ObjectView
	
	@Published public var selectedContainer:Container? = nil
	{
		willSet { selectedContainer?.purgeCachedDataOfObjects() }
		didSet { selectedContainer?.cancelPurgeCachedDataOfObjects() }
	}
	
	/// This property will be incremented whenever the current selectedContainer was loaded.
	/// This can trigger an update in the user interface.
	
	@Published public var didLoadSelectedContainer = 0


//----------------------------------------------------------------------------------------------------------------------


	/// Create a new Section with the specified name
	
	public init(identifier:String)
	{
		self.identifier = identifier
	}


//----------------------------------------------------------------------------------------------------------------------


	/// Adds a new section to this library
	
	public func addSection(_ section:Section)
	{
		self.objectWillChange.send()
		self.sections.append(section)
	}
	
	/// Loads the contents of the library. This essentially just passes the load command on to
	/// the sources in each section. It is up to the sources to decide how to load the library.
	
	public func load()
	{
		self.sections.forEach { $0.load() }
	}

}


//----------------------------------------------------------------------------------------------------------------------
