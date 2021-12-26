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

open class Container : ObservableObject, Identifiable
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
	
	/// The list of subcontainers
	
	@MainActor @Published public private(set) var containers:[Container] = []
	
	/// The list of MediaObjects in this container
	
	@MainActor @Published public private(set) var objects:[Object] = []
	
	/// Returns true if this container has been loaded (at least once)
	
	@MainActor @Published public private(set) var isLoaded = false
	
	/// Returns true if this container is expanded in the view. This property should only be manipulated by the view.
	
	@Published public var isExpanded = false
	
	/// The currently running Task for loading the contents of this container
	
	@Published private var loadTask:Task<Void,Never>? = nil
	

//----------------------------------------------------------------------------------------------------------------------


	/// Creates a new Container
	
	public init(identifier:String, info:Any, icon:String? = nil, name:String, loadHandler:@escaping Container.Loader.LoadHandler)
	{
		self.identifier = identifier
		self.info = info
		self.icon = icon
		self.name = name
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
	
	public func load(_ completionHandler:(()->Void)? = nil)
	{
		Swift.print("Loading \"\(name)\" - \(identifier)")

		self.loadTask?.cancel()
		self.loadTask = nil
		
		self.loadTask = Task
		{
			do
			{
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
				
				// Restore isExpanded state of containers
				
				for container in containers
				{
					if expandedContainerIdentifiers.contains(container.identifier)
					{
						container.isExpanded = true
					}
				}
				
				// Assign result in main thread
				
				await MainActor.run
				{
					self.containers = containers
					self.objects = objects
					self.isLoaded = true
					self.loadTask = nil
					completionHandler?()
				}
			}
			catch //let error
			{
//				Swift.print("    ERROR \(error)")
			}
		}
	}
	
	/// Returns true if this container is currently loading. Can be used to display progress info like a spinning wheel.
	
	public var isLoading:Bool { loadTask != nil }
	

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


	public func saveState()
	{
		UserDefaults.standard.set(isExpanded, forKey:isExpandedPrefsKey)

		Task
		{
			let containers = await self.containers
			
			await MainActor.run
			{
				containers.forEach { $0.saveState() }

			}
		}
	}
	
	
	public func restoreState()
	{
		self.isExpanded = UserDefaults.standard.bool(forKey:isExpandedPrefsKey)
		
		Task
		{
			let containers = await self.containers
			
			await MainActor.run
			{
				containers.forEach { $0.restoreState() }
			}
		}
	}


	private var isExpandedPrefsKey:String
	{
		"BXMediaBrowser.Container.\(identifier).isExpanded".replacingOccurrences(of:".", with:"-")
	}



//	var flattenedContainers:[Container]
//	{
//		get async
//		{
//			await self.containers.flatMap
//			{
//				$0.flattenedContainers
//			}
//		}
//	}


//----------------------------------------------------------------------------------------------------------------------


//	public func saveState(to dictionary:[String:Any]) async
//	{
//		UserDefaults.standard.set(isExpanded, forKey:"isExpanded")
//		
//		for container in await self.containers
//		{
//			var subDictionary:[String:Any] = [:]
//			dictionary["Container-\(container.identifier)"] = subDictionary
//			dictionary.saveState(to:subDictionary)
//		}
//	}
//	
//	public func restoreState(from dictionary:[String:Any])
//	{
//		self.isExpanded = UserDefaults.standard.bool(forKey:"isExpanded")
//	}
}


//----------------------------------------------------------------------------------------------------------------------


