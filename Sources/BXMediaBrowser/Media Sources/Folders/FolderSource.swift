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

#if canImport(AppKit)
import AppKit
#endif

#if canImport(UIKit)
import UIKit
#endif


//----------------------------------------------------------------------------------------------------------------------


open class FolderSource : Source, AccessControl
{
	/// The unique identifier of this source must always remain the same. Do not change this
	/// identifier, even if the class name changes due to refactoring, because the identifier
	/// might be stored in a preferences file or user documents.
	
	static let identifier = "FolderSource:"
	
	
	/// Creates a new Source for local file system directories
	
	public init(filter:FolderFilter = FolderFilter(), in library:Library?)
	{
		FolderSource.log.verbose {"\(Self.self).\(#function) \(Self.identifier)"}

		super.init(identifier:Self.identifier, name:"Finder", filter:filter, in:library)
		self.loader = Loader(loadHandler:self.loadContainers)
	}


	/// Converts a file URL to a unique identifier
	
	public class func identifier(for url:URL) -> String
	{
		url.absoluteString
	}
	
	
	/// Converts a unique identifier back to a file URL
	
	public class func url(for identifier:String) throws -> URL
	{
		guard let url = URL(string:identifier) else { throw Container.Error.notFound }
		return url
	}


	/// Loads the top-level containers of this source.
	///
	/// Subclasses can override this function, e.g. to load top level folder from the preferences file
	
	private func loadContainers(with sourceState:[String:Any]? = nil, filter:Object.Filter, in library:Library?) async throws -> [Container]
	{
		FolderSource.log.debug {"\(Self.self).\(#function) \(identifier)"}
		
		guard let filter = filter as? FolderFilter else { throw Container.Error.loadContentsFailed }
		
		// Add initial set of default containers
		
		var containers:[Container] = try await self.defaultContainers(with:filter)
		
		// Load stored bookmarks from state. Convert each bookmark to a folder url. If the folder
		// still exists, then create a FolderContainer for it.

		#if os(macOS)
		
		if let bookmarks = sourceState?[Self.bookmarksKey] as? [Data]
		{
			let folderURLs = bookmarks
				.compactMap { URL(with:$0) }
				.filter { $0.exists && $0.isDirectory }
				.filter { $0.startAccessingSecurityScopedResource() }
				
			for folderURL in folderURLs
			{
				guard !isDuplicate(folderURL, in:containers) else { continue }
				let container = try self.createContainer(for:folderURL, filter:filter, in:library)
				containers += container
			}
		}
		
		#else
		
		#warning("TODO: implement for iOS")
		
		#endif
		
		return containers
	}


	/// Creates a Container for the folder at the specified URL. Subclasses can override this
	/// function to filter out some directories or return more specific Container subclasses.
	
	open func createContainer(for url:URL, filter:FolderFilter, in library:Library?) throws -> Container?
	{
		FolderSource.log.verbose {"\(Self.self).\(#function) \(url)"}

		return FolderContainer(
			url: url,
			filter: filter,
			removeHandler: { [weak self] in self?.removeTopLevelContainer($0) },
			in: library)
	}


	/// Removes the specified top-level Container again
	
	open func removeTopLevelContainer(_ container:Container)
	{
		let title = NSLocalizedString("Alert.title.removeFolder", bundle:.BXMediaBrowser, comment:"Alert Title")
		let message = String(format:NSLocalizedString("Alert.message.removeFolder", bundle:.BXMediaBrowser, comment:"Alert Message"), container.name)
		let ok = NSLocalizedString("Remove", bundle:.BXMediaBrowser, comment:"Button Title")
		let cancel = NSLocalizedString("Cancel", bundle:.BXMediaBrowser, comment:"Button Title")
		
		#if os(macOS)
		
		NSAlert.presentModal(style:.critical, title:title, message:message, okButton:ok, cancelButton:cancel)
		{
			[weak self] in self?.removeContainer(container)
		}
		
		#else
		
		#warning("TODO: implement for iOS")
		
		#endif
	}
	
	
//----------------------------------------------------------------------------------------------------------------------


	/// Returns true if there is already a Container with the specified URL
	
	open func isDuplicate(_ url:URL, in containers:[Container]) -> Bool
	{
		for container in containers
		{
			if let otherURL = container.data as? URL, url == otherURL { return true }
		}
		
		return false
	}
	
	
	// To be overridden by subclasses
	
	open func defaultContainers(with filter:FolderFilter) async throws -> [Container]
	{
		return []
	}


	/// Return true if the default containers have been installed
	
	open var didAddDefaultContainers:Bool
	{
		let key = "BXMediaBrowser-\(Self.self)-didAddDefaultContainers"
		let didAdd = UserDefaults.standard.bool(forKey:key)
		UserDefaults.standard.set(true, forKey:key)
		return didAdd
	}
	
	@MainActor open func requestReadAccessRights(for folder:URL) -> URL?
	{
		if folder.isReadable { return folder }
		
		let name = folder.lastPathComponent
		let format = NSLocalizedString("Panel.message", bundle:.BXMediaBrowser, comment:"Panel Message")
		let allow = NSLocalizedString("Allow", bundle:.BXMediaBrowser, comment:"Button Title")
		let message = String(format:format, name)
		
		var url:URL? = nil
		
		#if os(macOS)
		
		NSOpenPanel.presentModal(title:message, message:message, buttonLabel:allow, directoryURL:folder, canChooseFiles:false, canChooseDirectories:true, allowsMultipleSelection:false)
		{
			urls in
			url = urls.first
		}
		
		#endif
		
		return url
	}
	
	
//----------------------------------------------------------------------------------------------------------------------


	override public func state() async -> [String:Any]
	{
		var state = await super.state()
		
		let bookmarks = await self.containers
			.compactMap { $0 as? FolderContainer }
			.compactMap { $0.data as? Data }
		
		state[Self.bookmarksKey] = bookmarks

		return state
	}

	internal static var bookmarksKey:String { "bookmarks" }


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
