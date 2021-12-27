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


open class Object : ObservableObject, Identifiable
{
	/// This unique identifier is persistent across application launches and should be able to locate an object again
	
	public let identifier:String
	
	/// The name of the object for UI display purposes
	
	public let name:String
	
	/// This can be any kind of information that subclasses need to their job.
	
	public let info:Any
	
	/// The Loader is responsible for loading the contents of this Object
	
	public let loader:Loader
	
	/// The thumbnail image of this Object
	
	@MainActor @Published public private(set) var thumbnailImage:CGImage? = nil

	/// This dictionary contains various metadata information, usually with keys derived from ImageIO or AVFoundation
	
	@MainActor @Published public private(set) var metadata:[String:Any]? = nil

//	@MainActor @Published public private(set) var isLocallyAvailable:Bool = false
//	@MainActor @Published public private(set) var isDownloadable:Bool = false
//	@MainActor @Published public private(set) var isStreaming:Bool = false
	
	@Published public var rating:Int = 0
	@Published public var useCount:Int = 0
	

	public init(identifier:String, name:String, info:Any, loadThumbnailHandler:@escaping Object.Loader.LoadThumbnailHandler, loadMetadataHandler:@escaping Object.Loader.LoadMetadataHandler, downloadFileHandler:@escaping Object.Loader.DownloadFileHandler)
	{
		self.identifier = identifier
		self.name = name
		self.info = info
		
		self.loader = Object.Loader(
			identifier: identifier,
			info: info,
			loadThumbnailHandler: loadThumbnailHandler,
			loadMetadataHandler: loadMetadataHandler,
			downloadFileHandler: downloadFileHandler)
	}
	

	// Required by the Identifiable protocol
	
	nonisolated public var id:String
	{
		identifier
	}


	public func load(_ completionHandler:(()->Void)? = nil)
	{
//		guard thumbnailImage == nil || metadata == nil else { return }
		
		Task
		{
			let image = try? await self.loader.thumbnailImage
			let metadata = try? await self.loader.metadata

			await MainActor.run
			{
				self.thumbnailImage = image
				self.metadata = metadata
				
//				self.isLocallyAvailable = true
//				self.isDownloadable = false
//				self.isStreaming = false
				
				completionHandler?()
			}
		}
	}


	/// Purges the thumbnailImage and metadata. This can help to reduce memory footprint.
	
	public func purge()
	{
		Task
		{
			let isLoadingThumbnail = await self.loader.isLoadingThumbnail
			let isLoadingMetadata = await self.loader.isLoadingMetadata
			if isLoadingThumbnail || isLoadingMetadata { return }
			
			await self.loader.purge()
			
			await MainActor.run
			{
				self.thumbnailImage = nil
				self.metadata = nil
			}
		}
	}
	
	var localURL:URL
	{
		get async throws
		{
			try await self.loader.localURL
		}
	}
}
	
	
//----------------------------------------------------------------------------------------------------------------------


