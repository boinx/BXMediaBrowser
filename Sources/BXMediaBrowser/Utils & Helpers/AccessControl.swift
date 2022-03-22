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
	
	@MainActor var hasAccess:Bool { get }
	
	/// This function presents some UI that let's the user grant access to a media Source. This can include login
	/// to an account, or just clicking a button that grants access to some system service.
	
	@MainActor func grantAccess(_ completionHandler:@escaping (Bool)->Void)
	
	/// Call this function to revoke access, e.g. to log out again.
	
	@MainActor func revokeAccess(_ completionHandler:@escaping (Bool)->Void)
}


//----------------------------------------------------------------------------------------------------------------------


// The default implementation does nothing. All Sources automatically get this empty implementation, but
// they can provide their own implemenation to do more meaningfull stuff

public extension AccessControl
{
	@MainActor var hasAccess:Bool
	{
		true
	}
	
	@MainActor func grantAccess(_ completionHandler:@escaping (Bool)->Void = { _ in })
	{
		completionHandler(hasAccess)
	}

	@MainActor func revokeAccess(_ completionHandler:@escaping (Bool)->Void = { _ in })
	{
		completionHandler(hasAccess)
	}
}


//----------------------------------------------------------------------------------------------------------------------
 
