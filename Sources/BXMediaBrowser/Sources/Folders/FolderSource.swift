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
		super.init(identifier:Self.identifier, name:"Finder")
		self.loader = Loader(identifier:self.identifier, loadHandler:Self.loadContainers)
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
	
	private class func loadContainers(with sourceState:[String:Any]? = nil) async throws -> [Container]
	{
		var containers:[Container] = []
		
		for (_,value) in sourceState ?? [:]
		{
			if let containerState = value as? [String:Any],
			   let bookmark = containerState["url"] as? Data,
			   let folderURL = URL(with:bookmark)
			{
				if folderURL.startAccessingSecurityScopedResource()
				{
					let container = try Self.createContainer(for:folderURL)
					containers += container

					folderURL.stopAccessingSecurityScopedResource()
				}
			}
		}
		
		return containers
	}


	/// Creates a Container for the folder at the specified URL.
	///
	/// Subclasses can override this function to filter out some directories.
	
	open class func createContainer(for url:URL) throws -> Container?
	{
		guard url.exists else { throw Container.Error.notFound }
		guard url.isDirectory else { throw Container.Error.notFound }
		return FolderContainer(url:url)
	}


	public var hasAccess:Bool { true }
	
	public func grantAccess(_ completionHandler:@escaping (Bool)->Void)
	{
		completionHandler(hasAccess)
	}


}


//----------------------------------------------------------------------------------------------------------------------
