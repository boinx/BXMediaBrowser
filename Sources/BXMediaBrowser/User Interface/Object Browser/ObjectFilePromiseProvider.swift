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


import Foundation
import AppKit


//----------------------------------------------------------------------------------------------------------------------


public class ObjectFilePromiseProvider : NSFilePromiseProvider
{
	/// The native Object that is attached to this NSFilePromiseProvider
	
	public var object:Object? = nil
	
	/// This type identifies the native Object on the NSPasteboard
	
	public static let objectType = NSPasteboard.PasteboardType("com.boinx.BXMediaBrowser.Object")

	
//----------------------------------------------------------------------------------------------------------------------


	public convenience init(object:Object?, fileType:String, delegate:NSFilePromiseProviderDelegate)
	{
		self.init(fileType:fileType, delegate:delegate)
		self.object = object
	}
	
	
//----------------------------------------------------------------------------------------------------------------------


	// If we have an attached native Object, then add objectType
	
    public override func writableTypes(for pasteboard:NSPasteboard) -> [NSPasteboard.PasteboardType]
    {
        var types = super.writableTypes(for:pasteboard)
        if object != nil { types.append(Self.objectType) }
        return types;
    }

	// Not need for writingOptions for in-memory drags of native Object

    public override func writingOptions(forType type:NSPasteboard.PasteboardType, pasteboard:NSPasteboard) -> NSPasteboard.WritingOptions
    {
        if type == Self.objectType
        {
            return []
        }

        return super.writingOptions(forType:type, pasteboard:pasteboard)
    }

	// When requested, return the attached native Object
	
    public override func pasteboardPropertyList(forType type:NSPasteboard.PasteboardType) -> Any?
    {
        if type == Self.objectType
        {
            return self.object
        }

        return super.pasteboardPropertyList(forType:type)
    }
}


//----------------------------------------------------------------------------------------------------------------------
