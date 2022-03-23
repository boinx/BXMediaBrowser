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


extension LightroomCC
{
	/// The JSON returned by https://lr.adobe.io/v2/health

	public struct Health : Codable
	{
		public let version:String?
		public let code:Int?
		public let description:String?
	}


	/// The JSON returned by https://lr.adobe.io/v2/catalog

	public struct Catalog : Codable
	{
		public struct Payload : Codable
		{
			public let name:String
			public let parent:Parent?
		}

		public let id:String
		public let payload:Payload
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
			
			public let id:String
			public let type:String
			public let subtype:String
			public let payload:Payload
		}

		public let resources:[Resource]
	}
	
	
	/// The JSON returned by https://lr.adobe.io/v2/catalogs/catalog_id/albums/album_id/assets

	public struct AlbumAssets : Codable
	{
		public struct Resource : Codable
		{
			public let asset:Asset
		}
		
		public let resources:[Resource]
	}

	public struct Asset : Codable
	{
		public struct Payload : Codable
		{
			public struct ImportSource : Codable
			{
				public let fileName:String
				public let fileSize:Int
				public let originalWidth:Int
				public let originalHeight:Int
			}
			
			public let captureDate:String
			public let importSource:ImportSource
		}

		public let id:String
		public let subtype:String?
		public let payload:Payload?
		
		public var name:String { self.payload?.importSource.fileName ?? ""}
		public var fileSize:Int { self.payload?.importSource.fileSize ?? 0 }
		public var width:Int { self.payload?.importSource.originalWidth ?? 0 }
		public var height:Int { self.payload?.importSource.originalHeight ?? 0 }
	}
	
	
}


//----------------------------------------------------------------------------------------------------------------------


extension LightroomCC
{
	public struct Parent : Codable
	{
		public let id:String
	}
}


//----------------------------------------------------------------------------------------------------------------------


