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
import SwiftUI


//----------------------------------------------------------------------------------------------------------------------


/// A Container is the main data structure to create tree like graphs. Each Container has a list of sub-containers
/// and a list of Objects (media files).

open class Container : ObservableObject, Identifiable, StateSaving, BXSignpostMixin
{
	/// Reference to the owning library
	
	public private(set) weak var library:Library? = nil

	/// The identifier specifies the location of a Container
	
	public let identifier:String
	
	/// An SFSymbol name for the container icon
	
	public let icon:String?
	
	/// The name of the Container can be displayed in the UI
	
	@Published public var name:String = ""
	
	/// This can be any kind of data that subclasses need to their job
	
	public var data:Any
	
	/// This info can be used for filtering the Objects of this Container. Filtering works differently for the
	/// various sources, as different metadata can be used when filtering.
	
	public let filter:Object.Filter
	
	/// The Loader is responsible for loading the contents of this Container
	
	public let loader:Loader
	
	/// Containers that were added manually by the user should be user-removable as well. This handler will be called
	/// when the user wants to remove a Container again.
	
	public let removeHandler:((Container)->Void)?

	/// The list of subcontainers
	
	@MainActor @Published public private(set) var containers:[Container] = []
	
	/// The list of MediaObjects in this container
	
	@MainActor @Published public private(set) var objects:[Object] = []
	
	/// The number of MediaObjects in this container. This property can be accessed outside the main thread, but its value might not be current.
	
	@Published public private(set) var objectCount = 0
	
	/// Returns true if this container is currently being loaded
	
	@MainActor @Published public private(set) var isLoading = false
	
	/// Returns true if this container has been loaded (at least once)
	
	@MainActor @Published public private(set) var isLoaded = false
	
	/// Returns true if this container is currently selected, i.e. it is visible in the ObjectCollectionView
	
	@Published public var isSelected = false
	
	/// Returns true if this container is expanded in the view. This property should only be manipulated by the view.
	
	@Published public var isExpanded = false
	{
		didSet { updateChildVisibility() }
	}
	
	/// Returns true if this container is currently visible, i.e. its parent is expanded.
	
	@Published public var isVisible = false
	
	/// The currently running Task for loading the contents of this container
	
	private var loadTask:Task<Void,Never>? = nil
	
	/// This task is used to only show the loading spinner if loading takes a while
	
//	private var spinnerTask:Task<Void,Never>? = nil
	
	/// This task is used to purge cached data after a specified amount of time
	
	internal var purgeTask:Task<Void,Never>? = nil
	
	/// An optional helper that can copy dropped file to this Container
	
	#if os(macOS)
	public var fileDropDestination:FolderDropDestination? = nil
	#endif
	
	/// References to subcriptions and notifications
	
	public var observers:[Any] = []


//----------------------------------------------------------------------------------------------------------------------


	// MARK: -
	
	/// Creates a new Container
	
	public init(identifier:String, icon:String? = nil, name:String, data:Any, filter:Object.Filter, loadHandler:@escaping Container.Loader.LoadHandler, removeHandler:((Container)->Void)? = nil, in library:Library?)
	{
		BXMediaBrowser.logDataModel.verbose {"\(Self.self).\(#function) \(identifier)"}

		self.library = library
		self.identifier = identifier
		self.icon = icon
		self.name = name
		self.data = data
		self.filter = filter
		self.loader = Container.Loader(identifier:identifier, loadHandler:loadHandler)
		self.removeHandler = removeHandler
		
		// Reload this Container when the filter changes
		
		self.setupFilterObserver()
			
		// If this (newly created) Container is the one that was selected in the Library before, then restore the selection.
		
		DispatchQueue.main.async
		{
			[weak self] in self?.restoreSelectedContainer()
		}
	}

	/// Reloads this Container when the filter changes
	
	open func setupFilterObserver()
	{
		// Reload Container when any property of the Filter has changed
		
		self.observers += filter
			.objectWillChange
			.debounce(for:0.25, scheduler:RunLoop.main)
			.sink
			{
				[weak self] _ in
				guard let self = self else { return }
				guard self.isSelected else { return }
				self.load(in:library)
			}

		// If this container is set to sort by rating and an Object rating has changed, then also reload
		
		self.observers += NotificationCenter.default.publisher(for:StatisticsController.ratingNotification, object:nil)
			.debounce(for:1.0, scheduler:RunLoop.main)
			.sink
			{
				[weak self] _ in
				guard let self = self else { return }
				guard self.isSelected else { return }
				guard self.filter.sortType == .rating else { return }
				self.load(in:library)
			}
			
		self.observers += NotificationCenter.default.publisher(for:StatisticsController.didChangeNotification, object:nil)
			.debounce(for:1.0, scheduler:RunLoop.main)
			.sink
			{
				[weak self] _ in
				guard let self = self else { return }
				guard self.isSelected else { return }
				guard self.filter.sortType == .useCount else { return }
				self.load(in:library)
			}
	}
	
	
	// Required by the Identifiable protocol
	
	nonisolated public var id:String
	{
		
		"\(identifier)-\(icon ?? "folder")-\(name)"
	}
	
	/// Returns the MediaType of this hosted by this Container. Subclasses should override this property to return their specific MediaType.
	
	nonisolated open var mediaTypes:[Object.MediaType]
	{
		return [.image]
	}


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Loading
	
	/// Loads the contents of the container. If a previous load is still in progress it is cancelled,
	/// so that the new load can be started sooner.
	
