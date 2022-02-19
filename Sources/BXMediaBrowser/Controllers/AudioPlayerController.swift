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
import AVKit


//----------------------------------------------------------------------------------------------------------------------


public class AudioPlayerController : ObservableObject
{
	@Published var url:URL? = nil
	{
		didSet { self.updatePlayer() }
	}
	
	
	private var player:AVAudioPlayer? = nil
	@Published var time:Double = 0.0
	
	private var urlObserver:Any? = nil
	private var timeObserver:Any? = nil
	
	init()
	{
		self.urlObserver = NotificationCenter.default.publisher(for:NSNotification.Name("selectedObjectURL"), object:nil).sink
		{
			[weak self] in self?.url = $0.object as? URL
		}
		
		self.timeObserver = Timer.publish(every:0.1, on:.main, in: RunLoop.Mode.common).autoconnect().sink
		{
			[weak self] _ in
			guard let self = self else { return }
			guard self.isPlaying else { return }
			self.time = self.currentTime
		}

	}
	
	func updatePlayer()
	{
		if isPlaying, let oldURL = self.player?.url, let newURL = self.url, oldURL != newURL
		{
			self.createPlayer()
			self.play()
		}
	}
	
	func createPlayer()
	{
		if let url = self.url
		{
			self.player = try? AVAudioPlayer(contentsOf:url)
		}
	}
	
	func toggle()
	{
		if isPlaying { self.pause() } else { self.play() }
	}
	
	func play()
	{
		if self.player == nil
		{
			self.createPlayer()
		}
		
		self.objectWillChange.send()
		self.player?.play()
	}
	
	func pause()
	{
		self.objectWillChange.send()
		self.player?.pause()
	}
	
	var isPlaying:Bool
	{
		self.player?.isPlaying ?? false
	}
	
	var duration:Double
	{
		self.player?.duration ?? 0.0
	}
	
	var currentTime:Double
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
	
	var fraction:Double
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
