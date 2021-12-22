//**********************************************************************************************************************
//
//  BXReducedOpacityWhenDisabledModifier.swift
//	Reduces the opacity when a view is disabled
//  Copyright ©2020 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import SwiftUI


//----------------------------------------------------------------------------------------------------------------------


public struct BXReducedOpacityWhenDisabledModifier : ViewModifier
{
	// Params
	
	private var enabledOpactiy = 1.0
	private var disabledOpactiy = 0.33

	// Environment
	
	@Environment(\.isEnabled) var isEnabled
	@Environment(\.hasReducedOpacityAncestor) var hasReducedOpacityAncestor

	// Init
	
	public init(enabledOpactiy:Double = 1.0, disabledOpactiy:Double = 0.33)
	{
		self.enabledOpactiy = enabledOpactiy
		self.disabledOpactiy = disabledOpactiy
	}
	
	// Modify View
	
	public func body(content:Content) -> some View
    {
		// Only reduce opacity if ancestor hasn't already done so
		
		let opacity = isEnabled || hasReducedOpacityAncestor ? enabledOpactiy : disabledOpactiy
        
        return content
			
			// Reduce the opacity as needed
			
			.opacity(opacity)
			
			// Store fact that we did - so that children can skip this step
			
			.environment(\.hasReducedOpacityAncestor, !isEnabled)
			
    }
}


//----------------------------------------------------------------------------------------------------------------------


extension View
{
	/// Reduces opacity when the view hierarchy is disabled
	
	public func reducedOpacityWhenDisabled(_ opactiy:Double = 0.33) -> some View
	{
		return self.modifier(BXReducedOpacityWhenDisabledModifier(disabledOpactiy:opactiy))
	}
}


//----------------------------------------------------------------------------------------------------------------------


// This environment key stores info about which node in the view tree has reduced opacity due to being disabled.
// Any children below that do not need to (and should not) reduce opacity any further.

struct BXHasReducedOpacityAncestorKey : EnvironmentKey
{
    static public let defaultValue:Bool = false
}

extension EnvironmentValues
{
    var hasReducedOpacityAncestor:Bool
    {
        set
        {
            self[BXHasReducedOpacityAncestorKey.self] = newValue
        }

        get
        {
            return self[BXHasReducedOpacityAncestorKey.self]
        }
    }
}


//----------------------------------------------------------------------------------------------------------------------

