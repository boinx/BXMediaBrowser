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


public struct ObjectInfoView : View
{
	// Model
	
	@ObservedObject var object:Object
	
	@State private var isLoading = false
	
	// Init
	
	public init(with object:Object)
	{
		self.object = object
	}
	
	// View
	
	public var body: some View
    {
		ScrollView([.horizontal,.vertical])
		{
			BXGrid(columnCount:2)
			{
				ForEach(metadataArray, id:\.self.0)
				{
					line in
					
					BXGridRow
					{
						BXGridCell(0)
						{
							Text(line.0)
								.bold()
						}
						
						BXGridCell(1)
						{
							Text(line.1)
								.truncationMode(.tail)
//								.leftAligned()
								.frame(minWidth:50, maxWidth:200, alignment:.leading)
						}
					}
				}
			}
			.controlSize(.small)
			.padding(12)
		}
		.frame(minWidth:160, maxWidth:320, minHeight:60, maxHeight:200)
    }
    
    @MainActor var metadataArray:[(String,String)]
    {
		let dict = object.metadata ?? [:]
		var array:[(String,String)] = []
		
		for (key,value) in dict
		{
			array += ("\(key)","\(value)")
		}
		
		return array
    }
}


//----------------------------------------------------------------------------------------------------------------------
