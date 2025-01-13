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


//----------------------------------------------------------------------------------------------------------------------


open class PhotosFilter : Object.Filter, Equatable
{
	/// Returns the supported mediaTypes for this Source. Possible values are .image and .video
	
	public let allowedMediaTypes:[Object.MediaType]


//----------------------------------------------------------------------------------------------------------------------


	/// Create a new Filter with the specified allowed MediaTypes
	
	public init(allowedMediaTypes:[Object.MediaType])
	{
		self.allowedMediaTypes = allowedMediaTypes
		super.init()
	}
	
	public required init(from decoder:Decoder) throws
	{
		fatalError("init(from:) has not been implemented")
	}
	
	
//----------------------------------------------------------------------------------------------------------------------


	/// Returns PHFetchOptions that filter by mediaType and returns the PHAssets already correctly sorted
	
	var assetFetchOptions:PHFetchOptions
	{
        let options = PHFetchOptions()

		if let mediaType = self.assetMediaType
		{
			options.predicate = NSPredicate(format:"mediaType = %d", mediaType.rawValue)
		}

		if sortType == .captureDate || sortType == .creationDate
		{
			let isAscending = sortDirection == .ascending
			options.sortDescriptors = [NSSortDescriptor(key:"creationDate", ascending:isAscending)]
		}
        
        return options
	}


	/// Returns the required PHAssetMediaType for this Source, or nil if any mediaType is allowed
	
	var assetMediaType:PHAssetMediaType?
	{
		if self.allowedMediaTypes == [.image]
		{
			return .image
		}
		else if self.allowedMediaTypes == [.video]
		{
			return .video
		}

		return nil
	}
	
	
//----------------------------------------------------------------------------------------------------------------------


	public static func == (lhs:PhotosFilter, rhs:PhotosFilter) -> Bool
	{
		lhs.searchString == rhs.searchString &&
		lhs.rating == rhs.rating &&
		lhs.sortType == rhs.sortType &&
		lhs.sortDirection == rhs.sortDirection
	}
	
	
	override open var objectComparator : ObjectComparator?
	{
		if sortType == .captureDate
		{
			let comparator = Self.compareCreationDate
			if sortDirection == .ascending { return comparator }
			return { !comparator($0,$1) }
		}
		else if sortType == .creationDate
		{
			let comparator = Self.compareCreationDate
			if sortDirection == .ascending { return comparator }
			return { !comparator($0,$1) }
		}
		else if sortType == .rating
		{
			let comparator = Self.compareRating
			if sortDirection == .ascending { return comparator }
			return { !comparator($0,$1) }
		}
		else if sortType == .useCount
		{
			let comparator = Self.compareUseCount
			if sortDirection == .ascending { return comparator }
			return { !comparator($0,$1) }
		}
		
		return nil
	}

	/// Sorts Objects by captureDate

	public static func compareCreationDate(_ object1:Object,_ object2:Object) -> Bool
	{
		guard let asset1 = object1.data as? PHAsset else { return false }
		guard let asset2 = object2.data as? PHAsset else { return false }
		guard let date1 = asset1.creationDate else { return false }
		guard let date2 = asset2.creationDate else { return false }
		return date1 < date2
	}
}


//----------------------------------------------------------------------------------------------------------------------