	public func load(with containerState:[String:Any]? = nil, in library:Library?)
	{
		self.loadTask?.cancel()
		self.loadTask = nil
		
		// Show spinning wheel after 0.15s
		
//		let spinnerTask = Task
//		{
//			try? await Task.sleep(nanoseconds:150_000_000) // 0.15s
//
//			await MainActor.run
//			{
//				self.isLoading = true
//			}
//		}

		// Perform loading in a background task
		
		self.loadTask = Task
		{
			do
			{
				try await Tasks.canContinue()
				
				BXMediaBrowser.logDataModel.debug {"\(Self.self).\(#function) \(identifier)"}

				let token = self.beginSignpost(in:"Container","load")
				defer { self.endSignpost(with:token, in:"Container","load") }
		
				// Show spinning wheel
				
				await MainActor.run
				{
					self.isLoading = true
				}
				
				// Get new list of (sub)containers and objects
				
				let (containers,objects) = try await self.loader.contents(with:data, filter:filter, in:library)
				let containerNames = containers.map { $0.name }.joined(separator:", ")
				let objectNames = objects.map { $0.name }.joined(separator:", ")
				BXMediaBrowser.logDataModel.verbose {"    containers = \(containerNames)"}
				BXMediaBrowser.logDataModel.verbose {"    objects = \(objectNames)"}
				
				// Remove duplicate objects - NSDiffableDataSource that is being used with the NSCollectionView
				// throws a hissy fit (and exceptions) when encountering duplicate identifiers.
				
				let uniqueObjects = objects.removingDuplicates()
				{
					$0.identifier
				}
				
				// Link the objects
				
				var prev:Object? = nil
				
				for object in uniqueObjects
				{
					prev?.next = object
					object.next = nil
					prev = object
				}
				
				// Check if this container should be expanded
				
				let isExpanded = containerState?[isExpandedKey] as? Bool ?? self.isExpanded
				
				// Spinning wheel is no longer needed
				
//				spinnerTask.cancel()
				
				// Store results in main thread
				
				await MainActor.run
				{
					self.containers = containers
					self.objects = uniqueObjects
					self.objectCount = uniqueObjects.count
					self.isExpanded = isExpanded

					// Restore isExpanded state of containers
					
					for container in containers
					{
						let state = containerState?[container.stateKey] as? [String:Any]
						let isExpanded = state?[container.isExpandedKey] as? Bool ?? false
						if isExpanded { container.load(with:state, in:library) }
					}
					
					self.isLoaded = true
					self.isLoading = false
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
				
				if let error = error as? Container.Error, error == .loadContentsCancelled
				{
					BXMediaBrowser.logDataModel.warning {"\(Self.self).\(#function) ERROR \(error)"}
				}
				else
				{
					BXMediaBrowser.logDataModel.error {"\(Self.self).\(#function) ERROR \(error)"}
				}
			}
		}
	}
	
	
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
	
	/// Call this function in special cases where you want to mark a Container as "unloaded", i.e. invalidated,
	/// so that it will be loaded lazily again the next time it is selected.
	
	@MainActor public func invalidateLoaded()
	{
		self.isLoaded = false
	}
	
	
	/// If the container caches any expensive data, calling this function will discard any cached data
	
	@MainActor func invalidateCache()
	{
		// Can be overridden by subclasses
		
		self.containers = []
		self.objects = []
		self.isLoaded = false
		self.isLoading	= false
	}
	
	
	/// Invalidates any cached data and then loads this Container again
	
	func reload()
	{
		Task
		{
			guard await self.isLoaded else { return }
			guard self.isSelected else { return }

			BXMediaBrowser.logDataModel.debug {"\(Self.self).\(#function) \(identifier)"}

			await MainActor.run
			{
				self.invalidateCache()
				self.load(in:library)
			}
		}
	}
	
	
//----------------------------------------------------------------------------------------------------------------------


	// MARK: - State
	
	/// Recursively walks through the data model tree and gathers the current state info. Since this
	/// operation is accessing async properties, this function is also async and can only be called
	/// from a Task or another async function.
	
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

	/// The key for the state dictionary of this Container
	
	internal var stateKey:String
	{
		"\(identifier)".replacingOccurrences(of:".", with:"-")
	}

	/// The key of the isExpanded state inside the state dictionary

	internal var isExpandedKey:String
	{
		"isExpanded"
	}
	
	/// Subclasses can override this read-only property if they know that a container can never be expanded,
	/// because it will never have any sub-containers.
	
	@MainActor open var canExpand:Bool { true }


	/// When a container is expanded is sub-containers need to be set to visible. If one of the subcontainers is selected,
	/// it will be loaded.
	
	func updateChildVisibility()
	{
		Task
		{
			let containers = await self.containers
			
			await MainActor.run
			{
				for container in containers
				{
					container.isVisible = isExpanded
					if container.isSelected && !container.isLoaded { container.load(in:library) }
				}
			}
		}
	}
	

	/// Once a Container instance is created, this function can be called to restore the library's selection, i.e. if this is the one
	
	private func restoreSelectedContainer()
	{
		if let restoreHandler = self.library?.stateSaver.restoreSelectedContainerHandler
		{
			restoreHandler(self)
		}
	}
	
	
//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Sorting
	
	/// Returns the list of allowed sort Kinds for this Container
		
	open var allowedSortTypes:[Object.Filter.SortType] { [.alphabetical] }

	/// When the selected Container changes the current sortType needs to validated, because it might
	/// not be usable anymore. In this case this function switches to the first available SortType.
	
	func validateSortType()
	{
		if !allowedSortTypes.contains(self.filter.sortType)
		{
			self.filter.sortType = allowedSortTypes.first ?? .never
		}
	}
	
	
//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Info
	
	/// Returns a description of the contents of this Container
	
    @MainActor open var localizedObjectCount:String
    {
		let n = self.objects.count
		let str = n.localizedItemsString
		return str
    }
}


//----------------------------------------------------------------------------------------------------------------------
