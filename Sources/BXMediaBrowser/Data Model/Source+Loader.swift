//
//  Source+Loader.swift
//  MediaBrowserTest
//  Created by Peter Baumgartner on 04.12.21.
//


import Foundation


//----------------------------------------------------------------------------------------------------------------------


extension Source
{
	public actor Loader
	{
		public typealias LoadHandler = () async throws -> [Container]
		
		let identifier:String
		
		let loadHandler:LoadHandler
		
		init(identifier:String, loadHandler:@escaping LoadHandler)
		{
			self.identifier = identifier
			self.loadHandler = loadHandler
		}
		
		/// Loads the top-level containers of this source
		
		public var containers:[Container]
		{
			get async throws
			{
				return try await self.loadHandler()
			}
		}
	}
}


//----------------------------------------------------------------------------------------------------------------------
