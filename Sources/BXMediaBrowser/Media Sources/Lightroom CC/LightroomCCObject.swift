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


import BXSwiftUtils
import BXSwiftUI
import CoreGraphics
import Foundation

#if canImport(QuickLookUI)
import QuickLookUI
#endif

#if canImport(MobileCoreServices)
import MobileCoreServices
#endif


//----------------------------------------------------------------------------------------------------------------------


open class LightroomCCObject : Object, AppLifecycleMixin
{
	/// Notification subscribers
	
	public var observers:[Any] = []
	

//----------------------------------------------------------------------------------------------------------------------


	/// Creates a new Object for the file at the specified URL

	public required init(with asset:LightroomCC.Asset)
	{
		super.init(
			identifier: Self.identifier(for:asset),
			name: asset.name,
			data: asset,
			loadThumbnailHandler: Self.loadThumbnail,
			loadMetadataHandler: Self.loadMetadata,
			downloadFileHandler: Self.downloadFile)
		
		// If we received a rating from Lightroom, then store it in our database
		
		if let rating = asset.rating, rating > 0 //, rating > StatisticsController.shared.rating(for:self)
		{
			StatisticsController.shared.setRating(rating, for:self, sendNotifications:false)
		}

		// Since Lightroom CC does not have and change notification mechanism yet, we need to poll for changes.
		// Whenever the app is brought to the foreground (activated), we just assume that a change was made in
		// Lightroom in the meantime. Perform necessary checks and reload this container if necessary.
		
//		self.registerDidActivateHandler
//		{
//			[weak self] in self?.reloadIfNeeded()
//		}
	}

	static func identifier(for asset:LightroomCC.Asset) -> String
	{
		"LightroomCC:Asset:\(asset.id)"
	}


//----------------------------------------------------------------------------------------------------------------------


	/// Downloads the thumbnail image for the specified Lightroom asset

	open class func loadThumbnail(for identifier:String, data:Any) async throws -> CGImage
	{
		try await Tasks.canContinue()
		
		guard let asset = data as? LightroomCC.Asset else { throw Error.loadThumbnailFailed }

		let catalogID = LightroomCC.shared.catalogID
		let assetID = asset.id
		let image = try await LightroomCC.shared.image(from:"https://lr.adobe.io/v2/catalogs/\(catalogID)/assets/\(assetID)/renditions/thumbnail2x")
		return image
	}


//----------------------------------------------------------------------------------------------------------------------


	// To be overridden in subclasses

	open class func loadMetadata(for identifier:String, data:Any) async throws -> [String:Any]
	{
		return [:]
	}

	@MainActor override open var localizedMetadata:[ObjectMetadataEntry]
    {
		return []
    }
    
    
//----------------------------------------------------------------------------------------------------------------------


	// Since Lightroom CC does not have and change notification mechanism yet, we need to poll for changes.
	// Whenever the app is brought to the foreground (activated), we just assume that a change was made in
	// Lightroom in the meantime. Perform necessary checks and reload this container if necessary.

	private func reloadIfNeeded()
	{
		guard let oldAsset = data as? LightroomCC.Asset else { return }
		
		Task
		{
			guard await self.thumbnailImage != nil else { return }
			
			let catalogID = LightroomCC.shared.catalogID
			let assetID = oldAsset.id
			let accessPoint = "https://lr.adobe.io/v2/catalogs/\(catalogID)/assets/\(assetID)"
			let newAsset:LightroomCC.Asset = try await LightroomCC.shared.getData(from:accessPoint, debugLogging:false)
			let needsReloading = newAsset.updated > oldAsset.updated

			LightroomCC.log.debug {"\(Self.self).\(#function)   oldUpdated = \(oldAsset.updated)    newUpdated = \(newAsset.updated)    needsReloading = \(needsReloading)"}

			if needsReloading
			{
				await MainActor.run
				{
					LightroomCC.log.debug {"\(Self.self).\(#function)"}
					self.data = newAsset
					self.purge()
					self.load()
				}
			}
		}
	}


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Downloading
	
	
	// Returns the filename of the file that will be downloaded

	override public var localFileName:String
	{
		Self.localFileName(for:identifier, data:data)
	}

	class func localFileName(for identifier:String, data:Any) -> String
	{
		"\(identifier).jpg"
	}

	// LightroomCC always returns JPEG files

	override public var localFileUTI:String
	{
		kUTTypeJPEG as String
	}

	// To be overridden in subclasses

	open class func downloadFile(for identifier:String, data:Any) async throws -> URL
	{
		throw Error.downloadFileFailed
	}

	// Shows an indeterminate progress bar
		
	open class func showProgress()
	{
		DispatchQueue.main.async
		{
			#if os(macOS)
			
			if !BXProgressWindowController.shared.isVisible
			{
				BXProgressWindowController.shared.title = NSLocalizedString("Importing Media Files", bundle:.BXMediaBrowser, comment:"Progress Title")
				BXProgressWindowController.shared.message = NSLocalizedString("Downloading", bundle:.BXMediaBrowser, comment:"Progress Title")
				BXProgressWindowController.shared.value = 0.0
				BXProgressWindowController.shared.isIndeterminate = true
				BXProgressWindowController.shared.show()
			}
			
			#else
			
			#warning("TODO: implement for iOS")
			
			#endif
		}
	}
	
	
//----------------------------------------------------------------------------------------------------------------------


	// MARK: - QuickLook
	

	/// Returns the filename of the local preview file
	
	public var previewFilename:String
    {
		let filename = Self.localFileName(for:identifier, data:data)
		let ext = filename.pathExtension
		return filename.replacingOccurrences(of:".\(ext)", with:".preview.\(ext.lowercased())")
	}
	
	/// Returns the title for the QuickLook panel
	
	override open var previewItemTitle: String!
    {
		self.localFileName
    }
	
	/// Returns the API accessPoint for downloading the preview file
	
	public var previewAccessPoint:String
	{
		guard let asset = data as? LightroomCC.Asset else { return "" }
		let catalogID = LightroomCC.shared.catalogID
		let assetID = asset.id
		return "https://lr.adobe.io/v2/catalogs/\(catalogID)/assets/\(assetID)/renditions/360p"
	}

	/// Returns the local file URL to the preview file. If not available yet, it will be downloaded from
	/// the Lightroom server.
	
	override public var previewItemURL:URL!
    {
		if self._previewItemURL == nil && !isDownloadingPreview
		{
			self.isDownloadingPreview = true
			
			Task
			{
				// Download the preview file
				
				let downloadAPI = self.previewAccessPoint
				let request = try LightroomCC.shared.request(for:downloadAPI, httpMethod:"GET")
				let tmpURL = try await URLSession.shared.downloadFile(with:request)
				
				// Rename the file
				
				let folderURL = tmpURL.deletingLastPathComponent()
				let filename = self.previewFilename
				let localURL = folderURL.appendingPathComponent(filename)
				try? FileManager.default.removeItem(at:localURL)
				try? FileManager.default.moveItem(at:tmpURL, to:localURL)
				
				// Store it in the TempFilePool and update the QLPreviewPanel
				
				await MainActor.run
				{
					TempFilePool.shared.register(localURL)
					self._previewItemURL = localURL
					
					#if os(macOS)
					if QLPreviewPanel.shared().isVisible
					{
						QLPreviewPanel.shared().refreshCurrentPreviewItem()
						QLPreviewPanel.shared().reloadData()
					}
					#endif
				}
			}
 		}
 		
 		return self._previewItemURL
	}

	private var _previewItemURL:URL? = nil
	private var isDownloadingPreview = false
}


//----------------------------------------------------------------------------------------------------------------------
