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
import QuickLook
import BXSwiftUtils


//----------------------------------------------------------------------------------------------------------------------


open class FolderSource : Source, AccessControl
{
	/// The unique identifier of this source must always remain the same. Do not change this
	/// identifier, even if the class name changes due to refactoring, because the identifier
	/// might be stored in a preferences file or user documents.
	
	static let identifier = "FolderSource:"
	
	
	/// Creates a new Source for local file system directories
	
	public init()
	{
		FolderSource.log.verbose {"\(Self.self).\(#function) \(Self.identifier)"}
		super.init(identifier:Self.identifier, name:"Finder")
		self.loader = Loader(identifier:self.identifier, loadHandler:self.loadContainers)
		
		SortController.shared.register(
			kind: .alphabetical,
			comparator: SortController.compareAlphabetical)
		
		SortController.shared.register(
			kind: .creationDate,
			comparator: SortController.compareCreationDate)
	}


	/// Converts a file URL to a unique identifier
	
	public class func identifier(for url:URL) -> String
	{
		return "\(Self.identifier)\(url.absoluteString)"
	}
	
	
	/// Converts a unique identifier back to a file URL
	
	public class func url(for identifier:String) throws -> URL
	{
		let string = identifier.replacingOccurrences(of:Self.identifier, with:"")
		guard let url = URL(string:string) else { throw Container.Error.notFound }
		return url
	}


	/// Loads the top-level containers of this source.
	///
	/// Subclasses can override this function, e.g. to load top level folder from the preferences file
	
	private func loadContainers(with sourceState:[String:Any]? = nil) async throws -> [Container]
	{
		FolderSource.log.debug {"\(Self.self).\(#function) \(identifier)"}
		
		// Load stored bookmarks from state. Convert each bookmark to a folder url. If the folder
		// still exists, then create a FolderContainer for it.

		var containers:[Container] = []
		
		if let bookmarks = sourceState?[Self.bookmarksKey] as? [Data]
		{
			let folderURLs = bookmarks
				.compactMap { URL(with:$0) }
				.filter { $0.exists && $0.isDirectory }
				.filter { $0.startAccessingSecurityScopedResource() }
				
			for folderURL in folderURLs
			{
				let container = try self.createContainer(for:folderURL)
				containers += container
			}
		}

		return containers
	}


	/// Creates a Container for the folder at the specified URL. Subclasses can override this
	/// function to filter out some directories or return more specific Container subclasses.
	
	open func createContainer(for url:URL) throws -> Container?
	{
		FolderSource.log.verbose {"\(Self.self).\(#function) \(url)"}

		return FolderContainer(url:url)
		{
			[weak self] in self?.removeContainer($0)
		}
	}


//----------------------------------------------------------------------------------------------------------------------


	override public func state() async -> [String:Any]
	{
		var state = await super.state()
		
		let bookmarks = await self.containers
			.compactMap { $0.data as? URL }
			.compactMap { try? $0.bookmarkData() }
		
		state[Self.bookmarksKey] = bookmarks

		return state
	}

	internal static var bookmarksKey:String { "bookmarks" }


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


extension SortController.Kind
{
	public static let alphabetical = "alphabetical"
}


extension SortController
{
	public static func compareAlphabetical(_ object1:Object,_ object2:Object) -> Bool
	{
		let name1 = object1.name as NSString
		let name2 = object2.name
		return name1.localizedStandardCompare(name2) == .orderedAscending
	}
}


//----------------------------------------------------------------------------------------------------------------------


extension SortController.Kind
{
	public static let creationDate = "creationDate"
}


extension SortController
{
	public static func compareCreationDate(_ object1:Object,_ object2:Object) -> Bool
	{
		guard let url1 = object1.data as? URL else { return false }
		guard let url2 = object2.data as? URL else { return false }
		guard let date1 = url1.creationDate else { return false }
		guard let date2 = url2.creationDate else { return false }
		return date1 < date2
	}
}


//----------------------------------------------------------------------------------------------------------------------
