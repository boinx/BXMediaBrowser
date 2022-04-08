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
import Foundation


//----------------------------------------------------------------------------------------------------------------------


extension PHAssetCollection
{
	public static func yearsCollections(mediaType:PHAssetMediaType? = nil) -> [(DateInterval,PHAssetCollection)]
	{
		let currentYear = Calendar.current.currentYear
		let startYear = currentYear - 20
		var collections:[(DateInterval,PHAssetCollection)] = []
		
		for year in (startYear...currentYear).reversed()
		{
			guard let interval = Calendar.current.dateInterval(year:year) else { continue }
			let title = "\(year)"
			
			if let assetCollection = self.dateIntervalCollection(for:interval, mediaType:mediaType, title:title)
			{
				collections += (interval,assetCollection)
			}
		}

		return collections
	}


	public static func monthsCollections(year:Int, mediaType:PHAssetMediaType? = nil) -> [(DateInterval,PHAssetCollection)]
	{
		var collections:[(DateInterval,PHAssetCollection)] = []
		var calendar = Calendar.current
		
		for month in 1 ... 12
		{
			guard let interval = calendar.dateInterval(year:year, month:month) else { break }
			let title = calendar.localizedShortMonthName(at:month)
			
			if let assetCollection = self.dateIntervalCollection(for:interval, mediaType:mediaType, title:title)
			{
				collections += (interval,assetCollection)
			}
		}

		return collections
	}


	public static func daysCollections(year:Int, month:Int, mediaType:PHAssetMediaType? = nil) -> [(DateInterval,PHAssetCollection)]
	{
		var collections:[(DateInterval,PHAssetCollection)] = []
		
		for day in 1 ... 31
		{
			guard let interval = Calendar.current.dateInterval(year:year, month:month, day:day) else { break }
			let title = DateFormatter.localizedString(from:interval.start, dateStyle:.medium, timeStyle:.none)
			
			if let assetCollection = self.dateIntervalCollection(for:interval, mediaType:mediaType, title:title)
			{
				collections += (interval,assetCollection)
			}
		}

		return collections
	}


//----------------------------------------------------------------------------------------------------------------------


	public static func dateIntervalCollection(for interval:DateInterval, mediaType:PHAssetMediaType? = nil, title:String) -> PHAssetCollection?
	{
		let fetchOptions = PHFetchOptions()
		fetchOptions.wantsIncrementalChangeDetails = false

		if let mediaType = mediaType
		{
			fetchOptions.predicate = NSPredicate(
				format: "creationDate > %@ AND creationDate < %@ AND mediaType = %d",
				interval.start as NSDate,
				interval.end as NSDate,
				mediaType.rawValue)
		}
		else
		{
			fetchOptions.predicate = NSPredicate(
				format: "creationDate > %@ AND creationDate < %@",
				interval.start as NSDate,
				interval.end as NSDate)
		}
		
		let fetchResult = PHAsset.fetchAssets(with:fetchOptions)

		if fetchResult.count > 0
		{
			return PHAssetCollection.transientAssetCollection(withAssetFetchResult:fetchResult, title:title)
		}

		return nil
	}
}

	
//----------------------------------------------------------------------------------------------------------------------
