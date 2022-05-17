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


#if canImport(iMedia)

import iMedia
import BXSwiftUtils
import Foundation


//----------------------------------------------------------------------------------------------------------------------


public class LightroomClassic : ObservableObject
{
	/// A shared singleton instance
	
	public static let shared = LightroomClassic()
	
	/// The Lightroom Classic app icon
	
	public private(set) var icon:CGImage? = nil
    
	/// The IMBLightroomParserMessenger is responsible for talking to the legacy Obj-C code in the iMedia framework
	
	public private(set) var parserMessenger:IMBLightroomParserMessenger? = nil
	
	
//----------------------------------------------------------------------------------------------------------------------


    private init()
    {
		// Instantiate a IMBLightroomParserMessenger if Lightroom Classic is installed
		
		if let identifier = IMBLightroomImageParserMessenger.lightroomAppBundleIdentifier()
		{
			let image = NSImage.icon(for:identifier) ?? Bundle.BXMediaBrowser.image(forResource:"lr_appicon_noshadow_256")
			self.icon = image?.CGImage
			self.parserMessenger = IMBLightroomImageParserMessenger()
		}
	}
    
    public var isInstalled:Bool
    {
		self.parserMessenger != nil
    }
    
//    public var icon:CGImage?
//    {
//		let identifier = IMBLightroomImageParserMessenger.identifier() ?? ""
//		let image =
//			NSImage.icon(for:identifier) ??
//			Bundle.BXMediaBrowser.image(forResource:"lr_appicon_noshadow_256")
//
////		let image:NSImage? = nil
////
////		for identifier in bundleIdentifiers
////		{
////			if image == nil
////			{
////				image = NSImage.icon(for:identifier)
////			}
////		}
////
////		if image == nil
////		{
////			image = Bundle.BXMediaBrowser.image(forResource:"lr_appicon_noshadow_256")
////		}
//
//		return image?.CGImage
//    }
   
	public var bundleIdentifiers:[String]
	{
		[
			"com.adobe.LightroomClassicCC7",
			"com.adobe.Lightroom6",
			"com.adobe.Lightroom5",
			"com.adobe.Lightroom4",
			"com.adobe.Lightroom3",
			"com.adobe.Lightroom2",
			"com.adobe.Lightroom",
		]
	}
   
   
//----------------------------------------------------------------------------------------------------------------------


	/// The current status
	
	@MainActor @Published public var status:Status = .offline
	{
		didSet
		{
			LightroomCC.log.debug {"\(Self.self).\(#function) = \(status)"}
		}
	}

	public enum Status : Equatable
	{
		case offline
		case running
	}
		
	/// Error that moight occur when talking to the Lightroom server
	
	public enum Error : Swift.Error
	{
		case notRunning
	}
	
	
//----------------------------------------------------------------------------------------------------------------------


 	// MARK: - Debugging
	
	/// A logger for Lightroom related code

	public static var log:BXLogger =
	{
		()->BXLogger in
		
		var logger = BXLogger()

		logger.addDestination
		{
			(level:BXLogger.Level,string:String)->() in
			BXMediaBrowser.log.print(level:level, force:true) { string }
		}
		
		return logger
	}()
		
}


//----------------------------------------------------------------------------------------------------------------------


#endif
