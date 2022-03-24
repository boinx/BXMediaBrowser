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
	/// The unique identifier of this source must always remain the same. Do not change this
	/// identifier, even if the class name changes due to refactoring, because the identifier
	/// might be stored in a preferences file or user documents.
	
	static let identifier = "LightroomCC:"
	
	/// The current status
	
	@MainActor public var status:LightroomCC.Status = .unknown
	{
		willSet
		{
			self.objectWillChange.send()
		}
		
		didSet
		{
			LightroomCC.log.debug {"\(Self.self).\(#function) = \(status)"}
		}
	}


//----------------------------------------------------------------------------------------------------------------------


	/// Creates a new Source for local file system directories
	
	public init()
	{
		LightroomCC.log.debug {"\(Self.self).\(#function)"}
		
		let icon = Bundle.BXMediaBrowser.image(forResource:"LightroomCC")?.CGImage
		super.init(identifier:Self.identifier, icon:icon, name:"Adobe Lightroom CC", filter:PexelsFilter())
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
					self.status = LightroomCC.shared.isLoggedIn ? .loggedIn : .loggedOut
				}
			}
			else if let code = health.code, code == 9999
			{
				await MainActor.run
				{
					self.status = .currentlyUnavailable
				}
			}
			else
			{
				await MainActor.run
				{
					self.status = .invalidClientID
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

//		// Build a search request with the provided search string (filter)
//
//		let clientID = LightroomCC.shared.clientID
//		let accessPoint = LightroomCC.shared.healthCheckAPI
//		let urlComponents = URLComponents(string:accessPoint)!
//		guard let url = urlComponents.url else { throw Error.loadFailed }
//
//		var request = URLRequest(url:url)
//		request.httpMethod = "GET"
//		request.setValue(clientID, forHTTPHeaderField:"X-API-Key")
//
//		// Perform the online search
//
//		let data = try await URLSession.shared.data(with:request)
//		guard let strippedData = LightroomCC.stripped(data) else { throw Error.loadFailed }
//
//		// Decode returned JSON to array of UnsplashPhoto
//
//		let health = try JSONDecoder().decode(LightroomCC.Health.self, from:strippedData)
//
//		return health
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
		
		oauth2.authorize()
		{
			params,error in
			
			if let accessToken = oauth2.accessToken //, let params = params
			{
				LightroomCC.log.debug {"\(Self.self).\(#function) accessToken = \(oauth2.accessToken)"}
				LightroomCC.log.debug {"\(Self.self).\(#function) refreshToken = \(oauth2.refreshToken)"}
				
				Task
				{
					await MainActor.run
					{
						self.status = .loggedIn
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
						self.status = .loggedOut
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
		
		self.status = .loggedOut
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
		
		let catalog:LightroomCC.Catalog = try await LightroomCC.shared.getData(from:"https://lr.adobe.io/v2/catalog")
		let albums:LightroomCC.Albums = try await LightroomCC.shared.getData(from:"https://lr.adobe.io/v2/catalogs/\(catalog.id)/albums")
		
		LightroomCC.shared.catalogID = catalog.id
		LightroomCC.shared.allAlbums = albums.resources
	
		// Find top-level albums (parent is nil)
		
		let topLevelAlbums = albums.resources.filter
		{
			$0.payload.parent == nil
		}
		
		// Create a Container for each album
		
		return topLevelAlbums.map
		{
			LightroomCCContainer(album:$0, filter:filter)
		}
		
//		var containers:[Container] = []
//		
//		for album in topLevelAlbums
//		{
//			containers += LightroomCCContainer(album:album, filter:filter)
//		}
//		
//		return containers
	}
	
	
	
//	/// Creates a new "saved" copy of the live search container
//	
//	func saveContainer(_ container:Container)
//	{
//		LightroomCC.log.debug {"\(Self.self).\(#function)"}
//	
//		guard let liveSearchContainer = container as? PexelsPhotoContainer else { return }
//		guard let liveFilter = liveSearchContainer.filter as? PexelsFilter else { return }
//		guard let savedContainer = self.createContainer(with:liveFilter.copy) else { return }
//		self.addContainer(savedContainer)
//	}
//
//
//	/// Creates a new "saved" PexelsContainer with the specified filter
//	
//	func createContainer(with filter:PexelsFilter) -> PexelsPhotoContainer?
//	{
//		guard !filter.searchString.isEmpty else { return nil }
//
//		let searchString = filter.searchString
//		let orientation = filter.orientation.rawValue
//		let color = filter.color.rawValue
//		let identifier = "PexelsSource:\(searchString)/\(orientation)/\(color)".replacingOccurrences(of:" ", with:"-")
//		let name = PexelsPhotoContainer.description(with:filter)
//		
//		return PexelsPhotoContainer(identifier:identifier, icon:"rectangle.stack", name:name, filter:filter, removeHandler:
//		{
//			[weak self] container in
//			
//			let title = NSLocalizedString("Alert.title.removeFolder", bundle:.BXMediaBrowser, comment:"Alert Title")
//			let message = String(format:NSLocalizedString("Alert.message.removeFolder", bundle:.BXMediaBrowser, comment:"Alert Message"), container.name)
//			let ok = NSLocalizedString("Remove", bundle:.BXMediaBrowser, comment:"Button Title")
//			let cancel = NSLocalizedString("Cancel", bundle:.BXMediaBrowser, comment:"Button Title")
//			
//			NSAlert.presentModal(style:.critical, title:title, message:message, okButton:ok, cancelButton:cancel)
//			{
//				[weak self] in self?.removeContainer(container)
//			}
//		})
//	}


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
