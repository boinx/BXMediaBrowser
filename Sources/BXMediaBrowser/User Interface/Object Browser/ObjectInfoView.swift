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


import BXSwiftUI
import BXSwiftUtils
import SwiftUI


//----------------------------------------------------------------------------------------------------------------------


/// This struct contains the information for a single line in the ObjectInfoView

struct ObjectMetadataEntry : Identifiable
{
	let id = UUID().uuidString
	var label:String
	var value:String
	var action:(()->Void)? = nil
}


//----------------------------------------------------------------------------------------------------------------------


public struct ObjectInfoView : View
{
	// Model
	
	@ObservedObject var object:Object
	
	// Init
	
	public init(with object:Object)
	{
		self.object = object
	}
	
	// View
	
	public var body: some View
    {
		BXGrid(columnCount:2, spacing:CGSize(8,4))
		{
			ForEach(object.localizedMetadata)
			{
				entry in
				
				BXGridRow
				{
					BXGridCell(0, alignment:.trailing)
					{
						Text(entry.label)
							.bold()
					}
					
					BXGridCell(1, alignment:.leading)
					{
						Text(entry.value)
							.linkStyle(entry.action)
							.onOptionalTapGesture(entry.action)
							.lineLimit(nil)
//							.fixedSize(horizontal:ftruealse, vertical:true)
							.frame(maxWidth:180, alignment:.leading)
					}
				}
			}
		}
		.controlSize(.small)
		.foregroundColor(.primary)
		.padding(12)
    }
}


//----------------------------------------------------------------------------------------------------------------------


fileprivate extension View
{
	@ViewBuilder func onOptionalTapGesture(_ action:(()->Void)?) -> some View
	{
		if let action = action
		{
			self.onTapGesture(perform:action)
		}
		else
		{
			self
		}
	}
}


fileprivate extension Text
{
	@ViewBuilder func linkStyle(_ action:(()->Void)?) -> some View
	{
		if action != nil
		{
			self
				.underline()
				.foregroundColor(.accentColor)
		}
		else
		{
			self
		}
	}
}


//----------------------------------------------------------------------------------------------------------------------
