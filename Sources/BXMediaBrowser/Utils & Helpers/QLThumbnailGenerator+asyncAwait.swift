//**********************************************************************************************************************
//
//  QLThumbnailGenerator+asyncAwait.swift
//	Provides async-await API for QLThumbnailGenerator
//  Copyright ©2022-2026 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation
import CoreGraphics
import QuickLookThumbnailing


//----------------------------------------------------------------------------------------------------------------------


extension QLThumbnailGenerator
{
	public enum Error : Swift.Error
	{
		case thumbnailNotAvailable
	}
	
	
	/// Creates a thumbnail image for the specified URL and size.
	///
	/// Never call the synchronous QuickLook API (QLThumbnailImageCreate or synchronousGenerateThumbnail…) from an
	/// async function. QuickLookThumbnailing is itself built on Swift concurrency, so blocking a cooperative pool
	/// thread while waiting for its result starves the very pool that has to deliver that result. Once as many
	/// thumbnails are in flight as the machine has cores, the app deadlocks (FM-2532).
	
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

			// generateBestRepresentation calls its handler exactly once - unlike generateRepresentations, which calls
			// it once per representation type and would thus resume the continuation more than once (a hard crash).
			// The isResumed flag guards against any future change of that contract.
			
			var isResumed = false
			
			self.generateBestRepresentation(for:request)
			{
				(thumbnail,error) in

				guard !isResumed else { return }
				isResumed = true
				
				if let image = thumbnail?.cgImage
				{
					continuation.resume(returning:image)
				}
				else
				{
					// Resume with an error even when QuickLook reports neither an image nor an error, because
					// abandoning the continuation would leak the awaiting task forever

					continuation.resume(throwing:error ?? Error.thumbnailNotAvailable)
				}
			}
        }
    }
}


//----------------------------------------------------------------------------------------------------------------------
