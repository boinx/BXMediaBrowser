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


open class ViewFactory
{
	public static let shared = ViewFactory()
	
//	private var types:[String:Any] = [:]
//	private var factories:[String:Any] = [:]
	

//----------------------------------------------------------------------------------------------------------------------


	public required init()
	{
//		self.addDefaultFactories()
	}
	

//	private func addDefaultFactories()
//	{
//		self.addViewFactory(forModelType:Library.self)
//		{
//			AnyView(LibraryView(with:$0))
//		}
//
//		self.addViewFactory(forModelType:Section.self)
//		{
//			AnyView(SectionView(section:$0))
//		}
//
//		self.addViewFactory(forModelType:Source.self)
//		{
//			AnyView(SourceView(source:$0))
//		}
//
//		self.addViewFactory(forModelType:FolderSource.self)
//		{
//			AnyView(FolderSourceView(source:$0))
//		}
//
//		self.addViewFactory(forModelType:Container.self)
//		{
//			AnyView(ContainerView(container:$0))
//		}
//
//		self.addViewFactory(forModelType:Object.self)
//		{
//			AnyView(ObjectCell(object:$0, isSelected:false))
//		}
//	}
	
	
//----------------------------------------------------------------------------------------------------------------------


//	public func addViewFactory<T,M>(forModelType type:T, _ factory:@escaping (M)->AnyView)
//	{
//		let key = "\(type)"
////		self.types[key] = V.self
//		self.factories[key] = factory
//	}
//
//
//	public func build<M>(with model:M) -> AnyView
//	{
//		let key = "\(type(of:model).self)"
////		let viewType = types[key]
//		let factory = factories[key] as! (M)->AnyView
//		let view = factory(model)
//		return view
//	}


//----------------------------------------------------------------------------------------------------------------------


	@ViewBuilder func view(for model:Any) -> some View
	{
		if let library = model as? Library
		{
			LibraryView(with:library)
		}
		else if let section = model as? Section
		{
			SectionView(section:section)
		}
		else if let source = model as? FolderSource
		{
			FolderSourceView(source:source)
		}
		else if let source = model as? Source
		{
			SourceView(source:source)
		}
		else if let container = model as? Container
		{
			ContainerView(container:container)
		}
	}


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


