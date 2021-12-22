//
//  Container+Loader.swift
//  MediaBrowserTest
//  Created by Peter Baumgartner on 04.12.21.
//


import Foundation


//----------------------------------------------------------------------------------------------------------------------


extension Container
{
	public actor Loader
	{
		/// The identifier specifies the location of a Container
		
		public let identifier:String
		
		/// This can be any lkind of info that subclasses need to their job.
		
		public let info:Any
	
		/// The loadHandler is an externally provided closure that returns the Contents for this Container
		
		public let loadHandler:LoadHandler
	
		/// A Container has an array of (sub) Containers and an array of Objects
		
		public typealias Contents = ([Container],[Object])
		
		/// The LoadHandler is a pure function closure that returns the Contents of a Container
		
		public typealias LoadHandler = (String,Any) async throws -> Contents

		/// Creates a new Container with an externally supplied closure to load the contents
		
		public init(identifier:String, info:Any, loadHandler:@escaping LoadHandler)
		{
			self.identifier = identifier
			self.info = info
			self.loadHandler = loadHandler
		}

		/// Loads the contents of this container
		
		public var contents:Contents
		{
			get async throws
			{
				try await self.loadHandler(identifier,info)
			}
		}
	}
}


//----------------------------------------------------------------------------------------------------------------------
