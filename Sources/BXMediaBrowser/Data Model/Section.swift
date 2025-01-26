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


/// A Section is a group of sources within a library.

open class Section : ObservableObject, Identifiable, StateSaving
{
	/// Reference to the owning library
	
	public private(set) weak var library:Library? = nil

	/// A unique identifier for this Section
	
	public let identifier:String
	
	/// The name is optional. If set, it will be displayed in the UI.
	
	public let name:String?
	
	/// The list of Sources in this section.
	
	@Published public private(set) var sources:[Source]
	
	/// Returns true if this source is expanded in the view
	
	@Published public var isExpanded = true
	
	/// If this handler is set, a small "+" button will be displayed after the section name.
	/// The button call this handler. That way the user can add a new Source to this Section.
	
	public var addSourceHandler:((Section)->Void)? = nil

	
//----------------------------------------------------------------------------------------------------------------------


	/// Create a new Section with the specified name
	
	public init(library:Library?, identifier:String, name:String?)
	{
		self.library = library
		self.identifier = identifier
		self.name = name
		self.sources = []
	}

	// Required by the Identifiable protocol

	nonisolated public var id:String { identifier }


//----------------------------------------------------------------------------------------------------------------------


	/// Loads all Sources in this Section
	
	public func load(with sectionState:[String:Any]? = nil, in library:Library)
	{
		if let isExpanded = sectionState?[isExpandedKey] as? Bool
		{
			self.isExpanded = isExpanded
		}

		for source in self.sources
		{
			let key = source.stateKey
			let sourceState = sectionState?[key] as? [String:Any]
			source.load(with:sourceState, in:library)
		}
	}

	/// Adds the specified Source to this Section
	
	public func addSource(_ source:Source)
	{
		self.objectWillChange.send()
		self.sources.append(source)
	}


//----------------------------------------------------------------------------------------------------------------------


	public func state() async -> [String:Any]
	{
		var state:[String:Any] = [:]
		state[isExpandedKey] = self.isExpanded

		for source in self.sources
		{
			let key = source.stateKey
			let value = await source.state()
			state[key] = value
		}
		
		return state
	}
	
	internal var stateKey:String
	{
		"\(identifier)".replacingOccurrences(of:".", with:"-")
	}

	/// The key of the isExpanded state inside the state dictionary

	internal var isExpandedKey:String
	{
		"isExpanded"
	}
}


//----------------------------------------------------------------------------------------------------------------------


