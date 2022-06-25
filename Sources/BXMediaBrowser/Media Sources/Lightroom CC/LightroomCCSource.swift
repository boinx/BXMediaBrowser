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
	

	/// Returns true if the user is logged in to a valid Adobe account
	
	@MainActor public var hasAccess:Bool
	{
		LightroomCC.shared.isLoggedIn
	}
	
	
	/// Starts the Adobe login process via OAuth
	
	@MainActor public func grantAccess(_ completionHandler:@escaping (Bool)->Void = { _ in })
	{
		let oauth2 = LightroomCC.shared.oauth2
		
		if oauth2.isAuthorizing
		{
			oauth2.abortAuthorization()
		}
		
		oauth2.forgetTokens()
		
		oauth2.authorize()
		{
			params,error in
			
			if error != nil || oauth2.accessToken == nil
			{
				self.loginDidFail(with:error, completionHandler:completionHandler)
			}
			else
			{
				self.loginDidSucceed(completionHandler:completionHandler)
			}
		}
	}


	/// Logs out from the current account
	
	@MainActor public func revokeAccess(_ completionHandler:@escaping (Bool)->Void = { _ in })
	{
		LightroomCC.shared.reset()
		self.isExpanded = false
		completionHandler(hasAccess)
	}


	/// Called when the OAuth login has succeeded
	
	private func loginDidSucceed(completionHandler:@escaping (Bool)->Void)
	{
		let oauth2 = LightroomCC.shared.oauth2
		LightroomCC.log.debug {"\(Self.self).\(#function) accessToken = \(oauth2.accessToken ?? "nil")"}
		LightroomCC.log.debug {"\(Self.self).\(#function) refreshToken = \(oauth2.refreshToken ?? "nil")"}

		Task
		{
			do
			{
				// Get account info
				
				let account:LightroomCC.Account = try await LightroomCC.shared.getData(from:"https://lr.adobe.io/v2/account")

				await MainActor.run
				{
					LightroomCC.shared.userID = account.id
					LightroomCC.shared.userName = account.full_name
					LightroomCC.shared.userEmail = account.email
					LightroomCC.shared.status = .loggedIn
					
					self.isExpanded = true
					self.load()
					
					completionHandler(self.hasAccess)
				}
			}
			catch let error
			{
				LightroomCC.log.error {"\(Self.self).\(#function) ERROR \(error)"}

				await MainActor.run
				{
					LightroomCC.shared.reset()
					completionHandler(false)
				}
			}
		}
	}
	
	
	/// Called when the OAuth login has failed
	
	private func loginDidFail(with error:Swift.Error?, completionHandler:@escaping (Bool)->Void)
	{
		if let error = error
		{
			LightroomCC.log.error {"\(Self.self).\(#function) OAuth login failed: \(error)"}
		}
		
		Task
		{
			await MainActor.run
			{
				LightroomCC.shared.reset()
				completionHandler(false)
			}
		}
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
		
		do
		{
			// Get catalog info
			
			let catalog:LightroomCC.Catalog = try await LightroomCC.shared.getData(from:"https://lr.adobe.io/v2/catalog")
			let albums:LightroomCC.Albums = try await LightroomCC.shared.getData(from:"https://lr.adobe.io/v2/catalogs/\(catalog.id)/albums")

			await MainActor.run
			{
				LightroomCC.shared.catalogID = catalog.id
				LightroomCC.shared.allAlbums = albums.resources
			}
			
			// Create a container for "All Photos"
			
			var containers:[Container] = []

			try await Tasks.canContinue()
		
			containers += LightroomCCContainerAllPhotos(allowedMediaTypes:allowedMediaTypes, filter:filter)
			
			// Find top-level albums (parent is nil) and create a Container for each album
			
			let topLevelAlbums = albums.resources.filter
			{
				$0.payload.parent == nil
			}
			
			for album in topLevelAlbums
			{
				try await Tasks.canContinue()
		
				containers += LightroomCCContainer(album:album, allowedMediaTypes:allowedMediaTypes, filter:filter)
			}

			return containers
		}
		
		// In case of error clear everything
		
		catch
		{
			await MainActor.run
			{
				LightroomCC.shared.reset()
			}

			return []
		}
	}
}


//----------------------------------------------------------------------------------------------------------------------
