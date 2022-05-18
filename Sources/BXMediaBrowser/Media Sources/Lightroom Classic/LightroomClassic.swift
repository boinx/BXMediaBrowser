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


public class LightroomClassic : ObservableObject, AppLifecycleMixin
{
	/// A shared singleton instance
	
	public static let shared = LightroomClassic()
	
	/// The Lightroom Classic app icon
	
	public private(set) var icon:CGImage? = nil
    
	/// The IMBLightroomParserMessenger is responsible for talking to the legacy Obj-C code in the iMedia framework
	
	public private(set) var parserMessenger:IMBLightroomParserMessenger? = nil
	
	/// Any errors that may have occured while loading this source
	
	@MainActor @Published public var error:Swift.Error? = nil

	/// Internal housekeeping
	
	public var observers:[Any] = []
	
	
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
    
    
    /// Returns true if Lightroom Classic is installed
	
    public var isInstalled:Bool
    {
		self.parserMessenger != nil
    }
    
    
    /// Returns true if the libraries parent folder is readable, i.e. we have access rights
	
    public var isReadable:Bool
    {
		guard let url = self.parserMessenger?.mediaSource else { return false }
		let isReadable = url.isReadable
		return isReadable
    }
    

	/// Returns the list of known Lightroom Classic bundle identifiers
	
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


    /// Launches the Lightroom Classic application in the background
	
	public func launch(completionHandler:((Swift.Error?)->Void)? = nil)
    {
		guard let path = IMBLightroomParserMessenger.lightroomPath() else { return }

		let url = URL(fileURLWithPath:path)
		let config = NSWorkspace.OpenConfiguration()
//		config.hides = true
		
		self.registerDidActivateHandler()
		{
			[weak self] in
			completionHandler?(nil)
			self?.observers = []
		}
		
		NSWorkspace.shared.openApplication(at:url, configuration:config)
//		{
//			_,error in
//
//			completionHandler?(error)
//		}
    }
   
   
//----------------------------------------------------------------------------------------------------------------------


	/// Error that might occur when talking to the Lightroom server
	
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


public extension LightroomClassic
{
	enum Status : Equatable
	{
		/// Read access to the Lightroom catalog file hasn't been granted by the user
		
		case noAccess
		
		/// Lightroom Classic is not running
		
		case notRunning
		
		/// Everything is fine
		
		case ok
	}
		
	/// The current status
	
	@MainActor var status:Status
	{
		if let error = self.error as? NSError
		{
			if error.domain == "com.karelia.imedia" && error.code == 14
			{
				return .notRunning
			}
			else
			{
				return .noAccess
			}
		}
		
		return .ok
	}

//	@MainActor var statusTitle:String
//	{
//		switch self.status
//		{
//			case .noAccess: return "Missing Access Rights"
//			case .notRunning: return "Lightroom Classic Not Running"
//			default: return ""
//		}
//	}
//
//	@MainActor var statusMessage:String
//	{
//		switch self.status
//		{
//			case .noAccess: return "The Lightroom library is not readable. Please grant read access rights for its parent folder."
//			case .notRunning: return error?.localizedDescription ?? ""
//			default: return ""
//		}
//	}
}


//----------------------------------------------------------------------------------------------------------------------


#endif
