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


/// A Container is the main data structure to create tree like graphs. Each Container has a list of sub-containers
/// and a list of Objects (media files).

open class Container : ObservableObject, Identifiable, StateRestoring
{
	/// The identifier specifies the location of a Container
	
	public let identifier:String
	
	/// This can be any kind of info that subclasses need to their job
	
	public var info:Any
	
	/// An SFSymbol name for the container icon
	
	public let icon:String?
	
	/// The name of the Container can be displayed in the UI
	
	public let name:String
	
	/// The Loader is responsible for loading the contents of this Container
	
	public let loader:Loader
	
	/// Containers that were added manually by the user should be user-removable as well. This handler will be called
	/// when the user wants to remove a Container again.
	
	public let removeHandler:((Container)->Void)?
	
	/// The list of subcontainers
	
	@MainActor @Published public private(set) var containers:[Container] = []
	
	/// The list of MediaObjects in this container
	
	@MainActor @Published public private(set) var objects:[Object] = []
	
	/// Returns true if this source is currently being loaded
	
	@MainActor @Published public private(set) var isLoading = false
	
	/// Returns true if this container has been loaded (at least once)
	
	@MainActor @Published public private(set) var isLoaded = false
	
	/// Returns true if this container is expanded in the view. This property should only be manipulated by the view.
	
	@Published public var isExpanded = false
	
	/// The currently running Task for loading the contents of this container
	
	private var loadTask:Task<Void,Never>? = nil
	

//----------------------------------------------------------------------------------------------------------------------


	/// Creates a new Container
	
	public init(identifier:String, info:Any, icon:String? = nil, name:String, removeHandler:((Container)->Void)? = nil, loadHandler:@escaping Container.Loader.LoadHandler)
	{
		self.identifier = identifier
		self.info = info
		self.icon = icon
		self.name = name
		self.removeHandler = removeHandler
		self.loader = Container.Loader(identifier:identifier, info:info, loadHandler:loadHandler)
	}

	// Required by the Identifiable protocol
	
	nonisolated public var id:String
	{
		identifier
	}
	

//----------------------------------------------------------------------------------------------------------------------


	/// Loads the contents of the container. If a previous load is still in progress it is cancelled,
	/// so that the new load can be started sooner.
	
	public func load(with containerState:[String:Any]? = nil)
	{
		Swift.print("Loading \"\(name)\" - \(identifier)")

		self.loadTask?.cancel()
		self.loadTask = nil
		
		self.loadTask = Task
		{
			do
			{
				await MainActor.run
				{
					self.isLoading = true
				}

				// Remember which existing containers are currently expanded, so that we can restore that state
				// when reloading the containers.
		
				let expandedContainerIdentifiers = await self.containers.compactMap
				{
					$0.isExpanded ? $0.identifier : nil
				}
		
				// Get new list of (sub)containers and objects
				
				let (containers,objects) = try await self.loader.contents
				
//				let names1 = containers.map { $0.name }.joined(separator:", ")
//				let names2 = objects.map { $0.name }.joined(separator:", ")
//				Swift.print("    containers = \(names1)")
//				Swift.print("    objects = \(names2)")
				
				// Check if this container should be expanded
				
				let isExpanded = containerState?[isExpandedKey] as? Bool ?? self.isExpanded
//				let isExpanded2 = expandedContainerIdentifiers.contains(identifier)
//				let isExpanded = isExpanded1 || isExpanded2
				
				// Store results in main thread
				
				await MainActor.run
				{
					self.containers = containers
					self.objects = objects
					self.isExpanded = isExpanded
					
					self.isLoaded = true
					self.isLoading = false
					self.loadTask = nil

					// Restore isExpanded state of containers
					
					for container in containers
					{
						let state = containerState?[container.stateKey] as? [String:Any]
						let isExpanded = state?[container.isExpandedKey] as? Bool ?? false
						if isExpanded { container.load(with:state) }
					}
				}
			}
			catch //let error
			{
//				Swift.print("    ERROR \(error)")
			}
		}
	}
	

//----------------------------------------------------------------------------------------------------------------------


	/// Purges cached data for the objects in this container. This reduces the memory footprint.

	func purgeCachedDataOfObjects(after delay:Double = 20)
	{
		self._purgeTask = Task
		{
			let ns = UInt64(delay * 1000000000)
			try? await Task.sleep(nanoseconds:ns)
			
			if Task.isCancelled
			{
				self._purgeTask = nil
				return
			}
			
			await MainActor.run
			{
				self.objects.forEach { $0.purge() }
				self._purgeTask = nil
			}
		}
	}
	
	public func cancelPurgeCachedDataOfObjects()
	{
		self._purgeTask?.cancel()
	}

	private var _purgeTask:Task<Void,Never>? = nil


//----------------------------------------------------------------------------------------------------------------------


	/// Adds a subcontainer to this container
	
	public func addContainer(_ container:Container)
	{
		Task
		{
			await MainActor.run
			{
				self.containers.append(container)
			}
		}
	}
	
	/// Removes the subcontainer with the specified identifier
	
	public func removeContainer(with identifier:String)
	{
		Task
		{
			await MainActor.run
			{
				self.containers = self.containers.filter { $0.identifier != identifier }
			}
		}
	}
	
	
//----------------------------------------------------------------------------------------------------------------------


	internal var stateKey:String
	{
		"\(identifier)".replacingOccurrences(of:".", with:"-")
	}

	internal var isExpandedKey:String
	{
		"isExpanded"
	}

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

}


//----------------------------------------------------------------------------------------------------------------------
