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
import BXSwiftUtils

#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif

#if canImport(MobileCoreServices)
import MobileCoreServices
#endif


//----------------------------------------------------------------------------------------------------------------------


open class Object : NSObject, ObservableObject, Identifiable, BXSignpostMixin
{
	/// This unique identifier is persistent across application launches and should be able to locate an object again
	
	public let identifier:String
	
	/// The name of the object for UI display purposes
	
	public var name:String
	
	/// This can be any kind of information that subclasses need to their job.
	
	public var data:Any
	
	/// The Loader is responsible for loading the contents of this Object
	
	public let loader:Loader
	
	/// The thumbnail image of this Object
	
	@MainActor @Published public private(set) var thumbnailImage:CGImage? = nil

	/// This dictionary contains various metadata information, usually with keys derived from ImageIO or AVFoundation
	
	@MainActor @Published public private(set) var metadata:[String:Any]? = nil
	
	/// A reference to the next Object according to the current ordering
	
	public internal(set) weak var next:Object? = nil
	
	/// Returns true if the media file is avaiable on the local device and can be used directly without downloading
	
	@Published public internal(set) var isLocallyAvailable:Bool = true
	
	/// Returns true if the media file is at a remote location, but can be downloaded to the local device
	
	@Published public internal(set) var isDownloadable:Bool = false
	
	/// Returns true if the media is DRM protected
	
	@Published public internal(set) var isDRMProtected:Bool = false

	/// Returns true if this Object can be used. If false it will be grayed out, but still displayed in the browser.
	
	@Published public var isEnabled:Bool = true
	
	
//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Creating
	
	public init(identifier:String, name:String, data:Any, loadThumbnailHandler:@escaping Object.Loader.LoadThumbnailHandler, loadMetadataHandler:@escaping Object.Loader.LoadMetadataHandler, downloadFileHandler:@escaping Object.Loader.DownloadFileHandler)
	{
		self.identifier = identifier
		self.name = name
		self.data = data
		
		self.loader = Object.Loader(
			identifier: identifier,
			data: data,
			loadThumbnailHandler: loadThumbnailHandler,
			loadMetadataHandler: loadMetadataHandler,
			downloadFileHandler: downloadFileHandler)
	}
	

	// Required by the Identifiable protocol
	
	nonisolated public var id:String
	{
		identifier
	}

	/// Returns the MediaType of this Object. Subclasses should override this property to return their specific MediaType.
	
	nonisolated open var mediaType:MediaType
	{
		return .image
	}
	
	/// Returns a name that is suitable for displaying in the user interface. Subclasses may override this accessor
	
	open var displayName:String
	{
		self.name
	}
	
	
//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Loading
	
	public func load(_ completionHandler:(()->Void)? = nil)
	{
//		guard thumbnailImage == nil || metadata == nil else { return }
		
		Task
		{
			let token = self.beginSignpost(in:"Object","load")
			defer { self.endSignpost(with:token, in:"Object","load") }

			let image = try? await self.loader.thumbnailImage
			let metadata = try? await self.loader.metadata

			await MainActor.run
			{
				self.thumbnailImage = image
				self.metadata = metadata
				
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
	

//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Metadata
	
	/// Transforms the metadata dictionary into an order list of human readable information (with optional click actions)
	
	@MainActor open var localizedMetadata:[ObjectMetadataEntry]
    {
		let dict = self.metadata ?? [:]
		var array:[ObjectMetadataEntry] = []
		
		for (key,value) in dict
		{
			array += ObjectMetadataEntry(label:key, value:"\(value)")
		}
		
		return array
    }


	/// The rating value of this Object is stored by the StatisticsController, which takes care of persisting the values.
	
	@MainActor open var rating:Int
	{
		set
		{
			self.objectWillChange.send()
			StatisticsController.shared.setRating(newValue, for:self)
		}
		
		get { StatisticsController.shared.rating(for:self) }
	}
	
	/// The useCount of this Object is stored by the StatisticsController, which takes care of persisting the values.
	
	@MainActor open var useCount:Int
	{
		StatisticsController.shared.useCount(for:self)
	}

	/// This optional comment can be displayed in the user interface, e.g. as a tooltip
	
	@MainActor open var comment:String?
	{
		nil
	}
	

//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Media File Access
	
	/// Returns the filename of the local file. This property must be overridden by conrete subclasses to provide
	/// the correct filename. In some cases (e.g. Photos.app) a filename is not available, so a generated name
	/// must be used.
	
	open var localFileName:String
	{
		var name = self.name
		
		if name.isEmpty
		{
			name = self.identifier
		}
		
		return name
	}
	
	
	/// Returns the UTI for the local file. Since the Object can still be in the cloud, and needs to be downloaded
	/// first, thi UTI must be know ahead of the download by the concrete subclass.
	
	open var localFileUTI:String
	{
		if #available(macOS 12, iOS 14, *)
		{
			return UTType.fileURL.identifier
		}
		else
		{
			return kUTTypeFileURL as String // To be overridden by subclasses
		}
	}
	
	
	/// Returns the URL to the local file. This can possibly trigger a download, if the Object is still in the cloud.
	
	open var localFileURL:URL
	{
		get async throws
		{
			let url = try await self.loader.localURL
			return url
		}
	}

}
	
	
//----------------------------------------------------------------------------------------------------------------------


