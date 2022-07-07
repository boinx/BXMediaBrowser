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


#if canImport(iMedia) && os(macOS)

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
    
	/// This bookmark holds the read access rights to the parent folder of the Lightroom catalog file
	
	public var libraryBookmark:Data? = nil
		
	/// Any errors that may have occured while loading this source
	
	@MainActor @Published public var error:Swift.Error? = nil

	/// This flag determines whether a warning is shown when "downloading" a Lightroom preview file that has
	/// a reduced preview image size (due to catalog settings in Lightroom Classic)
	
	@Published public var showPreviewSizeWarning:Bool = true
	{
		didSet { UserDefaults.standard.set(showPreviewSizeWarning, forKey:showPreviewSizeWarningKey) }
	}
	
	private let showPreviewSizeWarningKey = "showPreviewSizeWarning"
	
	/// Internal housekeeping
	
	public var observers:[Any] = []
	
	
//----------------------------------------------------------------------------------------------------------------------


    private init()
    {
		// Instantiate a IMBLightroomParserMessenger if Lightroom Classic is installed
		
		if let identifier = self.bundleIdentifier
		{
			let image = NSImage.icon(for:identifier) ?? Bundle.BXMediaBrowser.image(forResource:"lr_appicon_noshadow_256")
			self.icon = image?.CGImage
		}
		
		// Register default prefs
		
		UserDefaults.standard.register(defaults:[showPreviewSizeWarningKey:true])
		self.showPreviewSizeWarning = UserDefaults.standard.bool(forKey:showPreviewSizeWarningKey)
	}
    
    
//----------------------------------------------------------------------------------------------------------------------


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


      /// Returns the bundleIdentifier of the installed Lightroom Classic application
	
    public var bundleIdentifier:String?
    {
		for identifier in self.bundleIdentifiers
		{
			guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier:identifier) else { continue }
			if url.exists
			{
				return identifier
			}
		}
		
		return nil
    }


    /// Returns the URL of the installed Lightroom Classic application
	
    public var url:URL?
    {
		for identifier in self.bundleIdentifiers
		{
			guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier:identifier) else { continue }

			if url.exists
			{
				return url
			}
		}
		
		return nil
    }


    /// Returns the name of the installed Lightroom Classic application
	
    public var name:String
    {
		self.url?.deletingPathExtension().lastPathComponent ?? "Adobe Lightroom Classic"
    }


   /// Returns true if Lightroom Classic is installed
	
    public var isInstalled:Bool
    {
		self.url != nil
		
//		guard let identifier = IMBLightroomImageParserMessenger.lightroomAppBundleIdentifier() else { return false }
//		guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier:identifier) else { return false }
//		return url.exists
    }
    
    
//----------------------------------------------------------------------------------------------------------------------


    /// Launches the Lightroom Classic application in the background
	
	public func launch(completionHandler:((Swift.Error?)->Void)? = nil)
    {
		guard let url = self.url else { return }
		let config = NSWorkspace.OpenConfiguration()
		NSWorkspace.shared.openApplication(at:url, configuration:config)
//		{
//			_,error in
//
//			completionHandler?(error)
//		}
		
		self.registerDidActivateHandler()
		{
			[weak self] in
			completionHandler?(nil)
			self?.observers = []
		}
    }
   
   
//----------------------------------------------------------------------------------------------------------------------


 	// MARK: - Alerts
	

	public func showPreviewSizeWarningAlert(for imbObject:IMBLightroomObject, with url:URL)
	{
		guard LightroomClassic.shared.showPreviewSizeWarning else { return }

		guard let metadata1 = imbObject.preliminaryMetadata else { return }
		let W = (metadata1["width"] as? NSNumber)?.intValue ?? 0
		let H = (metadata1["height"] as? NSNumber)?.intValue ?? 0

		let metadata2 = url.imageMetadata
		let w = (metadata2["PixelWidth" as CFString] as? Int) ?? 0
		let h = (metadata2["PixelHeight" as CFString] as? Int) ?? 0
		
		if w < W && h < H
		{
			DispatchQueue.main.debounce("showPreviewSizeWarningAlert", interval:2.0)
			{
				let alert = NSAlert()
				
				alert.alertStyle = .critical
				alert.messageText = NSLocalizedString("PreviewSizeAlert.title",tableName:"LightroomClassic", bundle:.BXMediaBrowser, comment:"Alert Title")
				alert.informativeText = NSLocalizedString("PreviewSizeAlert.message",tableName:"LightroomClassic", bundle:.BXMediaBrowser, comment:"Alert Message")
				alert.addButton(withTitle:"OK")
				alert.showsSuppressionButton = true
				
				alert.runModal()

				if let checkbox = alert.suppressionButton, checkbox.state == .on
				{
					LightroomClassic.shared.showPreviewSizeWarning = false
				}
			}
		}
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
}


//----------------------------------------------------------------------------------------------------------------------


#endif
