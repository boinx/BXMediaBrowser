//----------------------------------------------------------------------------------------------------------------------
//
//  Copyright ©2022 Peter Baumgartner. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//
//----------------------------------------------------------------------------------------------------------------------


import BXSwiftUtils
import SwiftUI


//----------------------------------------------------------------------------------------------------------------------


public class SortController : ObservableObject, BXSignpostMixin
{
	public static let shared = SortController()
	
	private init()
	{

	}
	
	
//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Selected Container
	
	/// The currentContainer has properties like sortGroupKey or allowSortKinds that are needed to access the
	/// appropriate sorting properties.
	
	@Published public var selectedContainer:Container? = nil
	{
		didSet { self.didSelectContainer() }
	}
	
	/// This function is called when a Container is selected. In this case the current sorting Kind is validated
	/// against the Kinds that are allowed by the Container.
	
	func didSelectContainer()
	{
		if !allowedSortKinds.contains(self.kind)
		{
			self.kind = allowedSortKinds.first ?? .alphabetical
		}
	}
	
	/// Returns the group key of the currentContainer. Sorting parameters are shared within a group.
	
	var sortGroupKey:String
	{
		selectedContainer?.sortGroupKey ?? ""
	}
	
	/// Returns the allowed sorting Kinds for the currentContainer.
	
	var allowedSortKinds:[Kind]
	{
		selectedContainer?.allowedSortTypes ?? []
	}
	
	/// Reloads the selectedContainer. This function should be called whenever the sorting parameters have changed.
	
	func reloadCurrentContainer()
	{
		self.selectedContainer?.load()
	}
	
	
//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Settings
	
	public typealias Kind = String

	/// The kind determines how Objects are sorted
	
	public var kind:Kind
	{
		set
		{
			self.objectWillChange.send()
			let shouldReload = newValue != kind
			_kind[sortGroupKey] = newValue
			if shouldReload { self.reloadCurrentContainer() }
		}
		
		get
		{
			_kind[sortGroupKey] ?? .alphabetical
		}
	}
	
	// Sorting Kind is stored in a dictionary, grouped by Container type. All Containers with the same
	// sortGroupKey share their sorting settings.
	
	private var _kind:[String:Kind] = [:]


//----------------------------------------------------------------------------------------------------------------------


	/// Defines the sort direction
	
	public enum Direction : Equatable, Hashable, Codable
	{
		case ascending
		case descending
	}
	
	/// The Direction determines whether Objects are sorted ascending or descending
	
	public var direction:Direction
	{
		set
		{
			let shouldReload = newValue != direction
			_direction[sortGroupKey] = newValue
			if shouldReload { self.reloadCurrentContainer() }
		}
		
		get
		{
			_direction[sortGroupKey] ?? .ascending
		}
	}
	
	// Sorting Direction is stored in a dictionary, grouped by Container type. All Containers with the same
	// sortGroupKey share their sorting settings.
	
	private var _direction:[String:Direction] = [:]
	
	/// Toggles the current sorting Direction
	
	public func toggleDirection()
	{
		self.direction = direction == .ascending ? .descending : .ascending
	}
	

//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Sorting
	
	/// A Comparator closure is reponsible for comparing two Objects according to a metric that is useful for
	/// sorting a list of Objects.
	
	public typealias Comparator = (Object,Object) -> Bool


	/// Stores the registered Comparators by Kind
	
	private var _comparator:[Kind:Comparator] = [:]
	
	
	/// Registers a new Comparator for the specified Kind
	
	public func register(kind:Kind, comparator:@escaping Comparator)
	{
		self._comparator[kind] = comparator
	}
	
	
	/// Returns the Comparator for the specified Kind
	
	public func comparator(for kind:Kind, direction:Direction) -> Comparator?
	{
		guard kind != .never else { return nil }
		guard let comparator = self._comparator[kind] else { return nil }
		
		// If the sorting direction is ascending, then return the Comparator directly
		
		if direction == .ascending
		{
			return comparator
		}
		
		// Descending, then return an inverted Comparator
		
		let invertedComparator:Comparator =
		{
			!comparator($0,$1)
		}
		
		return invertedComparator
	}
	
	
	/// Returns the selected Comparator for the currentContainer
	
	public var comparator:Comparator?
	{
		self.comparator(for:kind, direction:direction)
	}
	
	/// Sort the specified array of Objects according to the current settings
	
	public func sort(_ objects:inout [Object])
	{
		let token = self.beginSignpost(in:"SortController","sort")
		defer { self.endSignpost(with:token, in:"SortController","sort") }
		
		if let comparator = self.comparator
		{
			objects.sort(by:comparator)
		}
	}
}


//----------------------------------------------------------------------------------------------------------------------


// MARK: - Localization
	
//extension SortController.Kind
//{
//	/// Returns a localized string for displaying the sorting Kind in the user interface
//
//	public var localizedName:String
//	{
//		NSLocalizedString(self, tableName:"SortController", bundle:Bundle.module, comment:"Sorting Kind Name")
//	}
//}


//----------------------------------------------------------------------------------------------------------------------
