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


#if canImport(iMedia)

import iMedia
import BXSwiftUtils
import Foundation


//----------------------------------------------------------------------------------------------------------------------


open class LightroomClassicContainer : Container, AppLifecycleMixin
{
	struct LRCData
	{
		let node:IMBNode
		let allowedMediaTypes:[Object.MediaType]
	}
	
	
//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Setup
	
	/// Creates a new Container for the folder at the specified URL
	
	public required init(node:IMBNode, allowedMediaTypes:[Object.MediaType], filter:LightroomClassicFilter)
	{
		let data = LRCData(node:node, allowedMediaTypes:allowedMediaTypes)
		let identifier = node.identifier ?? "LightroomClassic:Node:xxx"
		let icon = "folder"
		let name = node.name ?? "••••••"
		
		super.init(
			identifier: identifier,
			icon: icon,
			name: name,
			data: data,
			filter: filter,
			loadHandler: Self.loadContents)

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
		return data.allowedMediaTypes
	}

	// Folders can be expanded, but albums cannot
	
	override open var canExpand: Bool
	{
		guard let data = self.data as? LRCData else { return false }
		return true
	}

	/// Returns the list of allowed sort Kinds for this Container
		
	override open var allowedSortTypes:[Object.Filter.SortType]
	{
		[.captureDate,.alphabetical,.rating]
	}


	// Choose unit name depending on allowedMediaTypes
	
    @MainActor override open var localizedObjectCount:String
    {
		let n = self.objects.count
		guard let data = self.data as? LRCData else { return n.localizedItemsString }
		if data.allowedMediaTypes == [.image] { return n.localizedImagesString }
		if data.allowedMediaTypes == [.video] { return n.localizedVideosString }
		return n.localizedItemsString
    }


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Loading
	
	
	/// Clears the caches so that we can reload a Container
	
	@MainActor override func invalidateCache()
	{
		super.invalidateCache()
		
		guard let data = self.data as? LRCData else { return }
//		data.cachedContainers = nil
//		data.cachedObjects = nil
//		data.objectMap = [:]
//		data.nextAccessPoint = nil
	}
	
	
	/// Loads the (shallow) contents of this folder
	
	class func loadContents(for identifier:String, data:Any, filter:Object.Filter) async throws -> Loader.Contents
	{
		guard let data = data as? LRCData else { throw Error.loadContentsFailed }
		guard let parserMessenger = LightroomClassic.shared.parserMessenger else { throw Error.loadContentsFailed }
		guard let filter = filter as? LightroomClassicFilter else { throw Error.loadContentsFailed }

		LightroomClassic.log.debug {"\(Self.self).\(#function) \(identifier)"}

		let id = self.beginSignpost(in:"LightroomClassicContainer", #function)
		defer { self.endSignpost(with:id, in:"LightroomClassicContainer", #function) }

		var containers:[LightroomClassicContainer] = []
		var objects:[Object] = []
		
		do
		{
			// Load subnodes
			
			let node = data.node
			let allowedMediaTypes = data.allowedMediaTypes
			_ = try parserMessenger.populateNode(node)
			
			// Convert the IMBNodes to LightroomClassicContainer. For some reason we end sometimes end up with
			// duplicate nodes. For this reason we have to skip any duplicates and only create unique Containers.
			
			var knownNodes:[String:Bool] = [:]
			
			for node in node.subnodes
			{
				guard let node = node as? IMBNode else { continue }
				guard knownNodes[node.identifier] == nil else { continue }
				
				let container = LightroomClassicContainer(node:node, allowedMediaTypes:allowedMediaTypes, filter:filter)
				knownNodes[node.identifier] = true
				containers += container
			}
			
			for item in node.objects
			{
				guard let imbObject = item as? IMBLightroomObject else { continue }
				// Filter out items that are not wanted
				let object = LightroomClassicObject(with:imbObject)
				objects += object
			}
			
//			containers = node.subnodes.compactMap
//			{
//				guard let node = $0 as? IMBNode else { return nil }
//				return LightroomClassicContainer(node:node, allowedMediaTypes:allowedMediaTypes, filter:filter)
//			}

			// Load objects
			
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
