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
import BXSwiftUI


//----------------------------------------------------------------------------------------------------------------------


public struct AudioObjectFooterView : View
{
	// Model
	
	@ObservedObject var container:Container
	
	// Init
	
	public init(container:Container)
	{
		self.container = container
	}
	
	// View
	
	public var body: some View
    {
		HStack
		{
			AudioPlayerView()

			Text(container.localizedObjectCount)
				.controlSize(.small)
				.lineLimit(1)
		}
		.padding(.horizontal,20)
		.padding(.vertical,8)
    }
}


//----------------------------------------------------------------------------------------------------------------------


/// Displays the user interface for the AudioPreviewController

public struct AudioPlayerView : View
{
	// Model

	@EnvironmentObject var controller:AudioPreviewController
	
	// Build View
	
	public var body: some View
    {
		HStack
		{
			BXImage(systemName:"gobackward.15")
				.contentShape(Rectangle().inset(by:-6))
				.onTapGesture
				{
					self.controller.jump(by:-15)
				}

			BXImage(systemName:iconName)
				.contentShape(Rectangle().inset(by:-6))
				.onTapGesture
				{
					self.controller.toggle()
				}

			BXImage(systemName:"goforward.15")
				.contentShape(Rectangle().inset(by:-6))
				.onTapGesture
				{
					self.controller.jump(by:+15)
				}
				
			Text(controller.time.shortTimecodeString())
				.frame(width:54, alignment:.leading)
				
			TimeSlider(fraction:self.$controller.fraction)
				.frame(height:12)
		}
		.reducedOpacityWhenDisabled()
		.enabled(controller.isEnabled)
		
		
    }
    
    /// Return the icon name for the play/pause button
	
    public var iconName:String
    {
		controller.isPlaying ? "pause.fill" : "play.fill"
    }
}


//----------------------------------------------------------------------------------------------------------------------


/// Displays a slide for setting the audio playback position

public struct TimeSlider : View
{
	// Model
	
	@Binding var fraction:Double
	
	// Build View
	
	public var body: some View
    {
		GeometryReader
		{
			geometry in
			
			ZStack(alignment:.leading)
			{
				self.trackColor.frame(height:2)
				self.thumbColor.frame(width:2).offset(x:offset(for:geometry), y:0)
			}
			.contentShape(Rectangle())
			.gesture(DragGesture(minimumDistance:0.0).onChanged
			{
				let fraction = $0.location.x / geometry.size.width
				self.fraction = fraction
			})
		}
		
    }
    
    /// Returns the offset (in points from left edge) of the playback position
	
    func offset(for geometry:GeometryProxy) -> CGFloat
    {
		let W = geometry.size.width - 2
		let w = W * self.fraction
		return w
    }
    
    /// Color of the slider track
	
    var trackColor:Color
    {
		Color.primary.opacity(0.2)
	}
	
	/// Color of the slider thumb
	
	var thumbColor:Color
	{
		Color.primary
	}
}


//----------------------------------------------------------------------------------------------------------------------
