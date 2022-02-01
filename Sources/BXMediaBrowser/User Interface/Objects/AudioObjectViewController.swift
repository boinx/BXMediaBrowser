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

import BXSwiftUtils
import AppKit


//----------------------------------------------------------------------------------------------------------------------


public class AudioObjectViewController : ObjectViewController
{
	// Outlets
	
    @IBOutlet weak open var button: NSButton?
    @IBOutlet weak open var nameField: NSTextField?
    @IBOutlet weak open var metadataField: NSTextField?
    @IBOutlet weak open var durationField: NSTextField?
    @IBOutlet weak open var sizeField: NSTextField?


//----------------------------------------------------------------------------------------------------------------------


    override class var identifier:NSUserInterfaceItemIdentifier
    {
    	NSUserInterfaceItemIdentifier("BXMediaBrowser.AudioObjectViewController")
	}
	
	override class var width:CGFloat { 0 } // 0 means full width of view
	
	override class var height:CGFloat { 46 }
	
	override class var spacing:CGFloat { 0 }


//----------------------------------------------------------------------------------------------------------------------


	override func redraw()
	{
		guard let object = object else { return }
		guard let metadata = object.metadata else { return }
		
		let title = metadata[kMDItemTitle as String] as? String
		let authors = metadata[kMDItemTitle as String] as? [String]
		let composer = metadata[kMDItemComposer as String] as? String
		let album = metadata[kMDItemAlbum as String] as? String
		let genre = metadata[kMDItemMusicalGenre as String] as? String
		let duration = metadata[kMDItemDurationSeconds as String] as? Double ?? 0.0
		let size = metadata[kMDItemFSSize as String] as? Int
		let kind = metadata[kMDItemKind as String] as? String
		let name = title ?? object.name
		var info = ""
		
		if let artist = authors?.first ?? composer, !artist.isEmpty
		{
			info += artist
		}

		if let album = album, !album.isEmpty
		{
			if !info.isEmpty { info += ", " }
			info += album
		}

		if let genre = genre, !genre.isEmpty
		{
			if !info.isEmpty { info += ", " }
			info += genre
		}
		
		if let kind = kind, !kind.isEmpty
		{
			if !info.isEmpty { info += ", " }
			info += kind
		}

		self.nameField?.stringValue = name
		self.metadataField?.stringValue = info
		self.durationField?.stringValue = duration.shortTimecodeString()
		self.sizeField?.stringValue = size?.fileSizeDescription ?? ""
		
		self.nameField?.lineBreakMode = .byTruncatingTail
		self.metadataField?.lineBreakMode = .byTruncatingTail

		if let thumbnail = object.thumbnailImage
		{
			let w = thumbnail.width
			let h = thumbnail.height
			let size = CGSize(width:w, height:h)
			self.imageView?.image = NSImage(cgImage:thumbnail, size:size)
		}

		if object.isLocallyAvailable
		{
			self.button?.image = NSImage(systemSymbolName:"play", accessibilityDescription:nil)
			self.imageView?.alphaValue = 1.0
			self.nameField?.alphaValue = 1.0
		}
		else if object.isDownloadable
		{
			self.button?.image = NSImage(systemSymbolName:"icloud.and.arrow.down", accessibilityDescription:nil)
			self.imageView?.alphaValue = 0.5
			self.nameField?.alphaValue = 0.5
		}
		else
		{
			self.button?.image = NSImage(systemSymbolName:"exclamationmark.icloud", accessibilityDescription:nil)
			self.imageView?.alphaValue = 0.5
			self.nameField?.alphaValue = 0.5
		}
		
	}
	
	
//----------------------------------------------------------------------------------------------------------------------


	// MARK: -
	
    override public var isSelected:Bool
    {
        didSet { self.updateHighlight() }
    }

	override public var highlightState:NSCollectionViewItem.HighlightState
    {
        didSet { self.updateHighlight() }
    }

    private func updateHighlight()
    {
        guard isViewLoaded else { return }

		let isHilited = self.isSelected	|| self.highlightState != .none
		let backgroundColor = isHilited ? NSColor.systemBlue : NSColor.clear
		let textColor = isHilited ? NSColor.white : NSColor.textColor

		self.view.layer?.backgroundColor = backgroundColor.cgColor
		nameField?.textColor = textColor
		metadataField?.textColor = textColor
		durationField?.textColor = textColor
    }
}


//----------------------------------------------------------------------------------------------------------------------


extension Int
{
	/// Creates a formatted file size description for the number of bytes
	
	var fileSizeDescription:String
	{
		let bytes = self
		let kilobytes = Double(bytes) / 1000
		let megabytes = kilobytes / 1000
		let gigabytes = megabytes / 1000
		let terabytes = gigabytes / 1000
		
		if bytes < 1000
		{
			return"\(bytes) bytes"
		}
		else if kilobytes < 1000
		{
			return "\(kilobytes.string(digits:1)) KB"
		}
		else if megabytes < 1000
		{
			return "\(megabytes.string(digits:1)) MB"
		}
		else if gigabytes < 1000
		{
			return "\(gigabytes.string(digits:1)) GB"
		}

		return "\(terabytes.string(digits:1)) TB"
	}
}


//----------------------------------------------------------------------------------------------------------------------


fileprivate extension Double
{
	/// Formats a Double number with the specified precision
	
	func string(for format:String = "#.#", digits:Int = 1) -> String
	{
		let formatter = NumberFormatter.forFloatingPoint(with:format, numberOfDigits:digits)
		return formatter.string(from:NSNumber(value:self)) ?? "0"
	}
}


//----------------------------------------------------------------------------------------------------------------------


#endif
