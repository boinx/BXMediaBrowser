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
import UniformTypeIdentifiers


//----------------------------------------------------------------------------------------------------------------------


/// This view can be added as an overlay to a existing view. The externally supplied didDropFileHandler
/// will be called for each fileURL that is dropped onto this view.

public struct FileURLDropTargetView : View
{
	// Params
	
	private var color:Color = Color.accentColor.opacity(0.5)
	private var didDropFileHandler:(URL)->Void
	@State private var isDropTarget = false
	
	// Init
	
	public init(color:Color = .accentColor.opacity(0.5), didDropFileHandler:@escaping (URL)->Void)
	{
		self.color = color
		self.didDropFileHandler = didDropFileHandler
	}

	// Build View
	
	public var body: some View
	{
		#if os(macOS)
		
		// Unfortunately the .onDrop modifiers are only available for macOS 11 and newer. Create a clear view
		// with a drop handler for file URLs that call through to the externally supplied didDropFolder closure.
		
		if #available(macOS 11, iOS 13, *)
		{
			Color.clear

				// Attach a drop handler for fileURLs
				
				.onDrop(of:[UTType.fileURL], isTargeted:$isDropTarget)
				{
					providers in self.drop(providers)
				}
				
				// Highlight view when targeted
				
				.border(dropTargetColor, width:4)
		}
		
		// No functionality for macOS Catalina
		
		else
		{
			Color.clear
				.frame(width:0, height:0)
		}
		
		#else
		
		// Not implemented for iOS
		
		Color.clear
			.frame(width:0, height:0)

		#endif
	}
}


//----------------------------------------------------------------------------------------------------------------------


#if os(macOS)

public extension FileURLDropTargetView
{
	/// This function tries to extract a fileURL from each NSItemProvider and calls the didDropFileHandler for
	/// each fileURL.
	
    func drop(_ itemProviders:[NSItemProvider]) -> Bool
    {
		var hasURL = false
		
		for provider in itemProviders
		{
			if provider.hasItemConformingToTypeIdentifier(kUTTypeFileURL as String)
			{
				hasURL = true
			}

			provider.loadItem(forTypeIdentifier:kUTTypeFileURL as String, options:nil)
			{
				data,error in
				guard error == nil else { return }
				guard let data = data as? Data else { return }
				guard let url = URL(dataRepresentation:data, relativeTo:nil) else { return }
				guard url.isFileURL else { return }
				self.didDropFileHandler(url)
			}
		}
		
		return hasURL
    }
    
    /// Returns the highlight color for this view if a drop is currently happening
	
    var dropTargetColor:Color
    {
		isDropTarget ? color : .clear
    }
}

#endif


//----------------------------------------------------------------------------------------------------------------------
