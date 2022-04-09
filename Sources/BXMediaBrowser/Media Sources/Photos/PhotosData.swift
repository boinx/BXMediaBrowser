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


import Photos
import BXSwiftUtils


//----------------------------------------------------------------------------------------------------------------------


enum PhotosData
{
	/// Information for the "All Photos" collection (the whole library)
	
	case library(assets:PHFetchResult<PHAsset>)
	
	/// Information that specifies a single album or smart album
	
	case album(collection:PHAssetCollection)
	
	/// Information that specifies a single folder
	
	case folder(collections:[PHCollection], fetchResult:Any)
	
	/// Information that specifies smart folder for a DateInterval
	
	case dateInterval(unit:Calendar.Component, assetCollection:PHAssetCollection?, subCollections:[(DateInterval,PHAssetCollection)])
}


//----------------------------------------------------------------------------------------------------------------------


extension PhotosData
{
	/// Extracts the items from a PHFetchResult, e.g. PHCollections
	
	public static func items<T>(for fetchResult:PHFetchResult<T>) -> [T]
	{
		var items:[T] = []
		let n = fetchResult.count
		
		for i in 0 ..< n
		{
			let item = fetchResult[i]
			items += item
		}
			
		return items
	}
	
	
//	/// Returns the start and end date for a .timespan
//
//	public var dateRange:(Date,Date)?
//	{
//		if case .timespan(_, let year, let month, let day) = self
//		{
//			if let year = year
//			{
//				if let month = month
//				{
//					if let day = day
//					{
//						if let start = Date.fromComponents(year:year, month:month, day:day),
//						   let end = Calendar.current.date(byAdding:.day, value:1, to:start, wrappingComponents:true)
//						{
//							return (start,end)
//						}
//					}
//
//					if let start = Date.fromComponents(year:year, month:month, day:0),
//					   let end = Calendar.current.date(byAdding:.month, value:1, to:start, wrappingComponents:true)
//					{
//						return (start,end)
//					}
//				}
//
//				if let start = Date.fromComponents(year:year, month:0, day:0),
//				   let end = Calendar.current.date(byAdding:.year, value:1, to:start, wrappingComponents:true)
//				{
//					return (start,end)
//				}
//			}
//		}
//
//		return nil
//	}
//
//	public var timespanTitle:String
//	{
//		if case .timespan(_, let year, let month, let day) = self
//		{
//			if let year = year
//			{
//				if let month = month
//				{
//					if let day = day
//					{
//						return "\(year)/\(month)/\(day)"
//					}
//
//					return "\(year)/\(month)"
//				}
//
//				return "\(year)"
//			}
//		}
//
//		return ""
//	}
}


//----------------------------------------------------------------------------------------------------------------------


