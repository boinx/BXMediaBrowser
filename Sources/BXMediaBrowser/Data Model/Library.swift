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

open class Library : ObservableObject, StateSaving
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
	
	/// Internal helper object that coordinates library state saving
	
	internal let stateSaver = StateSaver()
	
	
//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Setup
	
	/// Create a new Library with the specified name
	
	public init(identifier:String)
	{
		self.identifier = identifier

		self.stateSaver.saveStateHandler =
		{
			[weak self] in self?.asyncSaveState()
		}
	}


	/// Adds a new section to this library
	
	public func addSection(_ section:Section)
	{
		self.objectWillChange.send()
		self.sections.append(section)
	}
	

//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Load & Save
	
	/// Loads the contents of the library. This essentially just passes the load command on to
	/// the sources in each section. It is up to the sources to decide how to load the library.
	
	public func load(with libraryState:[String:Any]? = nil)
	{
		// Restore the selectedContainer
		
		if let identifier = libraryState?[selectedContainerIdentifierKey] as? String
		{
			self.stateSaver.restoreSelectedContainerHandler =
			{
				[weak self] container in
				guard let self = self else { return }
				guard container.identifier == identifier else { return }
				
				DispatchQueue.main.async
				{
					self.selectedContainer = container
					container.load()
				}
			}
			
//			self.selectContainer(with:identifier)
		}

		// Load all sections
		
		for section in sections
		{
			let key = section.stateKey
			let sectionState = libraryState?[key] as? [String:Any]
			section.load(with:sectionState)
		}
	}


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - State
	
	/// This function saves the specified state to persistent storage. The default implementation saves
	/// the state to the UserDefaults, but if this is not convenient for the host application, simply
	/// override this method in a subclass and provide your own storage mechanism.
	
	open func saveState(_ state:[String:Any])
	{
		Swift.print("\(Self.self).\(#function)")
		UserDefaults.standard.set(state, forKey:stateKey)
	}

}


//----------------------------------------------------------------------------------------------------------------------
