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

	func objectsHeaderView(for library:Library, container:Container?) -> AnyView

	/// Returns a footer view that is appropriate for the currently selected Container of the Library

	func objectsFooterView(for library:Library, container:Container?) -> AnyView

	/// Provides context menu items for the specified model instance

	func containerContextMenu(for container:Container) -> AnyView

	/// Returns the type of ObjectViewController subclass to be used for the specified Container

	func objectViewControllerType(for container:Container?) -> ObjectViewController.Type
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
	
	open func objectsHeaderView(for library:Library, container:Container?) -> AnyView
	{
		typeErase( Self.defaultHeaderView(for:library, container:container) )
	}

	open func objectsFooterView(for library:Library, container:Container?) -> AnyView
	{
		typeErase( Self.defaultFooterView(for:library, container:container) )
	}

	open func containerContextMenu(for container:Container) -> AnyView
	{
		typeErase( Self.defaultContainerContextMenu(for:container) )
	}

	open func objectViewControllerType(for container:Container?) -> ObjectViewController.Type
	{
		Self.defaultObjectViewControllerType(for:container)
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
		if let source = source as? LightroomCCSource
		{
			LightroomCCSourceView(with:source,LightroomCC.shared)
		}
		else if source is FolderSource
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


	@ViewBuilder class func defaultHeaderView(for library:Library, container:Container?) -> some View
	{
		if let container = container as? UnsplashContainer, let filter = container.filter as? UnsplashFilter
		{
			UnsplashFilterBar(with:container, filter:filter)
		}
		else if let container = container as? PexelsPhotoContainer, let filter = container.filter as? PexelsFilter
		{
			PexelsFilterBar(with:container, filter:filter)
		}
		else if let container = container as? PexelsVideoContainer, let filter = container.filter as? PexelsFilter
		{
			PexelsFilterBar(with:container, filter:filter)
		}
		else if let container = container as? LightroomCCContainer, let filter = container.filter as? LightroomCCFilter
		{
			LightroomCCFilterBar(with:container, filter:filter)
		}
		else if let container = container as? MusicContainer, let filter = container.filter as? MusicFilter
		{
			MusicFilterBar(with:container, filter:filter)
		}
		else if let container = container as? FolderContainer, let filter = container.filter as? FolderFilter
		{
			FolderFilterBar(with:container, filter:filter)
		}
		else if let container = container
		{
			SearchBar(with:container)
		}
		else
		{
			EmptyView()
		}
	}


	@ViewBuilder class func defaultFooterView(for library:Library, container:Container?) -> some View
	{
		if let container = container as? AudioFolderContainer
		{
			AudioObjectFooterView(container:container)
		}
		else if let container = container as? MusicContainer
		{
			AudioObjectFooterView(container:container)
		}
		else if let container = container
		{
			DefaultObjectFooterView(container:container, uiState:library.uiState)
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
			Button(NSLocalizedString("Reveal in Finder", bundle:.BXMediaBrowser, comment:"Menu Item"))
			{
				folderContainer.revealInFinder()
			}
		}
		
		Button(NSLocalizedString("Reload", bundle:.BXMediaBrowser, comment:"Menu Item"))
		{
			container.load()
		}
			
		if let removeHandler = container.removeHandler
		{
			Button(NSLocalizedString("Remove", bundle:.BXMediaBrowser, comment:"Menu Item"))
			{
				removeHandler(container)
			}
		}
	}


	class func defaultObjectViewControllerType(for container:Container?) -> ObjectViewController.Type
	{
		// For some Container types we want custom ObjectViewControllers
		
		if let container = container
		{
			if container is AudioFolderContainer
			{
				return AudioObjectViewController.self
			}
			else if container is MusicContainer
			{
				return AudioObjectViewController.self
			}
//			else if container is VideoFolderContainer
//			{
//				return VideoObjectViewController.self
//			}
//			else if container is PhotosContainer
//			{
//				return ImageObjectViewController.self
//			}
		}
		
		// Default is a ImageObjectViewController
		
		return ImageObjectViewController.self
	}
}


//----------------------------------------------------------------------------------------------------------------------
