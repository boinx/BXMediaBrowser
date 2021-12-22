//
//  PhotosSource.swift
//  MediaBrowserTest
//  Created by Peter Baumgartner on 04.12.21.
//

import Photos


//----------------------------------------------------------------------------------------------------------------------


class PhotosChangeObserver : NSObject,PHPhotoLibraryChangeObserver
{
	var didChangeHandler:((PHChange)->Void)? = nil
	
	override public init()
	{
		super.init()

		PHPhotoLibrary.shared().register(self)
	}


    deinit
    {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }


    public func photoLibraryDidChange(_ change:PHChange)
    {
		DispatchQueue.main.async
		{
			self.didChangeHandler?(change)
		}
    }
}


//----------------------------------------------------------------------------------------------------------------------


