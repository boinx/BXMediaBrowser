

import Foundation
import Combine


public class UnsplashConfig : ObservableObject
{
	public static let shared = UnsplashConfig()
	
    private init() { }
    
    
    /// Your application’s access key
	
    public var accessKey = ""

    /// Your application’s secret key
	
    public var secretKey = ""

    /// The Unsplash API url
	
    let apiURL = "https://api.unsplash.com/"
}
