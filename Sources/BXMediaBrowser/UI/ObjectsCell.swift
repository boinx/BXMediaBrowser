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
import Combine


//----------------------------------------------------------------------------------------------------------------------


public struct ObjectCell : View
{
	// Data Model
	
	@ObservedObject var object:Object
	var isSelected:Bool
	
	// Build View
	
	public var body: some View
    {
		HStack(alignment:.top)
		{
			// Display thumbnail if already loaded
			
			if let image = object.thumbnailImage
			{
				Image(image, scale:1.0, orientation:.up, label:Text("Thumbnail"))
					.resizable()
					.scaledToFit()
					.border(Color.primary.opacity(0.2))
					.frame(width:160, height:90, alignment:.center)
			}
			
			// Display a placeholder with spinning wheel if still loading
			
			else
			{
				ZStack
				{
					Color.primary
						.opacity(0.1)
						.frame(width:160, height:90)
						.border(Color.primary.opacity(0.2))
						
					BXSpinningWheel(size: .regular)
				}
			}

			// Display image info
			
			VStack(alignment:.leading, spacing:3)
			{
				Text(object.name)
					.bold()
					.lineLimit(1)
					.leftAligned()
				
				if let metadata = object.metadata
				{
					if let w = metadata["PixelWidth"] as? Int, let h = metadata["PixelHeight"] as? Int
					{
						Text("Size: \(w) x \(h) pixels")
							.lineLimit(1)
							.opacity(0.5)
					}
	 
					if let model = metadata["ColorModel"] as? String
					{
						Text("Type: \(model)")
							.lineLimit(1)
							.opacity(0.5)
					}
					if let profile = metadata["ProfileName"] as? String
					{
						Text("Colorspace: \(profile)")
							.lineLimit(1)
							.opacity(0.5)
					}
				}
			}
		}
		.padding(.horizontal)
		.padding(.vertical,10)
		.background(backgroundColor)
		.foregroundColor(foregroundColor)
		.frame(minWidth:300)
		
		.contentShape(Rectangle())
		
		.onAppear
		{
			self.loadIfNeeded()
		}
    }
    
    var backgroundColor:Color
    {
		isSelected ? .accentColor : .clear
    }
    
    var foregroundColor:Color
    {
		isSelected ? .white : .primary
    }
    
    func loadIfNeeded()
    {
		if object.thumbnailImage == nil || object.metadata == nil
		{
			object.load()
		}
    }
}


//----------------------------------------------------------------------------------------------------------------------
 
