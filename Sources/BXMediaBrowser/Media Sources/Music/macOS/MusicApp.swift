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


#if os(macOS)

import BXSwiftUtils
import BXSwiftUI
import AppKit


//----------------------------------------------------------------------------------------------------------------------


public class MusicApp : ObservableObject
{
	/// The shared singlton instance of this class
	
	public static let shared = MusicApp()
	
	/// A reference to the Library and MusicSource. Hopefully there is only one instance of this in your application or this property won't be of much use.
	
	public weak var library:Library? = nil
	public weak var source:MusicSource? = nil
	
	/// If any encountered audio file is not readable, then this property will be set to false, so that the UI can display the necessary authorization interface.

	@Published var isReadable = true
	
	/// When set this points to the root folder containing the media files. The use should grant access to this folder (it may be outside ~/Music) so that
	/// accessing the audio file is allowed by the sandbox.
	
	var rootFolderURL:URL? = nil
	
	/// Once the user has granted access to a folder, this property contains the URL to the folder.
	
	@Published var grantedFolderURL:URL? = nil
	
	/// Post a notification with this name when encountering a MusicObject that doesn't have the necessary read access rights
	
	static let musicObjectNotReadable = Notification.Name("MusicObject.notReadable")
	
	/// This notification is posted when access has been granted or revoked
	
	static let didChangeAccessRights = Notification.Name("MusicApp.didChangeAccessRights")
	

//----------------------------------------------------------------------------------------------------------------------


	/// Checking read access right is performed on this private serial queue
	
	private var analyzeQueue = DispatchQueue(label:"com.boinx.BXMediaBrowser.MusicSource.analyze")
	
	/// Internal observers and subscriptions
	
	private var observers:[Any] = []
		
	
//----------------------------------------------------------------------------------------------------------------------


	/// Creates a new Source for local file system directories
	
	private init()
	{
		MusicSource.log.verbose {"\(Self.self).\(#function)"}

		// If audio files are not readable, then find a common root folder and prompt the  user to grant access to this folder
		
		self.observers += NotificationCenter.default.publisher(for:Self.musicObjectNotReadable, object:nil)
			.receive(on:analyzeQueue)
			.sink
			{
				[weak self] in
				guard let url = $0.object as? URL else { return }
				self?.findRootFolder(for:url)
			}
	}


//----------------------------------------------------------------------------------------------------------------------


	/// This function is called in response to a notification that an audio file was encountered that is not readable. In this case, try to find the common
	/// root folder for all audio files, so that the user can grant read access rights to the sandbox.
	///
	/// Please note that due to performance reasons, this function is iterative, so unless ALL audio file are checked, then returned root folder may not
	/// be definitive, but only a subfolder.
	
	func findRootFolder(for audioFileURL:URL)
	{
		let parentFolderURL = audioFileURL.deletingLastPathComponent()
		var url = parentFolderURL
		
		if let rootFolderURL = self.rootFolderURL
		{
			url = rootFolderURL.commonAncestor(with:parentFolderURL) ?? parentFolderURL
		}

		self.rootFolderURL = url

		MusicSource.log.warning {"\(Self.self).\(#function) File not readable at \(audioFileURL.path) => rootFolder = \(url)"}

		DispatchQueue.main.asyncIfNeeded
		{
			self.isReadable = false
		}
	}
	
	
//----------------------------------------------------------------------------------------------------------------------


	/// Presents an NSOpenPanel so that the user can grant access to the root media folder.
	///
	/// If access was granted, the didChangeAccessRights notification is sent, so that the UI can update appropriately.
	
	@MainActor @discardableResult open func requestReadAccessRights(for folder:URL) -> URL?
	{
		if folder.isReadable { return folder }
		
		let name = folder.lastPathComponent
		let format = NSLocalizedString("Panel.message", bundle:.BXMediaBrowser, comment:"Panel Message")
		let allow = NSLocalizedString("Allow", bundle:.BXMediaBrowser, comment:"Button Title")
		let message = String(format:format, name)
		
		var url:URL? = nil
		
		NSOpenPanel.presentModal(title:message, message:message, buttonLabel:allow, directoryURL:folder, canChooseFiles:false, canChooseDirectories:true, allowsMultipleSelection:false)
		{
			urls in
			url = urls.first
		}
		
		if url != nil
		{
			self.isReadable = true
			self.grantedFolderURL = url
			NotificationCenter.default.post(name:Self.didChangeAccessRights, object:url)
		}

		return url
	}
	
	/// Revokes previously granted read access rights.
	
	@MainActor open func revokeReadAccessRights()
	{
		guard let grantedFolderURL = self.grantedFolderURL else { return }
		
		grantedFolderURL.stopAccessingSecurityScopedResource()
		self.grantedFolderURL = nil
		self.isReadable = false
		
		NotificationCenter.default.post(name:Self.didChangeAccessRights, object:nil)
	}
	
}
	
	
//----------------------------------------------------------------------------------------------------------------------


#endif
