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


open class UnsplashSource : Source, AccessControl
{
	/// The unique identifier of this source must always remain the same. Do not change this
	/// identifier, even if the class name changes due to refactoring, because the identifier
	/// might be stored in a preferences file or user documents.
	
	static let identifier = "UnsplashSource:"
	
	
//----------------------------------------------------------------------------------------------------------------------


	/// Creates a new Source for local file system directories
	
	public init()
	{
		UnsplashSource.log.verbose {"\(Self.self).\(#function) \(Self.identifier)"}
		super.init(identifier:Self.identifier, name:"Unsplash", filter:UnsplashFilter())
		self.loader = Loader(loadHandler:self.loadContainers)
	}


//----------------------------------------------------------------------------------------------------------------------


	/// Loads the top-level containers of this source.
	///
	/// Subclasses can override this function, e.g. to load top level folder from the preferences file
	
	private func loadContainers(with sourceState:[String:Any]? = nil, filter:Object.Filter) async throws -> [Container]
	{
		UnsplashSource.log.debug {"\(Self.self).\(#function) \(identifier)"}

		var containers:[Container] = []
		
		// Add Live Search
		
		let name = NSLocalizedString("Search", tableName:"Unsplash", bundle:.module, comment:"Container Name")
		containers += UnsplashContainer(identifier:"UnsplashSource:Search", icon:"magnifyingglass", name:name, filter:UnsplashFilter(), saveHandler:
		{
			[weak self] in self?.saveContainer($0)
		})

		// Add Saved Searches
		
		if let savedFilterDatas = sourceState?[Self.savedFilterDatasKey] as? [Data]
		{
			for filterData in savedFilterDatas
			{
				guard let filter = try? JSONDecoder().decode(UnsplashFilter.self, from:filterData) else { continue }
				guard let container = self.createContainer(with:filter) else { continue }
				containers += container
			}
		}
		
		return containers
	}
	
	
	/// Creates a new "saved" copy of the live search container
	
	func saveContainer(_ liveSearchContainer:UnsplashContainer)
	{
		UnsplashSource.log.debug {"\(Self.self).\(#function)"}

		guard let liveFilter = liveSearchContainer.filter as? UnsplashFilter else { return }
		guard let savedContainer = self.createContainer(with:liveFilter.copy) else { return }
		self.addContainer(savedContainer)
	}


	/// Creates a new "saved" UnsplashContainer with the specified filter
	
	func createContainer(with filter:UnsplashFilter) -> UnsplashContainer?
	{
		guard !filter.searchString.isEmpty else { return nil }

		let searchString = filter.searchString
		let orientation = filter.orientation.rawValue
		let color = filter.color.rawValue
		let identifier = "UnsplashSource:\(searchString)/\(orientation)/\(color)".replacingOccurrences(of:" ", with:"-")
		let name = UnsplashContainer.description(with:filter)
		
		return UnsplashContainer(identifier:identifier, icon:"rectangle.stack", name:name, filter:filter, removeHandler:
		{
			[weak self] in self?.removeContainer($0)
		})
	}


//----------------------------------------------------------------------------------------------------------------------


	/// Returns the archived filterData of all saved Containers
	
	override public func state() async -> [String:Any]
	{
		var state = await super.state()
		
		let savedFilterDatas = await self.containers
			.compactMap { $0 as? UnsplashContainer }
			.filter { $0.saveHandler == nil }
			.compactMap { $0.filterData }

		state[Self.savedFilterDatasKey] = savedFilterDatas

		return state
	}

	internal static var savedFilterDatasKey:String { "savedFilterDatas" }


//----------------------------------------------------------------------------------------------------------------------


	public var hasAccess:Bool { true }
	
	public func grantAccess(_ completionHandler:@escaping (Bool)->Void)
	{
		completionHandler(hasAccess)
	}


//----------------------------------------------------------------------------------------------------------------------


	public static var log:BXLogger =
	{
		()->BXLogger in
		
		var logger = BXLogger()

		logger.addDestination
		{
			(level:BXLogger.Level,string:String)->() in
			BXMediaBrowser.log.print(level:level, force:true) { string }
		}
		
		return logger
	}()
}


//----------------------------------------------------------------------------------------------------------------------
