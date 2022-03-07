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
import Foundation

#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif


//----------------------------------------------------------------------------------------------------------------------


open class PexelsContainer : Container
{
	class PexelsData
	{
		var lastUsedFilter = PexelsFilter()
		var page = 0
		var photos:[Pexels.Photo] = []
		var videos:[Pexels.Video] = []
	}
	
	public typealias SaveContainerHandler = (PexelsContainer)->Void
	
	let saveHandler:SaveContainerHandler?
	
	
//----------------------------------------------------------------------------------------------------------------------


	/// Creates a new Container for the folder at the specified URL
	
	public required init(identifier:String, icon:String, name:String, filter:PexelsFilter, saveHandler:SaveContainerHandler? = nil, removeHandler:((Container)->Void)? = nil)
	{
		Pexels.log.verbose {"\(Self.self).\(#function) \(identifier)"}

		self.saveHandler = saveHandler

		super.init(
			identifier: identifier,
			icon: icon,
			name: name,
			data: PexelsData(),
			filter: filter,
			loadHandler: Self.loadContents,
			removeHandler: removeHandler)
		
		self.observers += NotificationCenter.default.publisher(for:NSCollectionView.didScrollToEnd, object:self).sink
		{
			[weak self] _ in self?.load(with:nil)
		}
	}


	/// Loads the (shallow) contents of this folder
	
	class func loadContents(for identifier:String, data:Any, filter:Object.Filter) async throws -> Loader.Contents
	{
		return ([],[])
	}
		
		
	// Pexels Container can never be expanded, as they do not have any sub-containers
	
	override open var canExpand: Bool
	{
		false
	}
	

//----------------------------------------------------------------------------------------------------------------------


	/// Encodes/decodes a PexelsFilter from Data
	
	var filterData:Data?
	{
		get
		{
			guard let pexelsData = self.data as? PexelsData else { return nil }
			let filter = pexelsData.lastUsedFilter
			let data = try? JSONEncoder().encode(filter)
			return data
		}
		
		set
		{
			guard let data = newValue else { return }
			guard let pexelsData = self.data as? PexelsData else { return }
			guard let filter = try? JSONDecoder().decode(PexelsFilter.self, from:data) else { return }
			pexelsData.lastUsedFilter = filter
		}
	}

	/// Returns a textual description of the filter params (for displaying in the UI)
	
	var description:String
	{
		guard let filter = self.filter as? PexelsFilter else { return "" }
		return Self.description(with:filter)
	}

	/// Returns a textual description of the filter params (for displaying in the UI)

	class func description(with filter:PexelsFilter) -> String
	{
		let searchString = filter.searchString
		let orientation = filter.orientation != .any ? filter.orientation.localizedName : ""
		let color = filter.color != .any ? filter.color.localizedName : ""

		var description = searchString
		if !orientation.isEmpty { description += ", \(orientation)" }
		if !color.isEmpty { description += ", \(color)" }
		return description
	}

	/// Returns a description of the contents of this Container
	
    @MainActor override open var localizedObjectCount:String
    {
		let n = self.objects.count
		let str = n.localizedImagesString
		return str
    }


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Sorting
	
	/// Returns the list of allowed sort Kinds for this Container
		
	override open var allowedSortTypes:[Object.Filter.SortType] { [] }
}


//----------------------------------------------------------------------------------------------------------------------

