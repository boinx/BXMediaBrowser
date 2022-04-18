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


// For (incomplete) documentation about the Adobe Lightroom REST API refer to:
//
//     https://developer.adobe.com/lightroom/lightroom-api-docs/api/
//
// Better (more complete) documentation is available at:
//
//     https://github.com/AdobeDocs/lightroom-partner-apis/blob/master/docs/api/LightroomPartnerAPIsSpec.json


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
//			"use_pkce": true, // only for native app flow
			"scope": "openid, AdobeID, lr_partner_apis, lr_partner_rendition_apis, offline_access",
		]
		
		self.oauth2 = OAuth2CodeGrant(settings:settings)
//		self.oauth2.authConfig.authorizeEmbedded = true
//		self.oauth2.authConfig.authorizeEmbeddedAutoDismiss = false
//		self.oauth2.authConfig.ui.useAuthenticationSession = true
//		self.oauth2.authConfig.ui.prefersEphemeralWebBrowserSession = true
//		self.oauth2.useProofKeyForCodeExchange = true // only for native app flow
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


	/// The current status
	
	@MainActor @Published public var status:LightroomCC.Status = .unknown
	{
		didSet
		{
			LightroomCC.log.debug {"\(Self.self).\(#function) = \(status)"}
		}
	}

	public enum Status : Equatable
	{
		case unknown
		case invalidClientID
		case currentlyUnavailable
		case loggedOut
		case loggedIn
	}
	
	/// The ID of the logged in user

	@Published public var userID:String = ""

	/// The name of the logged in user

	@Published public var userName:String? = nil

	/// The email of the logged in user

	@Published public var userEmail:String? = nil

	/// The ID of the current Lightroom catalog
	
	@Published public var catalogID:String = ""
	
	/// The cached list of all albums (loaded at launch time)
	
	@Published public var allAlbums:[LightroomCC.Albums.Resource] = []
	
	/// Error that moight occur when talking to the Lightroom server
	
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
	
	func getData<T:Codable>(from accessPoint:String?, requiresAccessToken:Bool = true, debugLogging:Bool = false) async throws -> T
	{
		LightroomCC.log.verbose {"\(Self.self).\(#function)"}

		// Build a search request with the provided search string (filter)
		
		guard let accessPoint = accessPoint else { throw Error.invalidURL }
		guard let urlComponents = URLComponents(string:accessPoint) else { throw Error.invalidURL }
		guard let url = urlComponents.url else { throw Error.invalidURL }

		var request = URLRequest(url:url)
		request.httpMethod = "GET"
		request.setValue(Self.clientID, forHTTPHeaderField:"X-API-Key")
		
		if requiresAccessToken
		{
			guard let accessToken = self.oauth2.accessToken else { throw Error.missingAccessToken }
			request.setValue("Bearer \(accessToken)", forHTTPHeaderField:"Authorization")
		}
		
		// Get the data and strip the prefix "while (1) {}" (13 bytes)
		
		let prefixedData = try await URLSession.shared.data(with:request)
		let data = prefixedData.subdata(in:13 ..< prefixedData.count)
		
		if debugLogging
		{
			let string = String(data:data, encoding:.utf8)
			let encoder = JSONEncoder()
			encoder.outputFormatting = .prettyPrinted
			let prettyData = try encoder.encode(string)
			var prettyJSON = String(data:prettyData, encoding:.utf8) ?? "nil"
			prettyJSON = prettyJSON.replacingOccurrences(of:"\\n", with:"\n")
			prettyJSON = prettyJSON.replacingOccurrences(of:"\\\"", with:"\"")
			Swift.print("\nURL = \(url)\nJSON = \(prettyJSON)\n")
		}
		
		// Decode returned JSON to specified type T
		
		let instance = try JSONDecoder().decode(T.self, from:data)
		return instance
	}
	
	
	/// Downloads an image from the specified API accessPoint
	
	func image(from accessPoint:String) async throws -> CGImage
	{
		LightroomCC.log.verbose {"\(Self.self).\(#function)"}

		let request = try self.request(for:accessPoint, httpMethod:"GET")
		let data = try await URLSession.shared.data(with:request)
		
		guard let source = CGImageSourceCreateWithData(data as CFData,nil) else { throw Error.loadImageFailed }
		guard let image = CGImageSourceCreateImageAtIndex(source,0,nil) else { throw Error.loadImageFailed }
		return image
	}
	
	
	/// Builds a URLRequest for the specified accessPoint. Default httpMethod is GET.
	
	func request(for accessPoint:String, httpMethod:String = "GET", requiresAccessToken:Bool = true) throws -> URLRequest
	{
		LightroomCC.log.verbose {"\(Self.self).\(#function)"}

		let urlComponents = URLComponents(string:accessPoint)!
		guard let url = urlComponents.url else { throw Error.invalidURL }

//		var request = URLRequest(url:url)
		var request = URLRequest(url:url, cachePolicy:.reloadIgnoringLocalAndRemoteCacheData)
		request.httpMethod = httpMethod
		request.setValue(Self.clientID, forHTTPHeaderField:"X-API-Key")
		
		if requiresAccessToken
		{
			guard let accessToken = self.oauth2.accessToken else { throw Error.missingAccessToken }
			request.setValue("Bearer \(accessToken)", forHTTPHeaderField:"Authorization")
		}
		
		return request
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
