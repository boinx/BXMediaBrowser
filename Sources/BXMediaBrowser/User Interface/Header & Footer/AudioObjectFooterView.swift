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
import BXSwiftUtils
import SwiftUI
import AVKit


//----------------------------------------------------------------------------------------------------------------------


public struct AudioObjectFooterView : View
{
	// Model
	
	@ObservedObject var container:Container
	
	// View
	
	public var body: some View
    {
		HStack
		{
			// Thumbnail size
			
//			Text("▶︎ Audio Player")

			AudioPlayerView(url:nil)
				.frame(height:22)
			
			Spacer()
			
			// Object count
			
			Text(container.localizedObjectCount)
				.controlSize(.small)
		}
		.padding(.horizontal,20)
		.padding(.vertical,8)
    }
}


//----------------------------------------------------------------------------------------------------------------------


/// This subclass of NSCollectionView can display the Objects of a Container

public struct AudioPlayerView : NSViewRepresentable
{
	// This NSViewRepresentable doesn't return a single view, but a whole hierarchy:
	//
	// 	 NSScrollView
	//	    NSClipView
	//	       NSCollectionView
	
	public typealias NSViewType = AVPlayerView

	private var url:URL? = nil


//----------------------------------------------------------------------------------------------------------------------


	/// Creates ObjectCollectionView with the specified Container and cell type
	
	public init(url:URL? = nil)
	{
		self.url = url
	}
	
	/// Builds a view hierarchy with a NSScrollView and a NSCollectionView inside
	
	public func makeNSView(context:Context) -> AVPlayerView
	{
		let playerView = AVPlayerView(frame:.zero)
		context.coordinator.player = playerView.player
//		playerView.controlsStyle = .floating
		return playerView
	}
	
	
	// The selected Container has changed, pass it on to the Coordinator
	
	public func updateNSView(_ playerView:AVPlayerView, context:Context)
	{
//		if let url = self.url
//		{
//			let item = AVPlayerItem(url:url)
//			playerView.player?.replaceCurrentItem(with:item)
//		}
//		else
//		{
//			playerView.player?.replaceCurrentItem(with:nil)
//		}
	}

	/// Creates the Coordinator which provides persistant state to this view

	public func makeCoordinator() -> Coordinator
    {
		return Coordinator()
    }


	public class Coordinator : NSObject
    {
		var player:AVPlayer? = nil
		var observers:[Any] = []
		
		override init()
		{
			super.init()

			self.observers += NotificationCenter.default.publisher(for:NSNotification.Name("selectedObjectURL"), object:nil).sink
			{
				if let url = $0.object as? URL
				{
					let item = AVPlayerItem(url:url)
					self.player?.replaceCurrentItem(with:item)
				}
				else
				{
					self.player?.replaceCurrentItem(with:nil)
				}
			}
		}
	}
	
}
