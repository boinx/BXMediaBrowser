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


extension NSPasteboard
{
	/// Returns the list of native Objects (if any) that are on this NSPasteboard
	
	public var mediaBrowserObjects:[Object]?
	{
		guard let pasteboardItems = self.pasteboardItems else { return nil }

		// Read the identifier from its own private type. Reading NSString off the pasteboard would
		// pick up any text that happens to be there, and no longer finds the identifier at all now
		// that it is not written with the generic string pasteboard type.

		let identifiers = pasteboardItems.compactMap { $0.string(forType:ObjectFilePromiseProvider.objectIdentifierType) }

		let objects = identifiers.compactMap { Object.draggedObject(for:$0) }
		return objects.count > 0 ? objects : nil
	}

	/// Returns the list of file URLs (if any) that are on this NSPasteboard

	public var fileURLs:[URL]?
	{
        let options:[NSPasteboard.ReadingOptionKey:Any] = [ .urlReadingFileURLsOnly:true ]
		guard let urls = self.readObjects(forClasses:[NSURL.self], options:options) as? [URL] else { return nil }
		guard !urls.isEmpty else { return nil }
		return urls
	}
}


//----------------------------------------------------------------------------------------------------------------------


#endif
