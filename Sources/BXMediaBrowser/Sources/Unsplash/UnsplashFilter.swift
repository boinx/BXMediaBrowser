

public struct UnsplashFilter : Equatable
{
	enum Orientation : String,Equatable
	{
		case landscape
		case portrait
		case squarish
	}
	
	enum Color : String,Equatable
	{
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
	}
	
	var searchString:String = ""
	var orientation:Orientation? = nil
	var color:Color? = nil
}
