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


//----------------------------------------------------------------------------------------------------------------------


/// EfficientVStack resolves to a LazyVStack (if available) or to a (less efficient) VStack as a fallback

public struct EfficientVStack<Content:View> : View
{
	private var alignment:HorizontalAlignment
	private var spacing:CGFloat?
	private var content:()->Content
	
	// Init
	
    public init(alignment:HorizontalAlignment = .center, spacing:CGFloat? = nil, @ViewBuilder content:@escaping ()->Content)
	{
		self.alignment = alignment
		self.spacing = spacing
		self.content = content
	}
	
	// View
	
	public var body: some View
    {
		if #available(macOS 11.0, iOS 14.0, *)
		{
			LazyVStack(alignment:alignment, spacing:spacing)
			{
				content()
			}
		}
		else
		{
			VStack(alignment:alignment, spacing:spacing)
			{
				content()
			}
		}
    }
}


//----------------------------------------------------------------------------------------------------------------------
