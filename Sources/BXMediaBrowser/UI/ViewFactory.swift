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


/// The ViewFactory protocol defines the API for creating views for the BXMediaBrowser UI. By providing
/// a custom implementation and injecting it into the environment, the BXMediaBrowser can be customized.

public protocol ViewFactory
{
	/// Returns the View for the specifed model object
	
	func build(with model:Any) -> AnyView
}


//----------------------------------------------------------------------------------------------------------------------


public struct DefaultViewFactory : ViewFactory
{
	// Create the View and wrap it in a type-erased AnyView
	
	public func build(with model:Any) -> AnyView
	{
		let view = Self.defaultView(for:model)
		return AnyView(view)
	}


	/// This function creates the built-in default Views for the BXMediaBrowser UI
	
	@ViewBuilder static public func defaultView(for model:Any) -> some View
	{
		if let container = model as? Container
		{
			ContainerView(with:container)
		}
		else if let source = model as? FolderSource
		{
			FolderSourceView(with:source)
		}
		else if let source = model as? Source
		{
			SourceView(with:source)
		}
		else if let section = model as? Section
		{
			SectionView(with:section)
		}
		else if let library = model as? Library
		{
			LibraryView(with:library)
		}
	}
	
	/// Returns the type of ObjectCell subclass to be used for the specified Container
	
	static public func objectCellType(for container:Container?) -> ObjectCell.Type
	{
		// For some Container subclasses we want custom ObjectCells
		
		if let container = container
		{
			if container is VideoFolderContainer
			{
	//			return ImageThumbnailCell.self
			}
			else if container is AudioFolderContainer
			{
				return AudioCell.self
			}
			else if container is PhotosContainer
			{
	//			return ImageThumbnailCell.self
			}
		}
		
		// Default is a ImageThumbnailCell
		
		return ImageThumbnailCell.self
	}
}


//----------------------------------------------------------------------------------------------------------------------


/// Injects a ViewFactory into the environment

public extension EnvironmentValues
{
    var viewFactory:ViewFactory
    {
        set { self[ViewFactoryKey.self] = newValue }
        get { self[ViewFactoryKey.self] }
    }
}

/// If no ViewFactory was injected into the environment, the DefaultViewFactory will be used instead

struct ViewFactoryKey : EnvironmentKey
{
    static let defaultValue:ViewFactory = DefaultViewFactory()
}


//----------------------------------------------------------------------------------------------------------------------
