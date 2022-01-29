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
import Combine


//----------------------------------------------------------------------------------------------------------------------


public struct EmptyObjectsView : View
{
	public init()
	{

	}
	
	public var body: some View
    {
		VStack
		{
			Spacer()
			Text("No Items").centerAligned()
			Spacer()
		}
    }
 }


//----------------------------------------------------------------------------------------------------------------------


public struct LoadingObjectsView : View
{
	public var body: some View
    {
		VStack
		{
			Spacer()
			BXSpinningWheel().centerAligned()
			Spacer()
		}
    }
 }


//----------------------------------------------------------------------------------------------------------------------


public struct LoadedObjectsView : View
{
	@ObservedObject var container:Container
	
	@State private var selectedObjectIdentifiers:[String] = []

	public var body: some View
    {
		let layout:[GridItem] = [GridItem(.adaptive(minimum:160))]
		
		return ScrollView
		{
			LazyVGrid(columns:layout, alignment:.leading, spacing:0)
			{
				ForEach(container.objects)
				{
					object in
					
					ObjectThumbnailCell(object:object, isSelected:selectedObjectIdentifiers.contains(object.identifier))

						.onTapGesture
						{
							self.select(object)
						}
				}
			}
			
//			LazyVStack(alignment:.leading, spacing:0)
//			{
//				ForEach(container.objects)
//				{
//					object in
//					ObjectDetailCell(object:object, isSelected:selectedObjectIdentifiers.contains(object.identifier))
//
//						.onTapGesture
//						{
//							self.select(object)
//						}
//				}
//			}
		}
    }
    
    func select(_ object:Object)
    {
		selectedObjectIdentifiers = [object.identifier]
    }
}


//----------------------------------------------------------------------------------------------------------------------


public struct ObjectsView : View
{
	// Model
	
	@ObservedObject var container:Container
	
	// Init
	
	public init(with container:Container)
	{
		self.container = container
	}
	
	// Build View
	
	public var body: some View
    {
		Group
		{
			if container.isLoading
			{
				LoadingObjectsView()
			}
			else if container.isLoaded && !container.objects.isEmpty
			{
				LoadedObjectsView(container:container)
			}
			else
			{
				EmptyObjectsView()
			}
		}
		.id(container.identifier)
    }
}


//----------------------------------------------------------------------------------------------------------------------
 
