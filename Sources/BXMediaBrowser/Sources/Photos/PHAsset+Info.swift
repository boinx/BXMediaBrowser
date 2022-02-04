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


/// The following accessors are taken from https://stackoverflow.com/questions/32687403/phasset-get-original-file-name
/// and https://slk11075.medium.com/traps-for-phasset-how-to-get-filename-from-phasset-67d856e75c64

extension PHAsset
{
	/// Returns the original filename for the PHAsset
	
    var originalFilename:String?
    {
		self.primaryResource?.originalFilename
    }


	/// Returns the UTI for the PHAsset
	
    var uti:String
    {
		// First try to get an exact UTI from the PHAsset, e.g. "public.jpeg" or "public.tiff"
		
        if let uti = self.primaryResource?.uniformTypeIdentifier
		{
			return uti
		}

		// If that fails that simply try to map the mediatype to a more generic UTI
		
		if self.mediaType == .video
		{
			return String.movieUTI
		}
		else if self.mediaType == .audio
		{
			return String.audioUTI
		}
		
		return String.imageUTI
    }


	/// Returns the primary (most important) PHAssetResource
	
    var primaryResource:PHAssetResource?
    {
        let types:Set<PHAssetResourceType>

        switch mediaType
        {
			case .video: 		types = [.video,.fullSizeVideo]
			case .image: 		types = [.photo,.fullSizePhoto]
			case .audio: 		types = [.audio]
			case .unknown: 		types = []
			@unknown default: 	types = []
        }

        let resources = PHAssetResource.assetResources(for:self)
        let resource = resources.first { types.contains($0.type) }
        return resource ?? resources.first
    }
}


//----------------------------------------------------------------------------------------------------------------------


