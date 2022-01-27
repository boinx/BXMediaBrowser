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
	var hasAccess:Bool { get }
	
	func grantAccess(_ completionHandler:@escaping (Bool)->Void)
}


//----------------------------------------------------------------------------------------------------------------------
 
