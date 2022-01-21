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


public struct FolderContainerView : View
{
	// Model
	
	@ObservedObject var container:Container

	/// Returns true if this Container is currently a drop target
	
	@State private var isDropTarget = false
	
	// Init
	
	public init(with container:Container)
	{
		self.container = container
	}
	
	// View
	
	public var body: some View
    {
		ContainerView(with:container)
		
			.id(container.identifier)

			.background(dropTargetView)
			
//			.onDrop(of:dropTypes, delegate: DropDelegate)

			.onDrop(of:dropTypes, isTargeted:self.$isDropTarget)
			{
				(itemProviders:[NSItemProvider])->Bool in
				
				for itemProvider in itemProviders
				{
//					if let receiver = itemProvider as? NSFilePromiseReceiver
//					{
//						print("didDrop \(receiver)")
//					}

//					let ok = itemProvider.canLoadObject(ofClass:NSFilePromiseReceiver.self)
//					print("has NSFilePromiseReceiver \(ok)")
					
//					let progress = itemProvider.loadFileRepresentation(forTypeIdentifier:"com.apple.pasteboard.promised-file-content-type")
//					{
//						url,error in
//
//						print("didDrop \(url) \(error)")
//					}
					
//					let progress = itemProvider.loadObject(ofClass:NSFilePromiseReceiver.self)
//					{
//						(reader:NSItemProviderReading?, error:Error?) -> Void in
//
//						if let error = error
//						{
//							print("didDrop ERROR \(error)")
//						}
//						else if let reader = reader
//						{
//							print("didDrop \(reader)")
//						}
//					}
				}
				
				return true
			}
    }
    
    /// Returns a background view that highlights the current drop target Container
	
	var dropTargetView: some View
    {
		GeometryReader
		{
			dropTargetColor
				.frame(width:$0.size.width+1000, height:20, alignment:.top)
				.offset(x:-900, y:0)
		}
    }

	/// Returns the background color for this Container
	
    var dropTargetColor:Color
    {
		isDropTarget ? .primary.opacity(0.15) : .clear
    }
    
    var dropTypes:[String]
    {
		var types = NSFilePromiseReceiver.readableDraggedTypes
//		types += "public.url"
		return types
    }
}


//----------------------------------------------------------------------------------------------------------------------


//struct URLDropDelegate: DropDelegate
//{
//    @Binding var urlItems: [URLItem]
//
//    func performDrop(info:DropInfo) -> Bool
//    {
//        guard info.hasItemsConforming(to: ["public.url"]) else {
//            return false
//        }
//
//        let items = info.itemProviders(for: ["public.url"])
//
//        for item in items {
//            _ = item.loadObject(ofClass: URL.self) { url, _ in
//                if let url = url {
//                    DispatchQueue.main.async {
//                        self.urlItems.insert(URLItem(link: url), at: 0)
//                    }
//                }
//            }
//        }
//
//        return true
//    }
//}


//----------------------------------------------------------------------------------------------------------------------


