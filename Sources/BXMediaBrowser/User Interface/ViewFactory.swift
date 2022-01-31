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


/// Injects a ViewFactory into the environment

public extension EnvironmentValues
{
    var viewFactory:ViewFactoryAPI
    {
        set { self[ViewFactoryKey.self] = newValue }
        get { self[ViewFactoryKey.self] }
    }
}

/// If no ViewFactory was injected into the environment, the default ViewFactory will be used instead

struct ViewFactoryKey : EnvironmentKey
{
    static let defaultValue:ViewFactoryAPI = ViewFactory()
}


//----------------------------------------------------------------------------------------------------------------------


/// The ViewFactory protocol defines the API for creating views for the BXMediaBrowser UI. By providing
/// a custom implementation and injecting it into the environment, the BXMediaBrowser can be customized.

public protocol ViewFactoryAPI
{
	/// Returns the View for the specifed model object

	func libraryView(for library:Library) -> AnyView

	/// Returns the View for the specifed model object

	func sectionView(for section:Section) -> AnyView

	/// Returns the View for the specifed model object

	func sourceView(for source:Source) -> AnyView

	/// Returns the View for the specifed model object

	func containerView(for container:Container) -> AnyView

	/// Returns a header view that is appropriate for the currently selected Container of the Library

	func objectsHeaderView(for library:Library) -> AnyView

	/// Returns a footer view that is appropriate for the currently selected Container of the Library

	func objectsFooterView(for library:Library) -> AnyView

	/// Provides context menu items for the specified model instance

	func containerContextMenu(for container:Container) -> AnyView

	/// Returns the type of ObjectCell subclass to be used for the specified Container

	func objectCellType(for container:Container?) -> ObjectCell.Type
}


//----------------------------------------------------------------------------------------------------------------------


open class ViewFactory : ViewFactoryAPI
{
	public init() { }

	open func libraryView(for library:Library) -> AnyView
	{
		typeErase( Self.defaultLibraryView(for:library) )
	}
	
	open func sectionView(for section:Section) -> AnyView
	{
		typeErase( Self.defaultSectionView(for:section) )
	}
	
	open func sourceView(for source:Source) -> AnyView
	{
		typeErase( Self.defaultSourceView(for:source) )
	}
	
	open func containerView(for container:Container) -> AnyView
	{
		typeErase( Self.defaultContainerView(for:container) )
	}
	
	open func objectsHeaderView(for library:Library) -> AnyView
	{
		typeErase( Self.defaultHeaderView(for:library) )
	}

	open func objectsFooterView(for library:Library) -> AnyView
	{
		typeErase( Self.defaultFooterView(for:library) )
	}

	open func containerContextMenu(for container:Container) -> AnyView
	{
		typeErase( Self.defaultContainerContextMenu(for:container) )
	}

	open func objectCellType(for container:Container?) -> ObjectCell.Type
	{
		Self.defaultObjectCellType(for:container)
	}
}


//----------------------------------------------------------------------------------------------------------------------


public extension ViewFactory
{
	func typeErase<V:View>(_ content:V) -> AnyView
	{
		AnyView(Group
		{
			content
		})
	}
	
	
	@ViewBuilder class func defaultLibraryView(for library:Library) -> some View
	{
		LibraryView(with:library)
	}


	@ViewBuilder class func defaultSectionView(for section:Section) -> some View
	{
		SectionView(with:section)
	}


	@ViewBuilder class func defaultSourceView(for source:Source) -> some View
	{
		if source is FolderSource
		{
			FolderSourceView(with:source)
		}
		else
		{
			SourceView(with:source)
		}
	}


	@ViewBuilder class func defaultContainerView(for container:Container) -> some View
	{
		if container is FolderContainer
		{
			FolderContainerView(with:container)
		}
		else
		{
			ContainerView(with:container)
		}
	}


	@ViewBuilder class func defaultHeaderView(for library:Library) -> some View
	{
		if let container = library.selectedContainer as? UnsplashContainer
		{
			UnsplashSearchBar(with:container)
		}
		else if let container = library.selectedContainer
		{
			SearchBar(with:container)
		}
		else
		{
			EmptyView()
		}
	}


	@ViewBuilder class func defaultFooterView(for library:Library) -> some View
	{
		if let container = library.selectedContainer
		{
			ObjectFooterView(library:library, container:container)
		}
		else
		{
			EmptyView()
		}
	}


	@ViewBuilder class func defaultContainerContextMenu(for container:Container) -> some View
	{
		if let folderContainer = container as? FolderContainer
		{
			Button("Reveal in Finder")
			{
				folderContainer.revealInFinder()
			}
		}
		
		Button("Reload")
		{
			container.load()
		}
			
		if let removeHandler = container.removeHandler
		{
			Button("Remove")
			{
				removeHandler(container)
			}
		}
	}


	class func defaultObjectCellType(for container:Container?) -> ObjectCell.Type
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
			else if container is MusicContainer
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
