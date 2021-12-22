//
//  MediaBrowserView.swift
//  MediaBrowserTest
//
//  Created by Peter Baumgartner on 04.12.21.
//

import SwiftUI


//----------------------------------------------------------------------------------------------------------------------


//protocol SwiftUIFactoryDelegate
//{
//	@ViewBuilder func view(for library:Library) -> View
//	@ViewBuilder func view(for section:Section) -> View
//	@ViewBuilder func view(for source:Source) -> View
//	@ViewBuilder func view(for container:Container) -> View
//	@ViewBuilder func view(for object:Object) -> View
//}


//protocol GenericFactory
//{
//    associatedtype Input
//    associatedtype Output
//    func build(input:Input) -> Output
//}

//----------------------------------------------------------------------------------------------------------------------


public class ViewFactory
{
	public static let shared = ViewFactory()
	
//	private var types:[String:Any] = [:]
	private var factories:[String:Any] = [:]
	

//----------------------------------------------------------------------------------------------------------------------


	private init()
	{
		self.addDefaultFactories()
	}
	

	private func addDefaultFactories()
	{
		self.addViewFactory(forModelType:Library.self)
		{
			LibraryView(library:$0)
		}

		self.addViewFactory(forModelType:Section.self)
		{
			SectionView(section:$0)
		}

		self.addViewFactory(forModelType:Source.self)
		{
			SourceView(source:$0)
		}

		self.addViewFactory(forModelType:FolderSource.self)
		{
			FolderSourceView(source:$0)
		}

		self.addViewFactory(forModelType:Container.self)
		{
			ContainerView(container:$0)
		}

		self.addViewFactory(forModelType:Object.self)
		{
			ObjectCell(object:$0, isSelected:false)
		}
	}
	
	
//----------------------------------------------------------------------------------------------------------------------


	public func addViewFactory<T,M,V:View>(forModelType type:T, _ factory:@escaping (M)->V)
	{
		let key = "\(type)"
//		self.types[key] = V.self
		self.factories[key] = factory
	}
	
	
	public func build<M,V:View>(with model:M) -> some View
	{
		let key = "\(type(of:model).self)"
//		let viewType = types[key]
		let factory = factories[key] as! (M)->V
		let view = factory(model)
		return view
	}


//----------------------------------------------------------------------------------------------------------------------


//	@ViewBuilder func view(for library:Library) -> some View
//	{
//		LibraryView(library:library)
//	}
//
//	@ViewBuilder func view(for section:Section) -> some View
//	{
//		SectionView(section:section)
//	}
//
//	@ViewBuilder func view(for source:Source) -> some View
//	{
//		if source is FolderSource
//		{
//			FolderSourceView(source:source)
//		}
//		else
//		{
//			SourceView(source:source)
//		}
//	}
//
//	@ViewBuilder func view(for container:Container) -> some View
//	{
//		ContainerView(container:container)
//	}
//
//	@ViewBuilder func view(for object:Object) -> some View
//	{
//		ObjectCell(object:object, isSelected:false)
//	}
}


//----------------------------------------------------------------------------------------------------------------------


