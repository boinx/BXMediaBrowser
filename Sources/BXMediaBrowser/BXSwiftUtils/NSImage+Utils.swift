//**********************************************************************************************************************
//
//  URL+Metadata.swift
//	Media file metadata
//  Copyright ©2022 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


#if os(macOS)

import AppKit


//----------------------------------------------------------------------------------------------------------------------


public extension NSImage
{
	var CGImage:CGImage?
	{
		self.cgImage(forProposedRect:nil, context:nil, hints:nil)
	}

	static func icon(for app:String) -> NSImage?
	{
		guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier:app) else { return nil }
		return NSWorkspace.shared.icon(forFile:url.path)
	}
}


//----------------------------------------------------------------------------------------------------------------------


#endif
