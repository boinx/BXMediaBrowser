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
import AVKit


//----------------------------------------------------------------------------------------------------------------------


public class AudioPlayerController : NSObject, ObservableObject, AVAudioPlayerDelegate
{
	@Published public var url:URL? = nil
	{
		didSet { self.updatePlayer() }
	}

	private var player:AVAudioPlayer? = nil
	private var urlObserver:Any? = nil
	private var timeObserver:Any? = nil
	

	override public init()
	{
		super.init()
		
		self.urlObserver = NotificationCenter.default.publisher(for:NSCollectionView.didSelectURL, object:nil).sink
		{
			[weak self] in self?.url = $0.object as? URL
		}
	}
	
	public func updatePlayer()
	{
		if self.url != self.player?.url
		{
			if let url = self.url
			{
				let wasPlaying = self.isPlaying
				self.createPlayer(for:url)
				if wasPlaying { self.play() }
			}
			else
			{
				self.deletePlayer()
			}
		}
	}
	
	public func createPlayer(for url:URL)
	{
		self.objectWillChange.send()

		self.player = try? AVAudioPlayer(contentsOf:url)
		self.player?.delegate = self
		
		self.timeObserver = Timer.publish(every:0.1, on:.main, in: RunLoop.Mode.common).autoconnect().sink
		{
			[weak self] _ in
			guard let self = self else { return }
			guard self.isPlaying else { return }
			self.objectWillChange.send()
		}
	}
	
	public func deletePlayer()
	{
		self.objectWillChange.send()
		self.player = nil
		self.timeObserver = nil
	}
	
	public var isEnabled:Bool
	{
		self.player != nil
	}
}


//----------------------------------------------------------------------------------------------------------------------


extension AudioPlayerController
{
	public func toggle()
	{
		if isPlaying { self.pause() } else { self.play() }
	}
	
	public func play()
	{
		self.objectWillChange.send()

		if self.player == nil
		{
			if let url = self.url
			{
				self.createPlayer(for:url)
			}
		}
		
		self.player?.play()
	}
	
	public func pause()
	{
		self.objectWillChange.send()
		self.player?.pause()
	}
	
	public var isPlaying:Bool
	{
		self.player?.isPlaying ?? false
	}
	
	public func audioPlayerDidFinishPlaying(_ player:AVAudioPlayer, successfully:Bool)
	{
		if successfully
		{
			self.deletePlayer()
		}
	}
}


//----------------------------------------------------------------------------------------------------------------------


extension AudioPlayerController
{
	public var duration:Double
	{
		self.player?.duration ?? 0.0
	}
	
	public var currentTime:Double
	{
		set
		{
			self.objectWillChange.send()
			self.player?.currentTime = newValue
		}
		
		get
		{
			self.player?.currentTime ?? 0.0
		}
	}
	
	public var fraction:Double
	{
		set
		{
			self.currentTime = self.duration * newValue
		}
		
		get
		{
			let duration = self.duration
			guard duration > 0.0 else { return 0.0 }
			return currentTime / duration
		}
	}
}


//----------------------------------------------------------------------------------------------------------------------
