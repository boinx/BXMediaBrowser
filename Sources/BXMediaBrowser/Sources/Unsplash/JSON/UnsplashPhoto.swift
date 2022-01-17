

import Foundation


public struct UnsplashPhoto : Codable
{
    public let id:String
    public let created_at:String?
    public let height:Int
    public let width:Int
    public let urls:[String:URL]
    public let description:String?
}
