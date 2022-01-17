

public struct UnsplashFilter : Equatable
{
	enum Orientation : String,Equatable,CaseIterable
	{
		case any = ""
		case landscape
		case portrait
		case squarish
		
		static var allValues:[String]
		{
			self.allCases.map { $0.rawValue }
		}
	}
	
	enum Color : String,Equatable,CaseIterable
	{
		case any = ""
		case black_and_white
		case black
		case white
		case yellow
		case orange
		case red
		case purple
		case magenta
		case green
		case teal
		case blue

		static var allValues:[String]
		{
			self.allCases.map { $0.rawValue }
		}
	}
	
	var searchString:String = ""
	var orientation:Orientation? = nil
	var color:Color? = nil
}
