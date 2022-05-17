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


import BXSwiftUtils
import OAuth2
import SwiftUI


//----------------------------------------------------------------------------------------------------------------------


open class LightroomCCSource : Source, AccessControl
{
	public let allowedMediaTypes:[Object.MediaType]
	
	/// The unique identifier of this source must always remain the same. Do not change this
	/// identifier, even if the class name changes due to refactoring, because the identifier
	/// might be stored in a preferences file or user documents.
	
	static let identifier = "LightroomCC:"
	
	
//----------------------------------------------------------------------------------------------------------------------


	/// Creates a new Source for local file system directories
	
	public init(allowedMediaTypes:[Object.MediaType])
	{
		LightroomCC.log.debug {"\(Self.self).\(#function)"}
		
		self.allowedMediaTypes = allowedMediaTypes
		
		super.init(
			identifier: Self.identifier,
			icon: CGImage.image(named:"lr_appicon_noshadow_256", in:.BXMediaBrowser),
			name: "Adobe Lightroom",
			filter: LightroomCCFilter())
		
		self.loader = Loader(loadHandler:self.loadContainers)

		self.checkHealth()
	}
	
	
	
//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Health Check
	
	/// Performs a health check with exponential backoff delays if the Lightroom CC serivce is currently unavailable

	private func checkHealth()
	{
		LightroomCC.log.debug {"\(Self.self).\(#function)"}

		Task
		{
			var health:LightroomCC.Health? = nil
			var delay = UInt64(1_000_000_000)
			
			while health == nil
			{
				health = try await Self.checkHealth()
				
				if health == nil
				{
					try await Task.sleep(nanoseconds:delay)
					delay *= 2
				}
				
				if let health = health
				{
					if health.version == nil
					{
						try await Task.sleep(nanoseconds:delay)
						delay *= 2
					}
				}
			}
			
			guard let health = health else { return }
 
			if health.version != nil
			{
				await MainActor.run
				{
					LightroomCC.shared.status = LightroomCC.shared.isLoggedIn ? .loggedIn : .loggedOut
				}
			}
			else if let code = health.code, code == 9999
			{
				await MainActor.run
				{
					LightroomCC.shared.status = .currentlyUnavailable
				}
			}
			else
			{
				await MainActor.run
				{
					LightroomCC.shared.status = .invalidClientID
				}
			}
			
		}
	}
	
	
	/// Performs a health check for the Lightroom CC internet service
	
	private class func checkHealth() async throws -> LightroomCC.Health
	{
		LightroomCC.log.verbose {"\(Self.self).\(#function)"}

		let health:LightroomCC.Health = try await LightroomCC.shared.getData(from:"https://lr.adobe.io/v2/health", requiresAccessToken:false)
		return health
	}


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Login
	

	@MainActor public var hasAccess:Bool
	{
		LightroomCC.shared.isLoggedIn
	}
	
	
	@MainActor public func grantAccess(_ completionHandler:@escaping (Bool)->Void = { _ in })
	{
		let oauth2 = LightroomCC.shared.oauth2
		
		if oauth2.isAuthorizing
		{
			oauth2.abortAuthorization()
		}
		
		oauth2.authorize()
		{
			params,error in
			
			if oauth2.accessToken != nil
			{
				LightroomCC.log.debug {"\(Self.self).\(#function) accessToken = \(oauth2.accessToken ?? "nil")"}
				LightroomCC.log.debug {"\(Self.self).\(#function) refreshToken = \(oauth2.refreshToken ?? "nil")"}
				
				Task
				{
					await MainActor.run
					{
						LightroomCC.shared.status = .loggedIn
						self.load()
						completionHandler(self.hasAccess)
					}
				}
			}
			else if let error = error
			{
				LightroomCC.log.error {"\(Self.self).\(#function) OAuth login failed: \(error)"}

				Task
				{
					await MainActor.run
					{
						LightroomCC.shared.status = .loggedOut
						completionHandler(self.hasAccess)
					}
				}
			}
		}
	}

	@MainActor public func revokeAccess(_ completionHandler:@escaping (Bool)->Void = { _ in })
	{
//		LightroomCC.shared.oauth2.forgetClient()
		LightroomCC.shared.oauth2.forgetTokens()
		LightroomCC.shared.catalogID = ""
		LightroomCC.shared.allAlbums = []
		
		LightroomCC.shared.status = .loggedOut
		completionHandler(hasAccess)
	}


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Top Level Containers
	
	/// Loads the top-level containers of this source.
	///
	/// Subclasses can override this function, e.g. to load top level folder from the preferences file
	
	private func loadContainers(with sourceState:[String:Any]? = nil, filter:Object.Filter) async throws -> [Container]
	{
		LightroomCC.log.debug {"\(Self.self).\(#function)"}

		guard LightroomCC.shared.isLoggedIn else { return [] }
		guard let filter = filter as? LightroomCCFilter else { return [] }
		
		// Get account & catalog  info
		
		let account:LightroomCC.Account = try await LightroomCC.shared.getData(from:"https://lr.adobe.io/v2/account")
		let catalog:LightroomCC.Catalog = try await LightroomCC.shared.getData(from:"https://lr.adobe.io/v2/catalog")
		let albums:LightroomCC.Albums = try await LightroomCC.shared.getData(from:"https://lr.adobe.io/v2/catalogs/\(catalog.id)/albums")
		
		await MainActor.run
		{
			LightroomCC.shared.catalogID = catalog.id
			LightroomCC.shared.allAlbums = albums.resources
			LightroomCC.shared.userID = account.id
			LightroomCC.shared.userName = account.full_name
			LightroomCC.shared.userEmail = account.email
		}
		
		// Find top-level albums (parent is nil)
		
		let topLevelAlbums = albums.resources.filter
		{
			$0.payload.parent == nil
		}
		
		// Create a Container for each album
		
		return topLevelAlbums.map
		{
			LightroomCCContainer(album:$0, allowedMediaTypes:allowedMediaTypes, filter:filter)
		}
	}


//----------------------------------------------------------------------------------------------------------------------


	/// Returns the archived filterData of all saved Containers
	
	override public func state() async -> [String:Any]
	{
		var state = await super.state()
		
		let savedFilterDatas = await self.containers
			.compactMap { $0 as? PexelsPhotoContainer }
			.filter { $0.saveHandler == nil }
			.compactMap { $0.filterData }

		state[Self.savedFilterDatasKey] = savedFilterDatas

		return state
	}

	internal static var savedFilterDatasKey:String { "savedFilterDatas" }


}


//----------------------------------------------------------------------------------------------------------------------
