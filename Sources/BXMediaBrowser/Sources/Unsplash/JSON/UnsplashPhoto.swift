

import Foundation


public struct UnsplashPhoto : Codable
{
	// Metadata about a photo
	
    public let id:String
    public let created_at:String?
    public let height:Int
    public let width:Int
    public let urls:[String:URL]
    public let description:String?
	public let public_domain:Bool?
	public let user:UnsplashUser
	
	private enum CodingKeys : String,CodingKey
    {
        case id
        case created_at
        case height
        case width
        case urls
        case description
        case public_domain
        case user
    }

    // Not included in Codable
    
    public var progress = Progress(totalUnitCount:1)
}
