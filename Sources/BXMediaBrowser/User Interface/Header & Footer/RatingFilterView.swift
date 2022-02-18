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
import SwiftUI


//----------------------------------------------------------------------------------------------------------------------


public struct RatingFilterView : View
{
	private var rating:Binding<Int>
	
	private var maxRating:Int
	
	@Environment(\.controlSize) private var controlSize
	
	var size:CGFloat
	{
		switch controlSize
		{
			case .small: return 12.0
			case .mini: return 9.0
			default: return 16.0
		}
	}
	
	// Init
	
	public init(rating:Binding<Int>, maxRating:Int = 5)
	{
		self.rating = rating
		self.maxRating = maxRating
	}
	
	// View
	
	public var body: some View
    {
		// Draw 5 stars
		
		HStack(spacing:2)
		{
			if #available(macOS 11, *)
			{
				ForEach(1..<maxRating+1)
				{
					i in

					SwiftUI.Image(systemName:icon(for:i))
						.foregroundColor(color(for:i))
				}
			}
		}
		
		// On drag change the rating filter value
		
//		.contentShape(Rectangle())
		.gesture( DragGesture(minimumDistance:0).onChanged
		{
			setRating(with:$0)
		}
		.onEnded
		{
			setRating(with:$0)
		})
	}
	
	/// Returns the icon name for the specified index
	
    func icon(for index:Int) -> String
    {
		let rating = self.rating.wrappedValue
		let icon = index <= rating ? "star.fill" : "star"
		return icon
    }

	/// Returns the icon color for the specified index
	
    func color(for index:Int) -> Color
    {
		let rating = self.rating.wrappedValue
		return index <= rating ? Color.yellow : Color.gray
    }

	/// Changes the rating filter value according to the mouse location
	
	func setRating(with drag:DragGesture.Value)
	{
		let w:CGFloat = CGFloat(maxRating) * size
		let f = CGFloat(maxRating)
		let x = drag.location.x + 12

		self.rating.wrappedValue = Int(f*x/w).clipped(to:0...maxRating)
	}
}


//----------------------------------------------------------------------------------------------------------------------


