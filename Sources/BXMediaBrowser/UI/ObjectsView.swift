//
//  ObjectsView.swift
//  MediaBrowserTest
//
//  Created by Peter Baumgartner on 04.12.21.
//

import SwiftUI
import Combine


//----------------------------------------------------------------------------------------------------------------------


public struct EmptyObjectsView : View
{
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
		ScrollView
		{
			LazyVStack(alignment:.leading, spacing:0)
			{
				ForEach(container.objects)
				{
					object in
//					SwiftUIFactory.shared.view(for:object)
					ObjectCell(object:object, isSelected:selectedObjectIdentifiers.contains(object.identifier))
					
						.onTapGesture
						{
							self.select(object)
						}
				}
			}
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
	// Data Model
	
	@ObservedObject var container:Container
	
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
 
