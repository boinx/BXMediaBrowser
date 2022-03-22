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


//----------------------------------------------------------------------------------------------------------------------


public class LightroomCC : ObservableObject
{
	public static let shared = LightroomCC()
	
    private init() { }
    

//----------------------------------------------------------------------------------------------------------------------


    /// Your application’s client ID
	
    public var clientID = ""

    /// The API for checking Lighroom server health
	
    let healthCheckAPI = "https://lr.adobe.io/v2/health"


//----------------------------------------------------------------------------------------------------------------------


	public enum Status : Equatable
	{
		case invalidClientID
		case currentlyUnavailable
		case loggedOut
		case loggedIn(user:String)
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
