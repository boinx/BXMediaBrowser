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


import Foundation


//----------------------------------------------------------------------------------------------------------------------


// For documentation about the following structs refer to https://developer.adobe.com/lightroom/lightroom-api-docs/api/

extension LightroomCC
{
	/// The JSON returned by https://lr.adobe.io/v2/health

	public struct Health : Codable
	{
		public let version:String?
		public let code:Int?
		public let description:String?
	}


	/// The JSON returned by https://lr.adobe.io/v2/account

	public struct Account : Codable
	{
		public let base:String?
		public let id:String
		public let email:String?
		public let full_name:String?
		public let first_name:String?
		public let last_name:String?
	}


	/// The JSON returned by https://lr.adobe.io/v2/catalog

	public struct Catalog : Codable
	{
		public struct Payload : Codable
		{
			public let name:String
			public let parent:Parent?
		}

		public let base:String?
		public let id:String
		public let payload:Payload
		public let links:Links?
	}


	/// The JSON returned by https://lr.adobe.io/v2/catalogs/catalog_id/albums

	public struct Albums : Codable
	{
		public struct Resource : Codable
		{
			public struct Payload : Codable
			{
				public let name:String
				public let parent:Parent?
			}
			
			public let base:String?
			public let id:String
			public let type:String
			public let subtype:String
			public let created:String
			public let updated:String
			public let payload:Payload
		}

		public let resources:[Resource]
		public let links:Links?
	}
	
	
	/// The JSON returned by https://lr.adobe.io/v2/catalogs/catalog_id/albums/album_id

	public struct Album : Codable
	{
		public struct Payload : Codable
		{
			public let userUpdated:String
			public let name:String
		}

		public let base:String?
		public let id:String
		public let type:String
		public let subtype:String
		public let created:String
		public let updated:String
		public let payload:Payload
	}
	
	
	/// The JSON returned by https://lr.adobe.io/v2/catalogs/catalog_id/albums/album_id/assets

	public struct AlbumAssets : Codable
	{
		public struct Resource : Codable
		{
			public struct Payload : Codable
			{
				public let order:String?
				public let key:String?
			}
			
			public let asset:Asset
			public let payload:Payload?
		}
		
		public let base:String?
		public let resources:[Resource]
		public let links:Links?
	}

	public struct Asset : Codable
	{
		public struct ImportSource : Codable
		{
			public let fileName:String
			public let fileSize:Int
			public let originalWidth:Int
			public let originalHeight:Int
			public let contentType:String?
		}
		
		public struct TIFF : Codable
		{
			public let Make:String?
			public let Model:String?
		}
		
		public struct EXIF : Codable
		{
			public let ApertureValue:[Int]?
			public let FNumber:[Int]?
			public let ExposureTime:[Int]?
			public let ISOSpeedRatings:Int?
			public let FocalLengthIn35mmFilm:Double?
		}
			
		public struct Rating : Codable
		{
			public let date:String?
			public let rating:Int?
		}
			
		public struct XMP : Codable
		{
			public let tiff:TIFF?
			public let exif:EXIF?
		}
		
		public struct Video : Codable
		{
			public let storageWidth:Int?
			public let storageHeight:Int?
			public let frameRate:[Int]?
			public let duration:[Int]?
			public let displayAspectRatio:[Int]?
			public let pixelAspectRatio:[Int]?
			
			public let videoCodec:String?
			public let videoBitrate:Int?
			public let bitDepth:Int?
			public let chromaSubsampling:String?
			public let colorMatrix:String?
			public let colorPrimaries:String?
			public let transferFunction:String?
			public let colorRange:String?
			public let fieldOrder:String?
			
			public let audioCodec:String?
			public let audioBitrate:Int?
			public let audioChannel:String?
			public let audioSampleRate:Int?
			public let audioSampleSize:Int?
		}
		
// "payload":{"video":{"frameRate":[60000,1001],"duration":[2503,500],"audioBitrate":192000,
// "audioChannel":"stereo","audioCodec":"AAC","audioSampleRate":48000,"audioSampleSize":16,"bitDepth":8,
// "chromaSubsampling":"4:2:0","colorMatrix":"bt709","colorPrimaries":"bt709","colorRange":"limited",
// "displayAspectRatio":[16,9],"fieldOrder":"progressive","pixelAspectRatio":[1,1],"storageHeight":2160,
// "storageWidth":3840,"transferFunction":"bt709","videoBitrate":99999744,"videoCodec":"AVC"}
		
		public struct Payload : Codable
		{
			public let captureDate:String
			public let importSource:ImportSource
			public let xmp:XMP?
			public let video:Video?
			public let ratings:[String:Rating]?
		}

		public let base:String?
		public let id:String
		public let subtype:String?
		public let updated:String
		public let payload:Payload?
		public let links:Links?
		
		public var name:String { self.payload?.importSource.fileName ?? ""}
		public var width:Int { self.payload?.importSource.originalWidth ?? 0 }
		public var height:Int { self.payload?.importSource.originalHeight ?? 0 }
		public var fileSize:Int { self.payload?.importSource.fileSize ?? 0 }
		public var captureDate:String? { self.payload?.captureDate }
		public var rating:Int? { self.payload?.ratings?.values.first?.rating }
	}


	/// The JSON returned by https://lr.adobe.io/v2/https://lr.adobe.io/v2/catalogs/catalog_id/assets

	public struct CatalogAssets : Codable
	{
		public let base:String?
		public let resources:[CatalogResource]
		public let links:Links?
		
		public struct CatalogResource : Codable
		{
			public let id:String
			public let type:String
			public let subtype:String
			public let updated:String
			public let payload:Asset.Payload
			public let links:Links?
		}
	}
}


//----------------------------------------------------------------------------------------------------------------------


extension LightroomCC
{
	public struct Parent : Codable
	{
		public let id:String
	}
	
	public struct Links : Codable
	{
		public struct Link : Codable
		{
			let href:String
			let invalid:Bool?
		}
		
		let prev:Link?
		let next:Link?
		let asset:Link?
		let master_create:Link?
		let xmp_develop_create:Link?
		let xmp_develop:Link?
		let rendition_type_thumbnail2x:Link?
		let rendition_type_1280:Link?
		let rendition_type_2048:Link?
		let rendition_type_fullsize:Link?
		
		enum CodingKeys: String, CodingKey
		{
			case prev = "prev"
			case next = "next"
			case asset = "/rels/asset"
			case master_create = "/rels/master_create"
			case xmp_develop_create = "/rels/xmp_develop_create"
			case xmp_develop = "/rels/xmp/develop"
			case rendition_type_thumbnail2x = "/rels/rendition_type/thumbnail2x"
			case rendition_type_1280 = "/rels/rendition_type/1280"
			case rendition_type_2048 = "/rels/rendition_type/2048"
			case rendition_type_fullsize = "/rels/rendition_type/fullsize"
		}
	}
}


//----------------------------------------------------------------------------------------------------------------------


