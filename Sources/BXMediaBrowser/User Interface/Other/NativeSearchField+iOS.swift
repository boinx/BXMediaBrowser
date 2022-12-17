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


#if os(iOS)

import SwiftUI
import UIKit


//----------------------------------------------------------------------------------------------------------------------


struct NativeSearchField: UIViewRepresentable
{
    @Binding var value: String
	public var placeholderString:String?
	public var continuousUpdates = true
	public var onBegan:(()->Void)? = nil
	public var onEnded:(()->Void)? = nil

	public func makeUIView(context:Context) -> UISearchTextField
    {
        let searchField = UISearchTextField(frame:.zero)
        searchField.delegate = context.coordinator
        searchField.text = self.value
        searchField.placeholder = self.placeholderString
		return searchField
    }

	public func updateUIView(_ searchField:UISearchTextField, context:Context)
    {
        searchField.text = self.value
	}

    func makeCoordinator() -> Coordinator
    {
        return Coordinator(value:$value, continuousUpdates:continuousUpdates, onBegan:onBegan, onEnded:onEnded)
    }

    class Coordinator: NSObject, UISearchTextFieldDelegate
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
		
    	func textFieldDidBeginEditing(_ textField:UITextField) // became first responder
		{
			self.onBegan?()
		}
		
		func textFieldDidEndEditing(_ textField:UITextField)
		{
			self.value.wrappedValue = textField.text ?? ""
			self.onEnded?()
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
				.strokeBorder(Color.primary.opacity(0.3), lineWidth:0.5)
				.padding(0.5)
		)
	}
}


//----------------------------------------------------------------------------------------------------------------------


#endif
