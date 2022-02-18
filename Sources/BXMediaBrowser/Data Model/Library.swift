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
	
	@Published public var selectedContainer:Container? = nil
	{
		willSet
		{
			selectedContainer?.isSelected = false
			selectedContainer?.purgeCachedDataOfObjects()
		}
		
		didSet
		{
			selectedContainer?.isSelected = true
			selectedContainer?.validateSortType()
			selectedContainer?.cancelPurgeCachedDataOfObjects()
		}
	}
	
	/// Internal helper object that coordinates library state saving
	
	internal let stateSaver = StateSaver()
	
	/// This helper object contains properties that are needed by the UI
	
	public var uiState = UIState()
	
	
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
	

//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Load & Save
	
	/// Loads the contents of the library
	
	public func load(with libraryState:[String:Any]? = nil)
	{
		BXMediaBrowser.logDataModel.verbose {"\(Self.self).\(#function) \(identifier)"}

		// Restore the selectedContainer. Please note that loading the library is an async operation.
		// we do not know when the Container in question will be created. For this reason we will
		// listen to the Container.didCreateNotification and check if the identifier matches the one
		// we are interested in. If yes, then select and load this container.
		
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
		}

		// Load the library. This is an async operation that may take a while.
		
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
		BXMediaBrowser.logDataModel.debug {"\(Self.self).\(#function) \(identifier)"}

		UserDefaults.standard.set(state, forKey:stateKey)
	}

}


//----------------------------------------------------------------------------------------------------------------------
