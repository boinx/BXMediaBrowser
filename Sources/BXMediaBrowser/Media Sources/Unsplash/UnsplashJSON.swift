import Foundation

#if os(macOS)
import AppKit
#else
import UIKit
#endif


//----------------------------------------------------------------------------------------------------------------------


public struct UnsplashSearchResults : Codable
{
	public let total:Int
	public let total_pages:Int
	public let results:[UnsplashPhoto]
}


//----------------------------------------------------------------------------------------------------------------------


public struct UnsplashPhoto : Codable
{
    public let id:String
    public let created_at:String?
    public let height:Int
    public let width:Int
    public let urls:[String:URL]
    public let description:String?
	public let public_domain:Bool?
	public let user:UnsplashUser
	public let links:UnsplashLinks
	public let exif:UnsplashExif?
    public let location:UnsplashLocation?
}


//----------------------------------------------------------------------------------------------------------------------


public struct UnsplashUser: Codable
{
    public let id:String
    public let username: String
 	public let name: String?
	public let first_name: String?
    public let last_name: String?
    public let portfolio_url: URL?
    public let location: String?
}

extension UnsplashUser
{
    var displayName: String
    {
        if let name = name
        {
            return name
        }

        if let first_name = first_name
        {
            if let last_name = last_name
            {
                return "\(first_name) \(last_name)"
            }
            
            return first_name
        }

        return username
    }

    var profileURL: URL?
    {
        return URL(string: "https://unsplash.com/@\(username)")
    }
    
    func openProfileURL()
	{
		self.profileURL?.open()
	}

    func openPortfolioURL()
	{
		self.portfolio_url?.open()
	}
}


//----------------------------------------------------------------------------------------------------------------------


public struct UnsplashLinks: Codable
{
	public let `self`: String?
	public let html: String?
	public let photos: String?
	public let likes: String?
	public let portfolio: String?
	public let download: String?
	public let download_location: String?
}


//----------------------------------------------------------------------------------------------------------------------


public struct UnsplashExif : Codable
{
    public let aperture:Double
    public let exposure_time:Double
    public let focal_length:Int
    public let iso:Int
    public let make:String
    public let model:String
}


//----------------------------------------------------------------------------------------------------------------------


public struct UnsplashLocation : Codable
{
    public let city:String?
    public let country:String?
    public let position:UnsplashPosition?
}


//----------------------------------------------------------------------------------------------------------------------


public struct UnsplashPosition : Codable
{
    public let latitude:Double
    public let longitude:Double
}


//----------------------------------------------------------------------------------------------------------------------


