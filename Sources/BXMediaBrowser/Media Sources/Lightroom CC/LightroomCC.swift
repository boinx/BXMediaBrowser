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
import OAuth2


//----------------------------------------------------------------------------------------------------------------------


public class LightroomCC : ObservableObject
{
	public static let shared = LightroomCC()
	
    private init()
    {
    }
    

//----------------------------------------------------------------------------------------------------------------------


    /// Your application clientID that was registered at developer.adobe.com
	
    public var clientID = ""
    
    /// Your application clientSecret that was registered at developer.adobe.com
	
	public var clientSecret = ""
	
	/// The redirectURI that was registered at developer.adobe.com
	
	public var redirectURI = ""

    /// The API for checking Lighroom server health
	
    let healthCheckAPI = "https://lr.adobe.io/v2/health"


//----------------------------------------------------------------------------------------------------------------------


    /// This object handles the OAuth login and holds accessToken/refreshToken
	
	public var oauth2:OAuth2CodeGrant
	{
		if let oauth2 = _oauth2 { return oauth2 }
		
		let settings:OAuth2JSON =
		[
			"client_id": clientID,
			"client_secret": clientSecret,
			"authorize_uri": "https://ims-na1.adobelogin.com/ims/authorize/v2",
			"token_uri": "https://ims-na1.adobelogin.com/ims/token/v3",
			"redirect_uris": [redirectURI],
			"scope": "openid, AdobeID, lr_partner_apis, lr_partner_rendition_apis, offline_access",
		]
		
		let oauth2 = OAuth2CodeGrant(settings:settings)
		oauth2.logger = OAuth2DebugLogger(.debug)
		self._oauth2 = oauth2
		
		return oauth2
	}
	
	private var _oauth2:OAuth2CodeGrant? = nil
	
	
//----------------------------------------------------------------------------------------------------------------------


	public enum Status : Equatable
	{
		case unknown
		case invalidClientID
		case currentlyUnavailable
		case loggedOut
		case loggedIn
	}
	
	
	public func isOAuthResponse(_ url:URL) -> Bool
	{
		url.absoluteString.contains(redirectURI)
	}


	public func handleOAuthResponse(_ url:URL)
	{
		LightroomCC.log.verbose {"\(Self.self).\(#function)"}
		self.oauth2.handleRedirectURL(url)
	}
	
	
//----------------------------------------------------------------------------------------------------------------------


	/// Strips the "while (1) {}" prefix from the returned JSON
	
	public static func stripped(_ data:Data) -> Data?
	{
		guard let string = String(data:data, encoding:.utf8) else { return nil }
		
		let stripped = string
			.replacingOccurrences(of:"while (1) {}", with:"")
			.trimmingCharacters(in:.whitespacesAndNewlines)
			
		return stripped.data(using:.utf8)
	}


//----------------------------------------------------------------------------------------------------------------------


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
