//
//  Section.swift
//  MediaBrowserTest
//  Created by Peter Baumgartner on 04.12.21.
//

import SwiftUI


//----------------------------------------------------------------------------------------------------------------------


/// A Section is a group of sources within a library.

open class Section : ObservableObject, Identifiable
{
	/// A unique identifier for this Section
	
	public let identifier:String
	
	/// The name is optional. If set, it will be displayed in the UI.
	
	public let name:String?
	
	/// The list of Sources in this section.
	
	@Published public private(set) var sources:[Source]
	
	/// If this handler is set, a small "+" button will be displayed after the section name.
	/// The button call this handler. That way the user can add a new Source to this Section.
	
	public var addSourceHandler:((Section)->Void)? = nil
	
	// Required by the Identifiable protocol

	nonisolated public var id:String { identifier }

	
//----------------------------------------------------------------------------------------------------------------------


	/// Create a new Section with the specified name
	
	public init(identifier:String, name:String?)
	{
		self.identifier = identifier
		self.name = name
		self.sources = []
	}

	/// Loads all Sources in this Section
	
	public func load()
	{
		for source in self.sources
		{
			source.load()
		}
	}

	/// Adds the specified Source to this Section
	
	public func addSource(_ source:Source)
	{
		self.objectWillChange.send()
		self.sources.append(source)
	}


//----------------------------------------------------------------------------------------------------------------------


	public func saveState()
	{
		self.sources.forEach { $0.saveState() }
	}
	
	
	public func restoreState()
	{
		self.sources.forEach { $0.restoreState() }
	}
}


//----------------------------------------------------------------------------------------------------------------------


