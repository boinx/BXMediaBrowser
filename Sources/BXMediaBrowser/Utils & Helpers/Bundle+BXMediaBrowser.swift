//**********************************************************************************************************************
//
//  Bundle+BXMediaBrowser.swift
//	Access to the BXSwiftUI Bundle
//  Copyright ©2022 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation


//----------------------------------------------------------------------------------------------------------------------


public extension Bundle
{
	/// Returns a reference to the BXMediaBrowser (resources) bundle
	
	#if SWIFT_PACKAGE
	static let BXMediaBrowser = Bundle.module
	#else
	static let BXMediaBrowser = Bundle(for:BXMediaBrowserMarker.self)
	#endif
}

fileprivate class BXMediaBrowserMarker {}


//----------------------------------------------------------------------------------------------------------------------
