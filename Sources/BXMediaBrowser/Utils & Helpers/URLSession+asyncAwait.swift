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
	/// Downloads some data from the specified URL
	
    public func data(with url:URL, delegate:URLSessionTaskDelegate? = nil) async throws -> Data
    {
        try await withCheckedThrowingContinuation
        {
			continuation in

            let task = self.dataTask(with:url)
            {
				(data,response,err) in

				if let error = self.error(for:data,response,err)
				{
					continuation.resume(throwing:error)
				}
				else if let data = data
				{
					continuation.resume(returning:(data))
				}
				else
				{
					continuation.resume(throwing:URLError(.badServerResponse))
				}
            }

			if #available(macOS 12.0, iOS 15, *)
			{
				task.delegate = delegate
			}
			
            task.resume()
        }
    }


	/// Downloads some data from the specified URLRequest
	
    public func data(with request:URLRequest, delegate:URLSessionTaskDelegate? = nil) async throws -> Data
    {
        try await withCheckedThrowingContinuation
        {
			continuation in

            let task = self.dataTask(with:request)
            {
				(data,response,err) in

				if let error = self.error(for:data,response,err)
				{
					continuation.resume(throwing:error)
				}
				else if let data = data
				{
					continuation.resume(returning:(data))
				}
				else
				{
					continuation.resume(throwing:URLError(.badServerResponse))
				}
            }

			if #available(macOS 12.0, iOS 15, *)
			{
				task.delegate = delegate
			}
			
            task.resume()
        }
    }
    
 
	/// This helper function evaluates networking errors, HTTP responses, and received data to return an overall error
	
	func error(for data:Data?,_ response:URLResponse?,_ error:Error?) -> Error?
	{
		if let error = error
		{
			return error
		}
		
		if let response = response as? HTTPURLResponse, response.statusCode < 200 || response.statusCode >= 300
		{
			return URLError(.badServerResponse)
		}
		
		if data == nil
		{
			return URLError(.badServerResponse)
		}
		
		return nil
	}


//----------------------------------------------------------------------------------------------------------------------


	/// Downloads a file from the specified URL
	
	public func downloadFile(from remoteURL:URL, delegate:URLSessionTaskDelegate? = nil) async throws -> URL
    {
		return try await withCheckedThrowingContinuation
		{
			continuation in

			let isParentProgressAvailable = Progress.current() != nil
		
			// Download the file from remoteURL
			
			let task = self.downloadTask(with:remoteURL)
			{
				(tmpURL,response,err) in

				if let error = self.error(for:tmpURL,response,err)
				{
					continuation.resume(throwing:error)
				}
				else if let url = self.localURL(for:tmpURL)
				{
					continuation.resume(returning:(url))
				}
				else
				{
					continuation.resume(throwing:URLError(.badServerResponse))
				}
			}

			if #available(macOS 12.0, iOS 15, *)
			{
				task.delegate = delegate
			}
			
			// If Progress.current is nil, this means that we didn't see the parent Progress object, because it
			// was created in a different thread (most likely the main thread). In this case we try to attach
			// to globalParent (which is visible to all threads) as a workaround
			
			if !isParentProgressAvailable
			{
				Progress.globalParent?.addChild(task.progress, withPendingUnitCount:1)
			}
			
			// Start downloading
			
			task.resume()
		}
    }


	/// Downloads a file from the specified URLRequest
	
	public func downloadFile(with request:URLRequest, delegate:URLSessionTaskDelegate? = nil) async throws -> URL
    {
		return try await withCheckedThrowingContinuation
		{
			continuation in

			let isParentProgressAvailable = Progress.current() != nil
		
			// Download the file from remoteURL
			
			let task = self.downloadTask(with:request)
			{
				(tmpURL,response,err) in

				if let error = self.error(for:tmpURL,response,err)
				{
					continuation.resume(throwing:error)
				}
				else if let url = self.localURL(for:tmpURL)
				{
					continuation.resume(returning:(url))
				}
				else
				{
					continuation.resume(throwing:URLError(.badServerResponse))
				}
			}

			if #available(macOS 12.0, iOS 15, *)
			{
				task.delegate = delegate
			}
			
			// If Progress.current is nil, this means that we didn't see the parent Progress object, because it
			// was created in a different thread (most likely the main thread). In this case we try to attach
			// to globalParent (which is visible to all threads) as a workaround
			
			if !isParentProgressAvailable
			{
				Progress.globalParent?.addChild(task.progress, withPendingUnitCount:1)
			}
			
			// Start downloading
			
			task.resume()
		}
    }

	
	/// This helper function evaluates networking errors, HTTP responses, and downloaded file to return an overall error
	
	func error(for url:URL?,_ response:URLResponse?,_ error:Error?) -> Error?
	{
		if let error = error
		{
			return error
		}
		
		if let response = response as? HTTPURLResponse, response.statusCode < 200 || response.statusCode >= 300
		{
			return URLError(.badServerResponse)
		}
		
		if url == nil
		{
			return URLError(.badServerResponse)
		}
		
		return nil
	}
	
	
	/// Moves the file at tmpURL to a backup location (because tmpURL will be deleted after lifetime of the completionHandler)
					
	func localURL(for tmpURL:URL?) -> URL?
	{
		guard let tmpURL = tmpURL else { return nil }
		
		let backupURL = tmpURL.appendingPathExtension("backup")
		try? FileManager.default.removeItem(at:backupURL)
		try? FileManager.default.linkItem(at:tmpURL, to:backupURL)
		
		return backupURL
	}
	
	
//----------------------------------------------------------------------------------------------------------------------


}
