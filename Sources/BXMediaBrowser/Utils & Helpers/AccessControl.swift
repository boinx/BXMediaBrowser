//
//  RestorableState.swift
//  MediaBrowserTest
//
//  Created by Peter Baumgartner on 04.12.21.
//

import SwiftUI
import Combine


//----------------------------------------------------------------------------------------------------------------------


public protocol AccessControl
{
	/// Returns true if access to a Source has been granted (if necessary at all)
	
	var hasAccess:Bool { get }
	
	/// This function presents some UI that let's the user grant access to a media Source. This can include login
	/// to an account, or just clicking a button that grants access to some system service.
	
	func grantAccess(_ completionHandler:@escaping (Bool)->Void)
}


//----------------------------------------------------------------------------------------------------------------------
 
