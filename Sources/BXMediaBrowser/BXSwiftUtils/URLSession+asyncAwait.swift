//**********************************************************************************************************************
//
//  URL+asyncAwait.swift
//	Provides async-await API for URL dataTask for pre macOS 12 or iOS 15
//  Copyright ©2022 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation


//----------------------------------------------------------------------------------------------------------------------


extension URLSession
{

//	@available(macOS, deprecated:12.0, message:"Use the built-in API instead")
//	@available(iOS, deprecated:15.0, message:"Use the built-in API instead")

    public func data(from url:URL, delegate:URLSessionTaskDelegate? = nil) async throws -> Data
    {
        try await withCheckedThrowingContinuation
        {
			continuation in

            let task = self.dataTask(with:url)
            {
				(data,response,error) in

                guard let data = data else
                {
                    let error = error ?? URLError(.badServerResponse)
                    return continuation.resume(throwing:error)
                }

                continuation.resume(returning:(data))
            }

			task.delegate = delegate
            task.resume()
        }
    }


//----------------------------------------------------------------------------------------------------------------------


//	@available(macOS, deprecated:12.0, message:"Use the built-in API instead")
//	@available(iOS, deprecated:15.0, message:"Use the built-in API instead")

    public func data(for request:URLRequest, delegate:URLSessionTaskDelegate? = nil) async throws -> Data
    {
        try await withCheckedThrowingContinuation
        {
			continuation in

            let task = self.dataTask(with:request)
            {
				(data,response,error) in

                guard let data = data else
                {
                    let error = error ?? URLError(.badServerResponse)
                    return continuation.resume(throwing:error)
                }

                continuation.resume(returning:(data))
            }

			task.delegate = delegate
            task.resume()
        }
    }
    
 
//----------------------------------------------------------------------------------------------------------------------


	public func downloadFile(from remoteURL:URL, delegate:URLSessionTaskDelegate? = nil) async throws -> URL
    {
		return try await withCheckedThrowingContinuation
		{
			continuation in

			// Download the file from remoteURL
			
			let task = self.downloadTask(with:remoteURL)
			{
				(tmpURL,response,error) in

				// Report potential errors and bail out
				
				guard let tmpURL = tmpURL else
				{
					let error = error ?? URLError(.badServerResponse)
					return continuation.resume(throwing:error)
				}

				// Move file to backup location (because tmpURL will be deleted after lifetime of this completionHandler
				
				let tmpURL2 = tmpURL.appendingPathExtension("backup")
				try? FileManager.default.linkItem(at:tmpURL, to:tmpURL2)
				
				// Return URL to backup file instead
				
				continuation.resume(returning:(tmpURL2))
			}

			task.delegate = delegate
			
			// If Progress.current is nil, this means that we didn't see the parent Progress object, because it
			// was created in a different thread (most likely the main thread). In this case we try to attach
			// to globalParent (which is visible to all threads) as a workaround
			
			Progress.globalParent?.addChild(task.progress, withPendingUnitCount:1)
			
			// Start downloading
			
			task.resume()
		}
    }
}


//----------------------------------------------------------------------------------------------------------------------
