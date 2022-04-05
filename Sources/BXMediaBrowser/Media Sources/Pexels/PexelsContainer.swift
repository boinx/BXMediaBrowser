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
		var objects:[Object] = []
		var knownIDs:[Int:Bool] = [:]
		var didReachEnd = false
		var loadNextPage = true
	}
	
	/// This handler is called when the user clicks on the Save button - it will permanently save a Pexels search
	
	open var saveHandler:SaveContainerHandler? = nil

	public typealias SaveContainerHandler = (Container)->Void
	

//----------------------------------------------------------------------------------------------------------------------


	/// Creates a new Container for the folder at the specified URL
	
	public required init(identifier:String, icon:String, name:String, filter:PexelsFilter, saveHandler:SaveContainerHandler? = nil, removeHandler:((Container)->Void)? = nil)
	{
		Pexels.log.verbose {"\(Self.self).\(#function) \(identifier)"}

		super.init(
			identifier: identifier,
			icon: icon,
			name: name,
			data: PexelsData(),
			filter: filter,
			loadHandler: Self.loadContents,
			removeHandler: removeHandler)
		
		self.saveHandler = saveHandler

		#if os(macOS)
		
		self.observers += NotificationCenter.default.publisher(for:NSCollectionView.didScrollToEnd, object:self).sink
		{
			[weak self] _ in self?.didScrollToEnd()
		}
		
		#elseif os(iOS)
		
		#warning("TODO: implement")
		
		#endif
	}

	// Pexels Container can never be expanded, as they do not have any sub-containers
	
	override open var canExpand: Bool
	{
		false
	}
	
	/// Returns the list of allowed sort Kinds for this Container
		
	override open var allowedSortTypes:[Object.Filter.SortType]
	{
		[]
	}


//----------------------------------------------------------------------------------------------------------------------


	/// This method will be called when the user scrolls to the end of the NSCollectionView.
	
	func didScrollToEnd()
	{
		guard let pexelsData = data as? PexelsData else { return }
		guard let pexelsFilter = filter as? PexelsFilter else { return }
		guard !pexelsFilter.searchString.isEmpty else { return }
		guard pexelsFilter.rating == 0 else { return }

		// If the content is not being filtered by rating, then load the next page of data
		
		if !pexelsData.didReachEnd
		{
			pexelsData.loadNextPage = true
			self.load(with:nil)
		}
	}
	
	
	// To be overridden by subclasses
	
	class func loadContents(for identifier:String, data:Any, filter:Object.Filter) async throws -> Loader.Contents
	{
		return ([],[])
	}
	
	/// Encodes/decodes a PexelsFilter from Data
	
	var filterData:Data?
	{
		get
		{
			guard let filter = self.filter as? PexelsFilter else { return nil }
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


//----------------------------------------------------------------------------------------------------------------------


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
}


//----------------------------------------------------------------------------------------------------------------------

