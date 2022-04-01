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


public struct DefaultObjectFooterView : View
{
	// Model
	
	@ObservedObject var container:Container
	@ObservedObject var uiState:UIState
	
	// Init
	
	public init(container:Container, uiState:UIState)
	{
		self.container = container
		self.uiState = uiState
	}
	
	// View
	
	public var body: some View
    {
		HStack(spacing:4)
		{
			// Thumbnail size
			
			BXImage(systemName:"square").scaleEffect(0.5)
			
			Slider(value:self.sliderResponse, in:0.4...1.0)
				.controlSize(.mini)
				.frame(width:100)

			BXImage(systemName:"square")

			Spacer()
			
			// Object count
			
			Text(container.localizedObjectCount)
				.controlSize(.small)
				.lineLimit(1)
		}
		.padding(.horizontal,20)
		.padding(.vertical,2)
    }
    
    var sliderResponse:Binding<Double>
    {
		let response = 3.0
		
		return Binding<Double>(
			get:{ pow(self.uiState.thumbnailScale, 1.0/response) },
			set:{ self.uiState.thumbnailScale = pow($0,response) })
    }
}


//----------------------------------------------------------------------------------------------------------------------
