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


/// A Library is the top level object in a BXMediaBrowser object graph. You can create multiple libraries for
/// different purposes, e.g. an image library, and audio library, etc.

open class Library : ObservableObject, StateSaving
{
	/// A unique identifier for this Library
	
	public let identifier:String
	
	/// A library has one or more sections, which can be named.
	
	@Published public private(set) var sections:[Section] = []
	
	/// The Objects of the currently selected Container are displayed in the ObjectView
	
	public var selectedContainer:Container?
	{
		set
		{
			BXMediaBrowser.logDataModel.debug {"\(Self.self).\(#function) = \(selection.container?.identifier ?? "nil")"}

			// Request purging of thumbnails of previously selected Container
			
			selection.container?.isSelected = false
			selection.container?.purgeCachedDataOfObjects()

			// Select new container
			
			self.objectWillChange.send()
			selection.container = newValue
			selection.container?.validateSortType()
			
			// Cancel purging if it was requested before
			
			selection.container?.isSelected = true
			selection.container?.cancelPurgeCachedDataOfObjects()
		}
		
		get
		{
			selection.container
		}
	}
	
	public let selection = Selection()
	
	/// This externally supplied handler will be called when file URLs are dropped onto a LibraryView
	
	public var didDropFileURLHandler:((URL)->Void)? = nil
	
	/// Internal helper object that coordinates library state saving
	
	internal let stateSaver = StateSaver()
	
	
//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Setup
	
	/// Create a new Library with the specified name
	
	public init(identifier:String)
	{
		BXMediaBrowser.logDataModel.verbose {"\(Self.self).\(#function) \(identifier)"}
		
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
	
	/// Inserts a new section at the specified index
	
	public func insertSection(_ section:Section, at index:Int)
	{
		self.objectWillChange.send()
		self.sections.insert(section, at:index)
	}
	
	/// Removes the specified Section
	
	public func removeSection(_ section:Section?)
	{
		guard let section = section else { return }
		self.objectWillChange.send()
		self.sections.removeAll { $0 === section }
	}
	

//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Load & Save
	
	/// Loads the contents of the library
	
	public func load(with libraryState:[String:Any]? = nil)
	{
		BXMediaBrowser.logDataModel.verbose {"\(Self.self).\(#function) \(identifier)"}

		// Restore the selectedContainer. Please note that loading the library is an async operation.
		// we do not know when the Container in question will be created. For this reason we will
		// have to check each newly created Container if it is the one in question.
		
		if let identifier = libraryState?[selectedContainerIdentifierKey] as? String
		{
			self.stateSaver.restoreSelectedContainerHandler =
			{
				[weak self] container in
				self?.restoreSelectedContainer(container, with:identifier)
			}
		}

		// Load the library. This is an async operation that may take a while.
		
		for section in sections
		{
			let key = section.stateKey
			let sectionState = libraryState?[key] as? [String:Any]
			section.load(with:sectionState, in:self)
		}
	}


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - State
	
	/// This function saves the specified state to persistent storage. The default implementation saves
	/// the state to the UserDefaults, but if this is not convenient for the host application, simply
	/// override this method in a subclass and provide your own storage mechanism.
	
	open func saveState(_ state:[String:Any])
	{
		BXMediaBrowser.logDataModel.debug {"\(Self.self).\(#function) \(identifier)"}

		UserDefaults.standard.set(state, forKey:stateKey)
	}


	/// If the specified Container is the one that was selected before (as specified by the identifier) then select it again.
	/// If the Container is not loaded yet, then it will be loaded now.
	
	public func restoreSelectedContainer(_ container:Container, with identifier:String)
	{
		guard container.library != nil && container.library == self else { return }
		guard container.identifier == identifier else { return }
		
		DispatchQueue.main.async
		{
			self.selectedContainer = container
			
			if !container.isLoading && !container.isLoaded
			{
				container.load(in:self)
			}
		}
	}
}


//----------------------------------------------------------------------------------------------------------------------
