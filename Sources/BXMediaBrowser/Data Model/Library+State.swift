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


import BXSwiftUtils
import Combine
import Foundation


//----------------------------------------------------------------------------------------------------------------------


extension Library
{
	/// This helper object is responsible for coalescing (debouncing) requests to save the Library state.
	/// That way unnecessary duplicate work is avoided.
	
	class StateSaver
	{
		/// This externally supplied closure performs the actual work of saving the state
		
		public var saveStateHandler:(()->Void)? = nil
		
		/// This externally supplied closure is used to restore the selected Container
		
		public var restoreSelectedContainerHandler:((Container)->Void)? = nil
		
		/// Incrementing this counter will cause the action closure to be called
		
		@Published internal var requestCounter = 0
	
		/// Reference to the Combine debouncing pipeline
		
		private var observers:[Any] = []
		
		/// Setup the debouncing pipeline
		
		init()
		{
			self.observers += self.$requestCounter
				.debounce(for:0.1, scheduler:RunLoop.main)
				.sink
				{
					[weak self] _ in self?.saveStateHandler?()
				}
		}
		
		/// Calling this function will cause the state saving action closure to be called shortly.
		
		func request()
		{
			self.requestCounter += 1
		}
	}


//----------------------------------------------------------------------------------------------------------------------


	/// Calling this function causes the state of this Library to be saved to persistent storage. Please note
	/// that multiple consecutive calls of this function will be coalesced (debounced) so that the heavy duty
	/// work is only performed once (per debounce interval).
	
	public func saveState()
	{
		self.stateSaver.request()
	}
	
	
	// Since getting the state is an async function that accesses @MainActor properties, this work has to be
	// wrapped in a Task.
	
	internal func asyncSaveState()
	{
		Task
		{
			BXMediaBrowser.logDataModel.debug {"\(Self.self).\(#function) \(identifier)"}
			let state = await self.state()
			self.saveState(state)
		}
	}
	
	/// Recursively walks through the data model tree and gathers the current state info. Since this
	/// operation is accessing async properties, this function is also async and can only be called
	/// from a Task or another async function.
	
	public func state() async -> [String:Any]
	{
		var state:[String:Any] = [:]
		
		for section in self.sections
		{
			let key = section.stateKey
			let value = await section.state()
			state[key] = value
		}
		
		state[selectedContainerIdentifierKey] = self.selectedContainer?.identifier
		
		return state
	}


	/// This key can be used to safely access state info in dictionaries or UserDefaults
	
	public var stateKey:String
	{
		"BXMediaBrowser.Library.\(identifier)".replacingOccurrences(of:".", with:"-")
	}

	/// The key for accessing the identifier of the selected Container
	
	public var selectedContainerIdentifierKey:String
	{
		"selectedContainerIdentifier"
	}

	/// The key for accessing the thumbnailScale
	
	public var thumbnailScaleKey:String
	{
		"thumbnailScale"
	}
}


//----------------------------------------------------------------------------------------------------------------------
