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
	/// The current rating value of the Object
	
	private var rating:Binding<Int>
	
	/// The maxRating value determies how many stars will be displayed
	
	private var maxRating:Int
	
	/// The initial rating at mouse down time
	
	@State private var initialRating:Int? = nil
	
	/// The controlsize determines the size of the stars
	
	@Environment(\.controlSize) private var controlSize
	
	var size:CGFloat
	{
		switch controlSize
		{
			case .small: return 12.0
			case .mini: return 9.0
			default: return 14.0
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
		
		HStack(spacing:0)
		{
			if #available(macOS 11, *)
			{
				ForEach(1..<maxRating+1)
				{
					BXSwiftUI.Image(systemName:icon(for:$0))
						.foregroundColor(color(for:$0))
			}
		}
		
		// On drag change the rating filter value
		
		.contentShape(Rectangle())
		
		.gesture( DragGesture(minimumDistance:0).onChanged
		{
			if self.initialRating == nil { self.initialRating = self.rating.wrappedValue } // On mouse down store initial rating
			self.setRating(with:$0)
		}
		.onEnded
		{
			self.setRating(with:$0, didEndGesture:true)
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

	/// Changes the rating value according to the mouse location
	
	func setRating(with drag:DragGesture.Value, didEndGesture:Bool = false)
	{
		let w:CGFloat = CGFloat(maxRating) * size
		let f = CGFloat(maxRating)
		let x = drag.location.x + size
		let i = Int(f * (x/w))
		
		// Calculate new rating depending on mouse position
		
		var rating = i.clipped(to:0...maxRating)
		
		// If new rating is same as intialRating on mouse up, then reset to 0. This provides a nicer UX.
		
		if didEndGesture
		{
			if let initialRating = initialRating, rating == initialRating { rating = 0 }
			self.initialRating = nil
		}
		
		// Store rating in data model
		
		self.rating.wrappedValue = rating
	}
}


//----------------------------------------------------------------------------------------------------------------------


