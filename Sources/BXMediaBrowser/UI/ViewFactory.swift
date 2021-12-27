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


import SwiftUI


//----------------------------------------------------------------------------------------------------------------------


open class ViewFactory
{
	/// The shared singleton instance of this ViewFactory
	
	private static let _shared = ViewFactory()

	/// This is the public accessor for the shared singleton instance. If you want to subclass ViewFactory
	/// to extend the view(for:) methods, you should also override this accessor to return an instance of
	/// your subclass instead.
	
	public static var shared:ViewFactory { _shared }


//----------------------------------------------------------------------------------------------------------------------


	@ViewBuilder func hierarchyView(for model:Any) -> some View
	{
		if let container = model as? Container
		{
			ContainerView(container:container)
		}
		else if let source = model as? FolderSource
		{
			FolderSourceView(source:source)
		}
		else if let source = model as? Source
		{
			SourceView(source:source)
		}
		else if let section = model as? Section
		{
			SectionView(section:section)
		}
		else if let library = model as? Library
		{
			LibraryView(with:library)
		}
	}


//----------------------------------------------------------------------------------------------------------------------


	@ViewBuilder func objectView(for model:Any, isSelected:Bool) -> some View
	{
		if let object = model as? Object
		{
			ObjectCell(object:object, isSelected:isSelected)
		}
	}


}

//----------------------------------------------------------------------------------------------------------------------


