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


/// ObjectFilePromiseProvider is a subclass of NSFilePromiseProvider that carries additional information about a
/// dragged Object.
///
/// Unfortunately only Plist-style datatypes can be used, wo we cannot attach the dragged Object itself. So instead
/// the identifier of the dragged Object is attached. This identifier can be used by the NSFilePromiseReceiver to
/// retrieve the in-memory instance of the dragged Object.
///
/// Insprired by: https://buckleyisms.com/blog/how-to-actually-implement-file-dragging-from-your-app-on-mac/

public class ObjectFilePromiseProvider : NSFilePromiseProvider
{
	/// The native Object that is attached to this NSFilePromiseProvider
	
	public var object:Object? = nil
	{
		didSet { self.storeDraggedObject() }
	}
	
	/// This type identifies the native Object on the NSPasteboard
	
	public static let objectIdentifierType = NSPasteboard.PasteboardType.string
	
	
//----------------------------------------------------------------------------------------------------------------------


	/// Creates a new ObjectFilePromiseProvider with an attached Object
	
	public convenience init(object:Object?, fileType:String, delegate:NSFilePromiseProviderDelegate)
	{
		self.init(fileType:fileType, delegate:delegate)
		self.object = object
		self.storeDraggedObject()
	}
	
	/// Stores a reference to the dragged Object in the global dictionary 
	
	private func storeDraggedObject()
	{
		if let object = self.object
		{
			Object.setDraggedObject(object, for:object.identifier)
		}
	}

	// When the NSFilePromiseProvider is released, also release the reference to the dragged Object
	
	deinit
	{
		if let object = object
		{
			Object.setDraggedObject(nil, for:object.identifier)
		}
	}
	
	
//----------------------------------------------------------------------------------------------------------------------


	// If we have an attached native Object, then add objectIdentifierType
	
    public override func writableTypes(for pasteboard:NSPasteboard) -> [NSPasteboard.PasteboardType]
    {
        var types = super.writableTypes(for:pasteboard)
        
        if object != nil
        {
			types.append(Self.objectIdentifierType)
        }
        
        return types;
    }

	// Not need for writingOptions for in-memory drags of native Objects

    public override func writingOptions(forType type:NSPasteboard.PasteboardType, pasteboard:NSPasteboard) -> NSPasteboard.WritingOptions
    {
        if type == Self.objectIdentifierType
        {
            return []
        }

        return super.writingOptions(forType:type, pasteboard:pasteboard)
    }

	// When requested, return the identifier of the attached Object
	
    public override func pasteboardPropertyList(forType type:NSPasteboard.PasteboardType) -> Any?
    {
        if type == Self.objectIdentifierType
        {
            return self.object?.identifier
        }

        return super.pasteboardPropertyList(forType:type)
    }
}


//----------------------------------------------------------------------------------------------------------------------


#endif
