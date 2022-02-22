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

import AppKit


//----------------------------------------------------------------------------------------------------------------------


extension Object
{
	/// Returns a NSFilePromiseProvider that has this Object attached to it.
	
	@MainActor var filePromiseProvider:NSFilePromiseProvider
	{
		let uti = self.localFileUTI
		let provider = ObjectFilePromiseProvider(object:self, fileType:uti, delegate:self)
		provider.userInfo = self
		return provider
	}
}


//----------------------------------------------------------------------------------------------------------------------


extension Object : NSFilePromiseProviderDelegate
{
	/// Returns a background queue for performing the file download/copy operation.
	
	public func operationQueue(for filePromiseProvider:NSFilePromiseProvider) -> OperationQueue
    {
        return Self.promiseQueue
    }
    
	public static let promiseQueue = OperationQueue()
	
	/// Returns the filename of the promised file.
	
	public func filePromiseProvider(_ filePromiseProvider:NSFilePromiseProvider, fileNameForType fileType:String) -> String
    {
		self.localFileName
    }
    
    /// Fulfills the promise by copying the file to the final destination.
	
	public func filePromiseProvider(_ filePromiseProvider:NSFilePromiseProvider, writePromiseTo dstURL:URL) async throws
    {
		// Get the local file url. This might trigger a download if the Object is still in the cloud.
		
		let localURL = try await self.localFileURL
		
		// If the local file url doesn't match the requested dstURL, then copy it to this destination.
		
		if localURL != dstURL
		{
			do
			{
				try FileManager.default.linkItem(at:localURL, to:dstURL)
			}
			catch
			{
				do
				{
					try FileManager.default.copyItem(at:localURL, to:dstURL)
				}
				catch let error
				{
					logDragAndDrop.error {"\(Self.self).\(#function) ERROR \(error)"}
				}
			}
		}
    }
}


//----------------------------------------------------------------------------------------------------------------------


extension Object
{
	/// This global dictionary stores references to dragged Objects by identifier
	
	private static var draggedObjects:[String:Object] = [:]
	
	/// Sets the dragged Object for the specified identifier
	
	public static func setDraggedObject(_ object:Object?, for identifier:String)
	{
		if object == nil
		{
			DispatchQueue.main.asyncAfter(deadline:.now() + 30)
			{
				Self.draggedObjects[identifier] = object
			}
		}
		else
		{
			Self.draggedObjects[identifier] = object
		}
	}

	/// Returns the dragged Object for the specified identifier
	
	public static func draggedObject(for identifier:String) -> Object?
	{
		Self.draggedObjects[identifier]
	}
}


//----------------------------------------------------------------------------------------------------------------------


#endif
