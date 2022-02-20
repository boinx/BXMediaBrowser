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


/// This class can preview play audio of an Object

public class AudioPlayerController : NSObject, ObservableObject, AVAudioPlayerDelegate
{
	/// The current Object that can be played

	public var object:Object? = nil
	{
		didSet { self.updatePlayer() }
	}

	/// When true, the next Object will automatically start playing after tthe current Object reaches the end.
	
	public var autoPlay = true
	
	/// The player handler audio playback
	
	private var player:AVAudioPlayer? = nil
	
	/// This subscriber listens to Object selection notifications
	
	private var objectObserver:Any? = nil
	
	/// This timer fire regularly to update the audio player user interface while audio is playing
	
	private var timeObserver:Any? = nil
	
	/// This notification is sent when the audio of an Object starts playing
		
	public static let didStartPlayingObject = NSNotification.Name("AudioPlayerController.didStartPlayingObject")
	
	/// This notification is sent when the audio of an Object stops playing
		
	public static let didStopPlayingObject = NSNotification.Name("AudioPlayerController.didStopPlayingObject")


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Setup

	/// Creates a new AudioPlayerController instance
	
	override public init()
	{
		super.init()
		
		self.objectObserver = NotificationCenter.default.publisher(for:NSCollectionView.didSelectObjects, object:nil).sink
		{
			[weak self] in self?.updateObject(with:$0)
		}
	}
	
	/// Called when new Object are selected in the ObjectCollectionView. If a single Object was selected, and
	/// it has a previewItemURL, then it is eligible for audio playback.
	
	private func updateObject(with notification:Notification)
	{
		// If we currently have audio playing, then send a didStop notification, because the player is
		// about to be released.
	
		if let object = self.object, self.isPlaying
		{
			NotificationCenter.default.post(name:Self.didStopPlayingObject, object:object)
		}

		// Store reference to the new current Object. This will also create a new player (see next function).
		
		if let objects = notification.object as? [Object], objects.count == 1, let object = objects.first, object.previewItemURL != nil
		{
			self.object = object
		}
		else
		{
			self.object = nil
		}
	}
	
	/// This function is called whenever the current Object changes. In this case a new player is created.
	
	private func updatePlayer()
	{
		let url = self.object?.previewItemURL
		
		if url != self.player?.url
		{
			if let url = url
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
	
	/// Creates a new player for the specified file URL. A timer for updating the user interface is also created.
	
	private func createPlayer(for url:URL)
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
	
	/// Deletes the currently player and UI timer
	
	private func deletePlayer()
	{
		self.objectWillChange.send()
		self.player = nil
		self.timeObserver = nil
	}
	

//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Control

	/// Toggles audio playback between playing and paused.
	
	public func toggle()
	{
		if isPlaying { self.pause() } else { self.play() }
	}
	
	/// Start audio playback and sends a notification to the user interface.
	
	public func play()
	{
		guard isEnabled else { return }
		self.objectWillChange.send()

		if self.player == nil
		{
			if let url = self.object?.previewItemURL
			{
				self.createPlayer(for:url)
			}
		}
		
		self.player?.play()
		NotificationCenter.default.post(name:Self.didStartPlayingObject, object:self.object)
	}
	
	/// Pauses audio playback and sends a notification to the UI.
	
	public func pause()
	{
		guard isEnabled else { return }
		self.objectWillChange.send()
		
		self.player?.pause()
		NotificationCenter.default.post(name:Self.didStopPlayingObject, object:self.object)
	}
	
	/// This function called when the currently playing audio Object reaches its end. If autoPlay is enabled,
	/// the next audio Object will automatically start playing.
	
	public func audioPlayerDidFinishPlaying(_ player:AVAudioPlayer, successfully:Bool)
	{
		NotificationCenter.default.post(name:Self.didStopPlayingObject, object:self.object)

		if successfully
		{
			if autoPlay, let nextObject = self.object?.next
			{
				self.object = nextObject
				self.play()
			}
			else
			{
				self.deletePlayer()
			}
		}
	}


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Accessors

	/// Returns true if a current Object is set and playback is possible.
	
	public var isEnabled:Bool
	{
		self.player != nil
	}

	/// Returns true is audio is currently playing
	
	public var isPlaying:Bool
	{
		self.player?.isPlaying ?? false
	}
	
	/// Returns the duration (in seconds) of the current audio Object.
	
	public var duration:Double
	{
		self.player?.duration ?? 0.0
	}
	
	/// Returns the current playback time (in seconds).
	
	public var time:Double
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
	
	/// Returns the fraction of the audio file that has been played already.
	
	public var fraction:Double
	{
		set
		{
			self.time = self.duration * newValue
		}
		
		get
		{
			let duration = self.duration
			guard duration > 0.0 else { return 0.0 }
			return time / duration
		}
	}
}


//----------------------------------------------------------------------------------------------------------------------
