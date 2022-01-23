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


open class Source : ObservableObject, Identifiable, StateSaving
{
	public let identifier:String
	public let icon:CGImage?
	public let name:String
	public var loader:Loader! = nil
	
	/// The list of top-level containers
	
	@MainActor @Published public private(set) var containers:[Container] = []
	
	/// Returns true if this container is currently being loaded
	
	@MainActor @Published public private(set) var isLoading = false
		
	/// Returns true if this source has been loaded (at least once)
	
	@MainActor @Published public private(set) var isLoaded = false
	
	/// Returns true if this source is expanded in the view
	
	@Published public var isExpanded = false
	
 	/// The currently running Task for loading the top-level containers
	
	private var loadTask:Task<Void,Never>? = nil


//----------------------------------------------------------------------------------------------------------------------


	// MARK: -
	
	/// Creates a Source with the specified identifier and name
	
	public init(identifier:String, icon:CGImage? = nil, name:String)
	{
		self.identifier = identifier
		self.icon = icon
		self.name = name
	}

	// Required by the Identifiable protocol

	nonisolated public var id:String { identifier }


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Loading
	
	/// Loads the top-level containers of this source. If a previous load is still in progress it is cancelled,
	/// so that the new load can be started sooner.
	
	public func load(with sourceState:[String:Any]? = nil)
	{
//		Swift.print("Loading \"\(name)\" - \(identifier)")

		self.loadTask?.cancel()
		self.loadTask = nil
		
		self.loadTask = Task
		{
			do
			{
				// Show spinning wheel
				
				await MainActor.run
				{
					self.isLoading = true
				}

				// Get new list of containers
				
				let containers = try await self.loader.containers(with:sourceState)
//				let names = containers.map { $0.name }.joined(separator:", ")
//				Swift.print("    containers = \(names)")

				let isExpanded = sourceState?[isExpandedKey] as? Bool ?? false

				// Assign result in main thread
				
				await MainActor.run
				{
					self.containers = containers
					self.isExpanded = isExpanded
					
					// Restore isExpanded state of containers
					
					for container in containers
					{
						let containerState = sourceState?[container.stateKey] as? [String:Any] 
						let isExpanded = containerState?[container.isExpandedKey] as? Bool ?? false
						
						if isExpanded
						{
							container.isExpanded = true
							container.load(with:containerState)
						}
					}
					
					self.isLoading = false
					self.isLoaded = true
					self.loadTask = nil
				}
			}
			catch let error
			{
				await MainActor.run
				{
					self.isLoading = false
					self.isLoaded = false
				}

				Swift.print("    ERROR \(error)")
			}
		}
	}
	

	func container(for identifier:String) async -> Container?
	{
		for container in await containers
		{
			if container.identifier == identifier
			{
				return container
			}
		}
		
		return nil
	}
	
	
//----------------------------------------------------------------------------------------------------------------------


	/// Adds a top-level container

	public func addContainer(_ container:Container)
	{
		Task
		{
			await MainActor.run
			{
				self.objectWillChange.send()
				self.containers.append(container)
			}
		}
	}

	/// Removes the specified subcontainer

	public func removeContainer(_ container:Container)
	{
		self.removeContainer(with:container.identifier)
	}
	
	/// Removes the subcontainer with the specified identifier

	public func removeContainer(with identifier:String)
	{
		Task
		{
			await MainActor.run
			{
				self.objectWillChange.send()
				self.containers = self.containers.filter { $0.identifier != identifier }
			}
		}
	}
	
	
//----------------------------------------------------------------------------------------------------------------------


	// MARK: - State
	
	/// Gathers the current state information for this Source.
	
	public func state() async -> [String:Any]
	{
		var state:[String:Any] = [:]
		state[isExpandedKey] = self.isExpanded
		
		let containers = await self.containers

		for container in containers
		{
			let key = container.stateKey
			let value = await container.state()
			state[key] = value
		}
		
		return state
	}
	
	/// The key for the state dictionary of this Source
	
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
