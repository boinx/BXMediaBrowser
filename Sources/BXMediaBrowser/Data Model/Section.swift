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


