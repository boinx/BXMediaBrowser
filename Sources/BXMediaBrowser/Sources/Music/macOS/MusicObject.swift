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


#if os(macOS)

import iTunesLibrary
import UniformTypeIdentifiers
import QuickLook
import AppKit


//----------------------------------------------------------------------------------------------------------------------


public class MusicObject : Object
{
	/// Creates a new MusicObject with the specified ITLibMediaItem
	///
	public init(with item:ITLibMediaItem)
	{
		let identifier = "MusicSource:ITLibMediaItem:\(item.persistentID)"
		let name = item.title
		
		super.init(
			identifier: identifier,
			name: name,
			data: item,
			loadThumbnailHandler: Self.loadThumbnail,
			loadMetadataHandler: Self.loadMetadata,
			downloadFileHandler: Self.downloadFile)
			
		Task
		{
			await MainActor.run
			{
				self.isLocallyAvailable = item.locationType == .file && item.location != nil
				self.isDownloadable = false
			}
		}
	}


//----------------------------------------------------------------------------------------------------------------------


	/// Creates a thumbnail image for the ITLibMediaItem
	
	class func loadThumbnail(for identifier:String, data:Any) async throws -> CGImage
	{
		guard let item = data as? ITLibMediaItem else { throw Error.notFound }
		let url = item.location
		let uti = url?.uti ?? "public.mp3"
		
		if #available(macOS 11, *)
		{
			if let type = UTType(uti)
			{
				let image = NSWorkspace.shared.icon(for:type)
				guard let thumbnail = image.cgImage(forProposedRect:nil, context:nil, hints:nil) else { throw Error.loadThumbnailFailed }
				return thumbnail
			}
		}
		
		guard let url = url else { throw Error.notFound }
		let image = NSWorkspace.shared.icon(forFile:url.path)
		guard let thumbnail = image.cgImage(forProposedRect:nil, context:nil, hints:nil) else { throw Error.loadThumbnailFailed }
		return thumbnail
	}


//----------------------------------------------------------------------------------------------------------------------


	/// Loads the metadata dictionary
	
	class func loadMetadata(for identifier:String, data:Any) async throws -> [String:Any]
	{
		guard let item = data as? ITLibMediaItem else { throw Object.Error.loadMetadataFailed }
		let artist = (item.artist?.name ?? "") as String
		var metadata:[String:Any] = [:]
		
		metadata[kMDItemTitle as String] = item.title
		metadata[kMDItemAuthors as String] = [artist]
		metadata[kMDItemComposer as String] = item.composer
		metadata[kMDItemAlbum as String] = item.album.title
		metadata[kMDItemMusicalGenre as String] = item.genre
		metadata[kMDItemDurationSeconds as String] = Double(item.totalTime) / 1000.0
		metadata[kMDItemFSSize as String] = Int(item.fileSize)
		metadata[kMDItemKind as String] = item.kind
		metadata["bpm"] = Double(item.beatsPerMinute)

		return metadata
	}


//----------------------------------------------------------------------------------------------------------------------


	/// Returns the UTI of the promised local file
	
	override var localFileUTI:String
	{
		guard let item = data as? ITLibMediaItem else { return kUTTypeAudio as String }
		guard let url = item.location else { return kUTTypeAudio as String }
		return url.uti ?? ""
	}


	/// Returns the filename of the local file
	
	override var localFileName:String
	{
		guard let item = data as? ITLibMediaItem else { return "Audio File" }
		guard let url = item.location else { return "Audio File" }
		return url.lastPathComponent
	}
	
	
	// Request the URL of an Object. Apple really doesn't want us to work with URLs of PHAssets, so we have to resort
	// to various tricks. In case of an image we'll pretend to want edit an image file in-place to get the URL. In the
	// case of a video, we'll pretend we want to play an AVURLAsset with an AVPlayer.
	// Taken from https://stackoverflow.com/questions/38183613/how-to-get-url-for-a-phasset
	
	class func downloadFile(for identifier:String, data:Any) async throws -> URL
	{
		guard let item = data as? ITLibMediaItem else { throw Object.Error.notFound }
		guard let url = item.location else { throw Object.Error.downloadFileFailed }
		return url
	}
	
}


//----------------------------------------------------------------------------------------------------------------------


#endif
