//**********************************************************************************************************************
//
//  NSOpenPanel+Present.swift
//	Convenience function to show an NSOpenPanel
//  Copyright ©2020 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


#if os(macOS)

//import SwiftUI
import AppKit
import UniformTypeIdentifiers


//----------------------------------------------------------------------------------------------------------------------


public extension NSOpenPanel
{
	class func presentModal(title:String? = nil, message:String? = nil, buttonLabel:String? = nil, directoryURL:URL? = nil, allowedFileTypes:[String]? = nil, canChooseFiles:Bool = true, canChooseDirectories:Bool = false, allowsMultipleSelection:Bool = false, appearance:NSAppearance? = nil, handler:([URL])->Void)
	{
		let panel = NSOpenPanel()
		
		panel.appearance = appearance
		panel.canCreateDirectories = true
		panel.canChooseFiles = canChooseFiles
		panel.canChooseDirectories = canChooseDirectories
		panel.allowsMultipleSelection = allowsMultipleSelection

		if let title = title
		{
			panel.title = title
		}
		
		if let message = message
		{
			panel.message = message
		}
		
		if let buttonLabel = buttonLabel
		{
			panel.prompt = buttonLabel
		}

		if let allowedFileTypes = allowedFileTypes
		{
			if #available(macOS 12,*)
			{
				panel.allowedContentTypes = allowedFileTypes.compactMap { UTType.init($0) }
			}
			else
			{
				panel.allowedFileTypes = allowedFileTypes
			}
		}



		if let directoryURL = directoryURL
		{
			panel.directoryURL = directoryURL
		}

		let button = panel.runModal()
		
		if button == NSApplication.ModalResponse.OK
		{
			handler(panel.urls)
		}
		else
		{
			handler([])
		}
	}
}


//----------------------------------------------------------------------------------------------------------------------

#endif
