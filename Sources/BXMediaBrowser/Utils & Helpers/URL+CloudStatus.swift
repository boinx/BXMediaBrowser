//**********************************************************************************************************************
//
//  URL+CloudStatus.swift
//	Helps to avoid unwanted downloads of cloud based files
//  Copyright ©2026 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation


//----------------------------------------------------------------------------------------------------------------------


extension URL
{
	/// Returns true if this is a cloud based file (e.g. iCloud Drive) whose contents are not available on disk.
	///
	/// Reading the contents of such a "dataless" file (CGImageSource, AVURLAsset, etc) makes the system download the
	/// WHOLE file, regardless of how little data is actually read. Loading thumbnails and metadata must therefore
	/// check this first, so that merely browsing a folder doesn't download every file in it.
	///
	/// The resource values are always fetched fresh, because a file may have been evicted after the folder was listed.
	
	public var isEvictedCloudItem:Bool
	{
		var url = self
		url.removeAllCachedResourceValues()
		
		guard let values = try? url.resourceValues(forKeys:[.isUbiquitousItemKey,.ubiquitousItemDownloadingStatusKey]) else { return false }
		guard values.isUbiquitousItem == true else { return false }
		
		// Please note that .downloaded (an older version is on disk, but a newer one exists in the cloud) does not
		// count as evicted, since there is local data that can be read without triggering a download.
		
		return values.ubiquitousItemDownloadingStatus == .notDownloaded
	}
}


//----------------------------------------------------------------------------------------------------------------------
