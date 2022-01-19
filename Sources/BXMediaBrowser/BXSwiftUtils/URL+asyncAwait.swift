//**********************************************************************************************************************
//
//  URL+asyncAwait.swift
//	Provides async-await API for URL dataTask for pre macOS 12 or iOS 15
//  Copyright ©2022 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation


//----------------------------------------------------------------------------------------------------------------------


@available(macOS, deprecated:12.0, message:"Use the built-in API instead")
@available(iOS, deprecated:15.0, message:"Use the built-in API instead")

extension URLSession
{
    public func data(from url:URL, delegate:URLSessionTaskDelegate? = nil) async throws -> (Data, URLResponse)
    {
        try await withCheckedThrowingContinuation
        {
			continuation in

            let task = self.dataTask(with:url)
            {
				(data,response,error) in

                guard let data = data, let response = response else
                {
                    let error = error ?? URLError(.badServerResponse)
                    return continuation.resume(throwing:error)
                }

                continuation.resume(returning:(data,response))
            }

			task.delegate = delegate
            task.resume()
        }
    }


    public func data(for request:URLRequest, delegate:URLSessionTaskDelegate? = nil) async throws -> (Data, URLResponse)
    {
        try await withCheckedThrowingContinuation
        {
			continuation in

            let task = self.dataTask(with:request)
            {
				(data,response,error) in

                guard let data = data, let response = response else
                {
                    let error = error ?? URLError(.badServerResponse)
                    return continuation.resume(throwing:error)
                }

                continuation.resume(returning:(data,response))
            }

            task.resume()
        }
    }
}


//----------------------------------------------------------------------------------------------------------------------
