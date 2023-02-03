//**********************************************************************************************************************
//
//  NSMenuItem+Convenience.swift
//	Convenience intializers for NSMenuItem
//  Copyright ©2023 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


#if os(macOS)

import AppKit
import BXSwiftUtils
import SwiftUI


//----------------------------------------------------------------------------------------------------------------------


extension NSMenuItem
{
    /**
     Convenience initializer that creates a menu item with a given `title` and `value` which will be used as the item's
     `representedObject`.
     
     - parameter title: The item's displayable title.
     - parameter value: The value that is represented by this item.
     - parameter indentationLevel: The item's indentationLevel, typically 0.
     - parameter enabled: Wheter the item should be enabled (if the parent menu doesn't auto-enable items itself).
     */
    @objc public convenience init(title: String, value: Any?, indentationLevel: Int, enabled: Bool)
    {
        self.init(title: title, action: nil, keyEquivalent: "")
        self.representedObject = value
        self.indentationLevel = indentationLevel
        self.isEnabled = enabled
    }
    
    /**
     Convenience initializer setting the title and represented object.
     
     Same as `NSMenuItem(title:value:indentationLevel:enabled)`, but with `indentationLevel = 0` and `enabled = true`.
     Listed as a seperate method for Objective C accessibility.
     */
    @objc public convenience init(title: String, value: Any?)
    {
        self.init(title: title, value: value, indentationLevel: 0, enabled: true)
    }
    
    /**
     Convenience initializer that creates a menu item with the given `value` used as the item's `representedObject`.
     The item's `title` will be set to `value`'s `rawValue`, which must be a `String`.
     
     - parameter value: The value that is represented by this item and the raw value of which must be a String.
     */
    public convenience init<Value>(for value: Value) where Value: RawRepresentable, Value.RawValue == String
    {
        self.init(title: value.rawValue, value: value)
    }


	/// Creates an NSMenuItem with the specified title, key, and modifiers. The action closure is automatically executed when the menu item is selected.
	/// - parameter identifier: The optional identifier for the NSMenuItem
	/// - parameter title: The item's displayable title.
	/// - parameter modifiers: The hotkey modifiers
	/// - parameter key: The hotkey character
	/// - parameter state: Determines whether the NSMenuItem gets a checkmark
	/// - parameter action: This closure is executed when the NSMenuItem is selected

	public convenience init(identifier:String = "", image:NSImage? = nil, title:String, indentationLevel:Int = 0, key modifiers:NSEvent.ModifierFlags = [], _ key:String = "", state:NSControl.StateValue = .off, enabled:Bool = true, action:@escaping ()->Void)
	{
		let actionWrapper = BXActionWrapper(action)

		self.init(title:title, action:#selector(BXActionWrapper.execute), keyEquivalent:key.lowercased())
		self.identifier = NSUserInterfaceItemIdentifier(rawValue:identifier)
		self.image = image
		self.target = actionWrapper				// Not retained!
		self.representedObject = actionWrapper	// Assign to representedObject to make sure it is retained
		self.keyEquivalentModifierMask = modifiers
		self.state = state
		self.isEnabled = enabled
		self.indentationLevel = indentationLevel
	}
	
	/// Creates a disabled menu with section title style (small caps font)
	
	public convenience init(sectionName:String)
	{
		let attributes:[NSAttributedString.Key:Any] =
		[
			.font: NSFont.systemFont(ofSize:11),
			.foregroundColor: NSColor.gray
		]
		
		self.init(title:sectionName.uppercased(), action:nil, keyEquivalent:"")
		self.attributedTitle = NSAttributedString(string:sectionName, attributes:attributes)
		self.isEnabled = false
	}
	
	/// Creates a menu item with a SwiftUI based custom view
	
	public convenience init<V:View>(size:CGSize, content:()->V)
	{
		let view = content()//.fixedSize()
		let hostingView = NSHostingView(rootView:view)
		hostingView.frame = CGRect(origin:.zero, size:size)
		
		self.init(title:"", action:nil, keyEquivalent:"")
		self.view = hostingView
	}
}


//----------------------------------------------------------------------------------------------------------------------


public extension NSMenu
{
	/// Adds the specified NSMenuItem at the end of the menu
	
	@discardableResult static func += (_ menu:NSMenu, _ item:NSMenuItem) -> NSMenu
	{
		menu.addItem(item)
		return menu
	}
}


//----------------------------------------------------------------------------------------------------------------------


#endif
