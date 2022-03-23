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
import Foundation
import ImageIO
import OAuth2


//----------------------------------------------------------------------------------------------------------------------


public class LightroomCC : ObservableObject
{
	public static let shared = LightroomCC()
	
    private init()
    {
		let settings:OAuth2JSON =
		[
			"client_id": Self.clientID,
			"client_secret": Self.clientSecret,
			"authorize_uri": "https://ims-na1.adobelogin.com/ims/authorize/v2",
			"token_uri": "https://ims-na1.adobelogin.com/ims/token/v3",
			"redirect_uris": [Self.redirectURI],
			"scope": "openid, AdobeID, lr_partner_apis, lr_partner_rendition_apis, offline_access",
		]
		
		self.oauth2 = OAuth2CodeGrant(settings:settings)
		self.oauth2.logger = OAuth2DebugLogger(.debug)
    }
    

//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Config
	
    /// Your application clientID that was registered at developer.adobe.com
	
    public static var clientID = ""
    
    /// Your application clientSecret that was registered at developer.adobe.com
	
	public static var clientSecret = ""
	
	/// The redirectURI that was registered at developer.adobe.com
	
	public static var redirectURI = ""


//----------------------------------------------------------------------------------------------------------------------


 	// MARK: - OAuth Login
	
	
	/// Returns true if there is an unexpired accessToken
	
	public var isLoggedIn:Bool
	{
		oauth2.hasUnexpiredAccessToken()
	}
	
	
	/// Returns true if the specified URL is for the Adobe Lightroom OAuth login
	
	public func isOAuthResponse(_ url:URL) -> Bool
	{
		url.absoluteString.contains(Self.redirectURI)
	}

	
	/// Handles the second step in the Adobe Lightroom OAuth login
	
	public func handleOAuthResponse(_ url:URL)
	{
		LightroomCC.log.verbose {"\(Self.self).\(#function)"}
		self.oauth2.handleRedirectURL(url)
	}


   /// This object handles the OAuth login and holds the accessToken/refreshToken
	
	public let oauth2:OAuth2CodeGrant
	
	
//----------------------------------------------------------------------------------------------------------------------


	/// The ID of the current Lightroom catalog
	
	@Published public var catalogID:String = ""
	
	/// The cached list of all albums (loaded at launch time)
	
	@Published public var allAlbums:[LightroomCC.Albums.Resource] = []
	
	
	public enum Status : Equatable
	{
		case unknown
		case invalidClientID
		case currentlyUnavailable
		case loggedOut
		case loggedIn
	}
	
	public enum Error : Swift.Error
	{
		case invalidURL
		case missingAccessToken
		case corruptData
		case loadImageFailed
	}
	
//----------------------------------------------------------------------------------------------------------------------


 	// MARK: - Data Transfer
	
	/// This re-usable function gets data of generic type T from the specified API accessPoint
	
	func getData<T:Codable>(from accessPoint:String, requiresAccessToken:Bool = true) async throws -> T
	{
		LightroomCC.log.verbose {"\(Self.self).\(#function)"}

		// Build a search request with the provided search string (filter)
		
		let urlComponents = URLComponents(string:accessPoint)!
		guard let url = urlComponents.url else { throw Error.invalidURL }

		var request = URLRequest(url:url)
		request.httpMethod = "GET"
		request.setValue(Self.clientID, forHTTPHeaderField:"X-API-Key")
		
		if requiresAccessToken
		{
			guard let accessToken = self.oauth2.accessToken else { throw Error.missingAccessToken }
			request.setValue("Bearer \(accessToken)", forHTTPHeaderField:"Authorization")
		}
		
		// Get the data and strip the prefix
		
		let prefixedData = try await URLSession.shared.data(with:request)
		guard let strippedData = LightroomCC.stripped(prefixedData) else { throw Error.corruptData }
		
//		if let string = Self.string(with:strippedData)
//		{
//			print(string)
//		}
		
		// Decode returned JSON to specified type T
		
		let instance = try JSONDecoder().decode(T.self, from:strippedData)
		return instance
	}
	
	
	/// Strips the "while (1) {}" prefix from the returned JSON
	
	public static func stripped(_ data:Data) -> Data?
	{
		data.subdata(in:12..<data.count)

//		guard let string = string(with:data) else { return nil }
//
//		let stripped = string
//			.replacingOccurrences(of:"while (1) {}", with:"")
//			.trimmingCharacters(in:.whitespacesAndNewlines)
//
//		return stripped.data(using:.utf8)
	}
	
	static func string(with data:Data) -> String?
	{
		String(data:data, encoding:.utf8)
	}


	/// Downloads an image from the specified API accessPoint
	
	func image(from accessPoint:String) async throws -> CGImage
	{
		LightroomCC.log.verbose {"\(Self.self).\(#function)"}

		// Build a search request with the provided search string (filter)
		
		let urlComponents = URLComponents(string:accessPoint)!
		guard let url = urlComponents.url else { throw Error.invalidURL }
		guard let accessToken = self.oauth2.accessToken else { throw Error.missingAccessToken }

		var request = URLRequest(url:url)
		request.httpMethod = "GET"
		request.setValue(Self.clientID, forHTTPHeaderField:"X-API-Key")
		request.setValue("Bearer \(accessToken)", forHTTPHeaderField:"Authorization")
		
		// Get the data and strip the prefix
		
		let data = try await URLSession.shared.data(with:request)
		guard let source = CGImageSourceCreateWithData(data as CFData,nil) else { throw Error.loadImageFailed }
		guard let image = CGImageSourceCreateImageAtIndex(source,0,nil) else { throw Error.loadImageFailed }
		return image
	}
	
	
//----------------------------------------------------------------------------------------------------------------------


 	// MARK: - Debugging
	
	/// A logger for Lightroom related code

	public static var log:BXLogger =
	{
		()->BXLogger in
		
		var logger = BXLogger()

		logger.addDestination
		{
			(level:BXLogger.Level,string:String)->() in
			BXMediaBrowser.log.print(level:level, force:true) { string }
		}
		
		return logger
	}()
	
	
}


//----------------------------------------------------------------------------------------------------------------------
