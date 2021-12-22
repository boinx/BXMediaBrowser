//
//  RestorableState.swift
//  MediaBrowserTest
//
//  Created by Peter Baumgartner on 04.12.21.
//

import SwiftUI
import Combine


//----------------------------------------------------------------------------------------------------------------------


//public protocol StateRestorationDelegate : AnyObject
//{
//	func saveState(for library:Library)
//	func restoreState(for library:Library)
//
//	func saveState(for section:Section)
//	func restoreState(for section:Section)
//
//	func saveState(for source:Source)
//	func restoreState(for source:Source)
//
//	func saveState(for container:Container)
//	func restoreState(for container:Container)
//}
//
//
////----------------------------------------------------------------------------------------------------------------------
//
//
//public class State : StateRestorationDelegate
//{
//	static let shared = State()
//	
//	weak var delegate:StateRestorationDelegate? = nil
//	var target:StateRestorationDelegate { delegate ?? self }
//
//
////----------------------------------------------------------------------------------------------------------------------
//
//
//	func saveState()
//	{
//		if let id = selectedContainer?.identifier
//		{
//			UserDefaults.standard.set(id, forKey:selectedContainerPrefsKey)
//		}
//		else
//		{
//			UserDefaults.standard.removeObject(forKey:selectedContainerPrefsKey)
//		}
//		
//		self.sections.forEach { $0.saveState() }
//	}
//	
//	
//	func restoreState()
//	{
//		self.sections.forEach { $0.restoreState() }
//		
//		if let id = UserDefaults.standard.string(forKey:selectedContainerPrefsKey)
//		{
////			Task
////			{
////				await MainActor.run
////				{
////					let containers = await self.flattenedContainers
////
////				}
////			}
//			
//			#warning("TODO: recursively search for container and set it")
//		}
//		else
//		{
//			self.selectedContainer = nil
//		}
//		
//	}
//	
//	
////	var flattenedContainers:[Container]
////	{
////		get async
////		{
////			self.sections.flatMap
////			{
////				self.containers.flatMap
////			}
////		}
////	}
//	
//	
//	var selectedContainerPrefsKey:String
//	{
//		"BXMediaBrowser.Library.\(identifier).selectedContainer".replacingOccurrences(of:".", with:"-")
//	}
//	
//	
////----------------------------------------------------------------------------------------------------------------------
//
//
//	public func saveState(for library:Library)
//	{
//		
//	}
//	
//	public func restoreState(for library:Library)
//	{
//	
//	}
//	
//
////----------------------------------------------------------------------------------------------------------------------
//
//
//	public func saveState(for section:Section)
//	{
//	
//	}
//	
//	public func restoreState(for section:Section)
//	{
//	
//	}
//	
//
////----------------------------------------------------------------------------------------------------------------------
//
//
//	public func saveState(for source:Source)
//	{
//	
//	}
//	
//	public func restoreState(for source:Source)
//	{
//	
//	}
//	
//
////----------------------------------------------------------------------------------------------------------------------
//
//
//	public func saveState(for container:Container)
//	{
//	
//	}
//	
//	public func restoreState(for container:Container)
//	{
//	
//	}
//	
//}

//----------------------------------------------------------------------------------------------------------------------
 
