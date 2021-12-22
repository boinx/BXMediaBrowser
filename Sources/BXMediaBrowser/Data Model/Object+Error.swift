//
//  Object+Loader.swift
//  MediaBrowserTest
//  Created by Peter Baumgartner on 04.12.21.
//

import SwiftUI


//----------------------------------------------------------------------------------------------------------------------


extension Object
{
	public enum Error : Swift.Error
	{
		case notFound
		case loadThumbnailFailed
		case loadMetadataFailed
		case downloadFileFailed
	}
}


//----------------------------------------------------------------------------------------------------------------------
