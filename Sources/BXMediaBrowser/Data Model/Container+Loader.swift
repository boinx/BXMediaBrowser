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


import Foundation


//----------------------------------------------------------------------------------------------------------------------


extension Container
{
	public actor Loader
	{
		/// The identifier specifies the location of a Container
		
		public let identifier:String
		
		/// The loadHandler is an externally provided closure that returns the Contents for this Container
		
		public let loadHandler:LoadHandler
	
		/// A Container has an array of (sub) Containers and an array of Objects
		
		public typealias Contents = ([Container],[Object])
		
		/// The LoadHandler is a pure function closure that returns the Contents of a Container
		
		public typealias LoadHandler = (String,Any,Object.Filter) async throws -> Contents

		/// Creates a new Container with an externally supplied closure to load the contents
		
		public init(identifier:String, loadHandler:@escaping LoadHandler)
		{
			self.identifier = identifier
			self.loadHandler = loadHandler
		}

		/// Loads the contents of this container
		
		public func contents(with data:Any, filter:Object.Filter) async throws -> Contents
		{
			try await self.loadHandler(identifier,data,filter)
		}
	}
}


//----------------------------------------------------------------------------------------------------------------------
