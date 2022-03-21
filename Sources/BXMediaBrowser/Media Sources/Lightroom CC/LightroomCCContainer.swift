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


//----------------------------------------------------------------------------------------------------------------------


open class LightroomCCContainer : Container
{
//	class PexelsData
//	{
//		var lastUsedFilter = PexelsFilter()
//		var page = 0
//		var photos:[Pexels.Photo] = []
//		var videos:[Pexels.Video] = []
//	}
//
//	/// This handler is called when the user clicks on the Save button - it will permanently save a Pexels search
//
//	open var saveHandler:SaveContainerHandler? = nil
//
//	public typealias SaveContainerHandler = (Container)->Void
	

//----------------------------------------------------------------------------------------------------------------------


//	// Pexels Container can never be expanded, as they do not have any sub-containers
//
//	override open var canExpand: Bool
//	{
//		false
//	}
//
//	/// Returns the list of allowed sort Kinds for this Container
//
//	override open var allowedSortTypes:[Object.Filter.SortType]
//	{
//		[]
//	}


//----------------------------------------------------------------------------------------------------------------------


	/// Encodes/decodes a PexelsFilter from Data
	
//	var filterData:Data?
//	{
//		get
//		{
//			guard let pexelsData = self.data as? PexelsData else { return nil }
//			let filter = pexelsData.lastUsedFilter
//			let data = try? JSONEncoder().encode(filter)
//			return data
//		}
//		
//		set
//		{
//			guard let data = newValue else { return }
//			guard let pexelsData = self.data as? PexelsData else { return }
//			guard let filter = try? JSONDecoder().decode(PexelsFilter.self, from:data) else { return }
//			pexelsData.lastUsedFilter = filter
//		}
//	}


//----------------------------------------------------------------------------------------------------------------------


	/// Returns a textual description of the filter params (for displaying in the UI)
	
//	var description:String
//	{
//		guard let filter = self.filter as? PexelsFilter else { return "" }
//		return Self.description(with:filter)
//	}
//
//	/// Returns a textual description of the filter params (for displaying in the UI)
//
//	class func description(with filter:PexelsFilter) -> String
//	{
//		let searchString = filter.searchString
//		let orientation = filter.orientation != .any ? filter.orientation.localizedName : ""
//		let color = filter.color != .any ? filter.color.localizedName : ""
//
//		var description = searchString
//		if !orientation.isEmpty { description += ", \(orientation)" }
//		if !color.isEmpty { description += ", \(color)" }
//		return description
//	}
}


//----------------------------------------------------------------------------------------------------------------------

