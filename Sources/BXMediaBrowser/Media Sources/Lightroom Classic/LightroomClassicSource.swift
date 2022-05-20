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
import SwiftUI


//----------------------------------------------------------------------------------------------------------------------


open class LightroomClassicSource : Source, AccessControl
{
	/// The unique identifier of this source must always remain the same. Do not change this identifier, even if the
	/// class name changes due to refactoring, because the identifier  might be stored in a preferences file or user
	/// documents.
	
	static let identifier = "LightroomClassic:"
	
	/// Returns the mediaTypes that are supported by this Source
	
	public let mediaType:Object.MediaType
	
	/// The IMBLightroomParserMessenger is our gateway to the legacy ObjC iMedia code
	
	public let parserMessenger:IMBLightroomParserMessenger
	
	
//----------------------------------------------------------------------------------------------------------------------


	/// Creates a new Source for local file system directories
	
	public init(mediaType:Object.MediaType)
	{
		LightroomClassic.log.debug {"\(Self.self).\(#function)"}
		
		self.mediaType = mediaType
		
		if mediaType == .image
		{
			self.parserMessenger = IMBLightroomImageParserMessenger()
		}
		else
		{
			self.parserMessenger = IMBLightroomMovieParserMessenger()
		}
		
		super.init(
			identifier: Self.identifier,
			icon: LightroomClassic.shared.icon,
			name: "Adobe Lightroom Classic",
			filter: LightroomClassicFilter())
		
		self.loader = Loader(loadHandler:self.loadContainers)
	}
	

//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Login
	

	@MainActor public var hasAccess:Bool
	{
		LightroomClassic.shared.error == nil
	}
	
	
	@MainActor public func grantAccess(_ completionHandler:@escaping (Bool)->Void = { _ in })
	{
		guard let path = IMBLightroomParserMessenger.libraryPaths().first as? String else
		{
			completionHandler(false)
			return
		}
		
		let parentFolder = URL(fileURLWithPath:path).deletingLastPathComponent()
		let message = NSLocalizedString("GrantAccess.title", tableName:"LightroomClassic", bundle:.BXMediaBrowser, comment:"Alert Title")
		let button = NSLocalizedString("GrantAccess.button", tableName:"LightroomClassic", bundle:.BXMediaBrowser, comment:"Button Title")

		NSOpenPanel.presentModal(message:message, buttonLabel:button, directoryURL:parentFolder, canChooseFiles:false, canChooseDirectories:true, allowsMultipleSelection:false)
		{
			if let url = $0.first, url == parentFolder
			{
				if let bookmark = try? url.bookmarkData()
				{
					LightroomClassic.shared.libraryBookmark = bookmark
				}
				self.load()
				completionHandler(true)
			}
			else
			{
				completionHandler(false)
			}
		}
	}


	@MainActor public func revokeAccess(_ completionHandler:@escaping (Bool)->Void = { _ in })
	{
		#warning("TODO: implement")
	}


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Top Level Containers
	
	/// Loads the top-level containers of this source.
	///
	/// Subclasses can override this function, e.g. to load top level folder from the preferences file
	
	private func loadContainers(with sourceState:[String:Any]? = nil, filter:Object.Filter) async throws -> [Container]
	{
		LightroomClassic.log.debug {"\(Self.self).\(#function)"}

		guard let filter = filter as? LightroomClassicFilter else { return [] }
		let parserMessenger = self.parserMessenger
		
		do
		{
			// If access to the library was stored in a prefs bookmark, then restore the access rights
			
			self.restoreAccess(with:sourceState)

			// Get the top-level node from iMedia
			
			let rootNodes = try parserMessenger.unpopulatedTopLevelNodes().compactMap { $0 as? IMBNode }
			guard let rootNode = rootNodes.first else { return [] }
			
			// This top-level nodes in not of interest to us, so populate
			// it to get at its subnodes "Folders" and "Collections".
			
			_ = try parserMessenger.populateNode(rootNode)
			
			// Convert these two subnodes to native BXMediaBrowser Containers
			
			let containers:[LightroomClassicContainer] = rootNode.subnodes.compactMap
			{
				guard let node = $0 as? IMBNode else { return nil }
				return LightroomClassicContainer(node:node, mediaType:mediaType, parserMessenger:parserMessenger, filter:filter)
			}
			
			await MainActor.run
			{
				LightroomClassic.shared.error = nil
			}
			
			return containers
		}
		catch
		{
			LightroomClassic.log.error {"\(Self.self).\(#function) ERROR \(error)"}
		
			// Store any errors that have occured, so that the error message can be displayed in the UI
			
			await MainActor.run
			{
				LightroomClassic.shared.error = error
			}
		}
		
		return []
	}


//----------------------------------------------------------------------------------------------------------------------


	override public func state() async -> [String:Any]
	{
		var state = await super.state()
		
		if let bookmark = LightroomClassic.shared.libraryBookmark
		{
			state[libraryBookmarkKey] = bookmark
		}
		
		return state
	}
	
	internal var libraryBookmarkKey:String
	{
		"libraryBookmark"
	}
	
	// If access to the library was stored in a prefs bookmark, then restore the access rights
	
	func restoreAccess(with sourceState:[String:Any]? = nil)
	{
		guard let bookmark = (sourceState?[libraryBookmarkKey] as? Data) ?? LightroomClassic.shared.libraryBookmark else { return }
		guard let url = URL(with:bookmark) else { return }
		
		// Punch a hole into the sandbox
		
		_ = url.startAccessingSecurityScopedResource()
		
		// Store bookmark for the next app launch cycle
		
		LightroomClassic.shared.libraryBookmark = bookmark
	}
}


//----------------------------------------------------------------------------------------------------------------------


#endif
