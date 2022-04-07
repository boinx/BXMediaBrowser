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


extension PHCollectionList
{
	public static func years(mediaType:PHAssetMediaType = .image, start:Int? = nil, end:Int? = nil) -> PHCollectionList
	{
		let currentYear = end ?? Calendar.current.currentYear
		let startYear = start ?? currentYear - 20
		
		let fetchOptions = PHFetchOptions()
		fetchOptions.wantsIncrementalChangeDetails = false

		var yearCollections:[PHAssetCollection] = []
		
		for year in (startYear...currentYear).reversed()
		{
			guard let interval = DateInterval(year:year) else { continue }
			
			fetchOptions.predicate = NSPredicate(
				format: "creationDate > %@ AND creationDate < %@",
				interval.start as NSDate,
				interval.end as NSDate)

			let assets = PHAsset.fetchAssets(with:mediaType, options:fetchOptions)
				
			if assets.count > 0
			{
				yearCollections += PHAssetCollection.transientAssetCollection(withAssetFetchResult:assets, title:"\(year)")
			}
		}

		let title = "Years"
		return PHCollectionList.transientCollectionList(with:yearCollections, title:title)
	}
}

	
//----------------------------------------------------------------------------------------------------------------------


extension Calendar
{
    var currentYear:Int
    {
        component(.year, from:Date())
    }
    
    func startOfYear(_ year:Int? = nil) -> Date?
    {
        date(from:DateComponents(year:year ?? currentYear))
    }
}


//----------------------------------------------------------------------------------------------------------------------


extension DateInterval
{
    init?(year:Int)
    {
        guard let start = Calendar.current.startOfYear(year), let end = Calendar.current.startOfYear(year + 1) else
        {
            return nil
        }
        
        self.init(start:start, end:end)
    }
}


//----------------------------------------------------------------------------------------------------------------------


