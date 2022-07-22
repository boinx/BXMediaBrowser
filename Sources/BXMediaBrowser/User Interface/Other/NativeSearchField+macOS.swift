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

import SwiftUI
import AppKit


//----------------------------------------------------------------------------------------------------------------------


struct NativeSearchField: NSViewRepresentable
{
    @Binding var value: String
	public var placeholderString:String?
	public var continuousUpdates = true
	public var onBegan:(()->Void)? = nil
	public var onEnded:(()->Void)? = nil

	public func makeNSView(context:Context) -> _NSSearchField
    {
        let searchField = _NSSearchField(frame:.zero)
        searchField.delegate = context.coordinator
        searchField.stringValue = self.value
        searchField.placeholderString = self.placeholderString
        searchField.onBegan = onBegan
        searchField.onEnded = onEnded
		return searchField
    }

	public func updateNSView(_ searchField:_NSSearchField, context:Context)
    {
        searchField.stringValue = self.value
	}

    func makeCoordinator() -> Coordinator
    {
        return Coordinator(value:$value, continuousUpdates:continuousUpdates, onBegan:onBegan, onEnded:onEnded)
    }

    class Coordinator: NSObject, NSSearchFieldDelegate,NSWindowDelegate
    {
		var value:Binding<String>
		var continuousUpdates = true
		var onBegan:(()->Void)? = nil
		var onEnded:(()->Void)? = nil

		init(value:Binding<String>, continuousUpdates:Bool, onBegan:(()->Void)?, onEnded:(()->Void)?)
		{
			self.value = value
			self.continuousUpdates = continuousUpdates
			self.onBegan = onBegan
			self.onEnded = onEnded
		}
		
//		func controlTextDidBeginEditing(_ notification:Notification)
//		{
//			self.onBegan?()
//		}

		func controlTextDidChange(_ notification:Notification)
		{
			guard let searchField = notification.object as? NSSearchField else { return }
			guard continuousUpdates else { return }
			self.value.wrappedValue = searchField.stringValue
		}
		
		func controlTextDidEndEditing(_ notification:Notification)
		{
			guard let searchField = notification.object as? NSSearchField else { return }
			self.value.wrappedValue = searchField.stringValue
			self.onEnded?()
		}

		func searchFieldDidEndSearching(_ searchField:NSSearchField)
		{
			self.value.wrappedValue = searchField.stringValue
		}
    }
}
 
 
//----------------------------------------------------------------------------------------------------------------------


extension NativeSearchField
{
	func strokeBorder() -> some View
	{
		self.overlay(
		
			RoundedRectangle(cornerRadius:6)
				.strokeBorder(Color.primary.opacity(0.5), lineWidth:0.5)
				.padding(0.5)
		)
	}
}


//----------------------------------------------------------------------------------------------------------------------


public class _NSSearchField : NSSearchField
{
	public var onBegan:(()->Void)? = nil
	public var onEnded:(()->Void)? = nil
	
	override open func becomeFirstResponder() -> Bool
	{
		self.onBegan?()
		return super.becomeFirstResponder()
	}
}


//----------------------------------------------------------------------------------------------------------------------


#endif
