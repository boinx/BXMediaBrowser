

import Foundation


public struct UnsplashSearchResults : Codable
{
	public let total:Int
	public let total_pages:Int
	public let results:[UnsplashPhoto]
}
