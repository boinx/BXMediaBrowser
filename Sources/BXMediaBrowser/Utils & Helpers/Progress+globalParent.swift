//**********************************************************************************************************************
//
//  Progress+parent.swift
//	Helps with multithreaded creation of Progress trees
//  Copyright ©2022 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation


//----------------------------------------------------------------------------------------------------------------------


extension Progress
{
	/// In tricky multithreaded scenarios it may be difficult to create the Progress tree, because Progress.current()
	/// is not visible from the current thread (because it was made current in a different thread). In this case it
	/// may help to resort to globalParent - which is available across all threads.
	
	static var globalParent:Progress?
	{
		set
		{
			_globalParent = newValue
		}
		
		get
		{
			Progress.current() ?? _globalParent
		}
	}
}

/// The global reference to the parent progress

fileprivate var _globalParent:Progress? = nil


//----------------------------------------------------------------------------------------------------------------------
