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
#else
import UIKit
#endif


//----------------------------------------------------------------------------------------------------------------------


extension URL
{
	/// Opens a remote URL in a web browser
	
	public func open()
	{
		#if os(macOS)
		
		NSWorkspace.shared.open(self)
		
		#else
		
		#warning("TODO: implement")
		
		#endif
	}
	
	/// Reveals a file URL in the Finder
	
	public func reveal()
	{
		guard self.exists else { return }
		
		#if os(macOS)
		
		NSWorkspace.shared.selectFile(self.path, inFileViewerRootedAtPath:self.deletingLastPathComponent().path)

		#else
		
		#warning("TODO: implement")

		#endif
	}
	
	/// Copies a file URL to the specified destination. If possible the file will be hard linked to save
	/// disk space and speed up the operation.
	
	public func fastCopy(to dstURL:URL) throws
	{
		do
		{
			if dstURL.exists
			{
				try? FileManager.default.removeItem(at:dstURL)
			}
			
			try FileManager.default.linkItem(at:self, to:dstURL)
		}
		catch
		{
			try FileManager.default.copyItem(at:self, to:dstURL)
		}
	}
	
}


//----------------------------------------------------------------------------------------------------------------------

