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


#if canImport(iMedia) && os(macOS)

import iMedia
import BXSwiftUtils
import Foundation


//----------------------------------------------------------------------------------------------------------------------


open class LightroomClassicContainer : Container, AppLifecycleMixin
{
	struct LRCData
	{
		let node:IMBNode
		let mediaType:Object.MediaType
		let parserMessenger:IMBLightroomParserMessenger
	}
	
	
//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Setup
	
	/// Creates a new Container for the folder at the specified URL
	
	public required init(node:IMBNode, mediaType:Object.MediaType, parserMessenger:IMBLightroomParserMessenger, filter:FolderFilter, in library:Library?)
	{
		let data = LRCData(node:node, mediaType:mediaType, parserMessenger:parserMessenger)
		let identifier = node.identifier ?? "LightroomClassic:Node:xxx"
		let icon = "folder"
		let name = node.name ?? "••••••"
		
		super.init(
			identifier: identifier,
			icon: icon,
			name: name,
			data: data,
			filter: filter,
			loadHandler: Self.loadContents,
			in: library)

		// Since Lightroom CC does not have and change notification mechanism yet, we need to poll for changes.
		// Whenever the app is brought to the foreground (activated), we just assume that a change was made in
		// Lightroom in the meantime. Perform necessary checks and reload this container if necessary.
		
//		self.registerDidActivateHandler
//		{
//			[weak self] in self?.reloadIfNeeded()
//		}
	}


//----------------------------------------------------------------------------------------------------------------------



	override nonisolated open var mediaTypes:[Object.MediaType]
	{
		guard let data = self.data as? LRCData else { return [] }
		return [data.mediaType]
	}

	// A container can be expanded if it has sub-containers
	
	override open var canExpand: Bool
	{
		if self.isLoaded
		{
			return !self.containers.isEmpty
		}

		return true
	}

	/// Returns the list of allowed sort Kinds for this Container
		
	override open var allowedSortTypes:[Object.Filter.SortType]
	{
		[.captureDate,.alphabetical,.rating,.useCount]
	}


	// Choose unit name depending on allowedMediaTypes
	
    @MainActor override open var localizedObjectCount:String
    {
		let n = self.objects.count
		guard let data = self.data as? LRCData else { return n.localizedItemsString }
		if data.mediaType == .image { return n.localizedImagesString }
		if data.mediaType == .video { return n.localizedVideosString }
		return n.localizedItemsString
    }


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Loading
	
	
	/// Loads the (shallow) contents of this folder
	
	class func loadContents(for identifier:String, data:Any, filter:Object.Filter, in library:Library?) async throws -> Loader.Contents
	{
		guard let data = data as? LRCData else { throw Error.loadContentsFailed }
		guard let filter = filter as? FolderFilter else { throw Error.loadContentsFailed }
		let parserMessenger = data.parserMessenger
		let mediaType = data.mediaType
		let searchString = filter.searchString
		let minRating = filter.rating

		LightroomClassic.log.debug {"\(Self.self).\(#function) \(identifier)"}

		let id = self.beginSignpost(in:"LightroomClassicContainer", #function)
		defer { self.endSignpost(with:id, in:"LightroomClassicContainer", #function) }

		var containers:[LightroomClassicContainer] = []
		var objects:[Object] = []
		
		do
		{
			// Load subnodes
			
			let node = data.node
			node.setSubnodes(nil)
			node.objects = []
			
			try NSException.catch
			{
				_ = try parserMessenger.populateNode(node)
			}
			
			// Convert the IMBNodes to LightroomClassicContainer. For some reason we end sometimes end up with
			// duplicate nodes. For this reason we have to skip any duplicates and only create unique Containers.
			
			var knownNodes:[String:Bool] = [:]
			
			if let subnodes = node.subnodes
			{
				for node in subnodes
				{
					guard let node = node as? IMBNode else { continue }
					guard knownNodes[node.identifier] == nil else { continue }
					if node.name.lowercased() == "smart collections" { continue }   // Filter out some nodes that aren't populated
					if node.name.lowercased() == "quick collection" { continue }    // by iMedia and are thus pretty useless anyway

					try await Tasks.canContinue()
			
					let container = LightroomClassicContainer(node:node, mediaType:mediaType, parserMessenger:parserMessenger, filter:filter, in:library)
					knownNodes[node.identifier] = true
					containers += container
				}
			}
			
			// Convert IMBLightroomObjects to LightroomClassicObjects. Again, there are edge cases where we get
			// duplicate objects - which can cause crashes with the NSDiffableDataSource of our NSCollectionView.
			// For this reason we need to remove any duplicates.
			
			var knownObjects:[String:Bool] = [:]
	
			if let nodeObjects = node.objects
			{
				for item in nodeObjects
				{
					// Get next IMBLightroomObject
					
					guard let imbObject = item as? IMBLightroomObject else { continue }
					let identifier = LightroomClassicObject.identifier(for:imbObject)
					let name = imbObject.name ?? ""
					
					// Filter out items that are not wanted
					
					guard searchString.isEmpty || name.contains(searchString) else { continue }
					guard minRating == 0 || StatisticsController.shared.rating(for:identifier) >= minRating else { continue }
					guard knownObjects[identifier] == nil else { continue }
					
					// Convert to LightroomClassicObject
					
					let object = LightroomClassicObject(with:imbObject, mediaType:mediaType, parserMessenger:parserMessenger, in:library)
					knownObjects[identifier] = true
					objects += object
				}
			}
			
			// Sort according to specified sort order
			
			filter.sort(&objects)
		}
		catch
		{
			LightroomClassic.log.error {"\(Self.self).\(#function) ERROR \(error)"}
		}
		
		// Return contents
		
		return (containers,objects)
	}
}



//----------------------------------------------------------------------------------------------------------------------


#endif
