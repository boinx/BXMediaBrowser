//**********************************************************************************************************************
//
//  QLThumbnailGenerator+asyncAwait.swift
//	Provides async-await API for QLThumbnailGenerator
//  Copyright ©2022 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


#if os(iOS)

import Foundation
import CoreGraphics
import QuickLookThumbnailing


//----------------------------------------------------------------------------------------------------------------------


extension QLThumbnailGenerator
{
	/// Creates a thumbnail image for the specified URL and size
	
    public func thumbnail(with url:URL, maxSize:CGSize, type:QLThumbnailGenerator.Request.RepresentationTypes = .thumbnail) async throws -> CGImage
    {
        try await withCheckedThrowingContinuation
        {
			continuation in

			let request = QLThumbnailGenerator.Request(
				fileAt:url,
				size:maxSize,
				scale:1.0,
				representationTypes:type)

			self.generateRepresentations(for:request)
			{
				(thumbnail,type,error) in

				if let error = error
				{
					continuation.resume(throwing:error)
				}
				else if let image = thumbnail?.uiImage.cgImage
				{
					continuation.resume(returning:image)
				}
			}
        }
    }
}


//----------------------------------------------------------------------------------------------------------------------


#endif
