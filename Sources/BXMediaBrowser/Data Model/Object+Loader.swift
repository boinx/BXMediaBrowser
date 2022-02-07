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


import SwiftUI


//----------------------------------------------------------------------------------------------------------------------


// MARK: -


extension Object
{
	public actor Loader
	{
		public typealias LoadThumbnailHandler = (String,Any) async throws -> CGImage
		public typealias LoadMetadataHandler = (String,Any) async throws -> [String:Any]
		public typealias DownloadFileHandler = (String,Any) async throws -> URL

		private let identifier:String
		private let data:Any
		private let loadThumbnailHandler:LoadThumbnailHandler
		private let loadMetadataHandler:LoadMetadataHandler
		private let downloadFileHandler:DownloadFileHandler
	
		public init(identifier:String, data:Any, loadThumbnailHandler:@escaping LoadThumbnailHandler, loadMetadataHandler:@escaping LoadMetadataHandler, downloadFileHandler:@escaping DownloadFileHandler)
		{
			self.identifier = identifier
			self.data = data
			self.loadThumbnailHandler = loadThumbnailHandler
			self.loadMetadataHandler = loadMetadataHandler
			self.downloadFileHandler = downloadFileHandler
		}
	
	
//----------------------------------------------------------------------------------------------------------------------


		public func purge() async
		{
			logDataModel.verbose {"Purging data for \(identifier)"}
			self._thumbnailImage = nil
			self._metadata = nil
		}
	
	
//----------------------------------------------------------------------------------------------------------------------


		// MARK: -

		/// Returns the thumbnail image for this media object. This will trigger an async download
		/// task if the thumbnail is not available yet.
		
		public var thumbnailImage:CGImage
		{
			get async throws
			{
				// If we already have the thumbnail image, then return it immediately

				if let image = self._thumbnailImage
				{
					return image
				}

				// If not then check if we already have a download task - if yes then wait for its result

				if let task = self._loadThumbnailTask
				{
					return try await task.value
				}

				// If not then create a new download task and wait for its result

				let task = Task<CGImage,Swift.Error>
				{
					logDataModel.verbose {"Loading thumbnail for \(identifier)"}
					
					let image = try await self.loadThumbnailHandler(identifier,data)
					self._thumbnailImage = image
					self._loadThumbnailTask = nil
					return image
				}

				self._loadThumbnailTask = task
				return try await task.value
			}
		}
		
		/// Returns true if the thumbnail image is currently being loaded. Can be used to display progress info like a spinning wheel.
		
		public var isLoadingThumbnail:Bool { _loadThumbnailTask != nil }

		/// Stores the downloaded thumbnail image
		
		private var _thumbnailImage:CGImage? = nil
		
		/// The currently running download task
		
		private var _loadThumbnailTask:Task<CGImage,Swift.Error>? = nil
	
	
//----------------------------------------------------------------------------------------------------------------------


		// MARK: -
		
		/// Returns the thumbnail image for this media object. This will trigger an async download
		/// task if the thumbnail is not available yet.
		
		public var metadata:[String:Any]
		{
			get async throws
			{
				// If we already have the metadata, then return it immediately
				
				if let metadata = self._metadata
				{
					return metadata
				}
				
				// If not then check if we already have a download task - if yes then wait for its result
				
				if let task = self._loadMetadataTask
				{
					return try await task.value
				}

				// If not then create a new download task and wait for its result
				
				let task = Task<[String:Any],Swift.Error>
				{
					logDataModel.verbose {"Loading metadate for \(identifier)"}
					
					let metadata:[String:Any] = try await self.loadMetadataHandler(identifier,data)
					self._metadata = metadata
					self._loadMetadataTask = nil
					return metadata
				}
				
				self._loadMetadataTask = task
				return try await task.value
			}
		}

		/// The cached metadata dictionary
		
		private var _metadata:[String:Any]? = nil
		
		/// The currently running task to load the metadata
		
		private var _loadMetadataTask:Task<[String:Any],Swift.Error>? = nil
		
		/// Returns true if the metadata is currently being loaded. Can be used to display progress info like a spinning wheel.
		
		public var isLoadingMetadata:Bool { _loadMetadataTask != nil }
		
	
//----------------------------------------------------------------------------------------------------------------------


		// MARK: -
		
		/// Returns the local media file URL. This can potentially trigger a lengthy download from the Internet,
		/// depending on the Source that created this Object.
		
		var localURL:URL
		{
			get async throws
			{
				// If we already have the local file, then return it immediately. Progress will be faked.
				
				if let url = self._localFileURL
				{
					let childProgress = Progress(totalUnitCount:1)
					Progress.globalParent?.addChild(childProgress, withPendingUnitCount:1)
					childProgress.completedUnitCount = 1
					return url
				}
				
				// If not then check if we already have a download task - if yes then wait for its result
				
				if let task = self._downloadFileTask
				{
					return try await task.value
				}

				// If not then create a new download task and wait for its result
				
				let task = Task<URL,Swift.Error>
				{
					do
					{
						let url:URL = try await self.downloadFileHandler(identifier,data)
						self._localFileURL = url
						self._downloadFileTask = nil
						return url
					}
					catch let error
					{
						self._localFileURL = nil
						self._downloadFileTask = nil
						throw error
					}
				}
				
				self._downloadFileTask = task
				return try await task.value
			}
		}
		
		/// If already available locally, this property caches the URL to the local file
		
		private var _localFileURL:URL? = nil
		
		/// If the file is currently being downloaded, this is the reference to the download Task
		
		private var _downloadFileTask:Task<URL,Swift.Error>? = nil
	}
}


//----------------------------------------------------------------------------------------------------------------------
