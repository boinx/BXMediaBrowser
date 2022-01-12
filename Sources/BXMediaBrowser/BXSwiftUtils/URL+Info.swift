//**********************************************************************************************************************
//
//  URL+Info.swift
//	Adds new methods to URL
//  Copyright ©2016-2018 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation
import Darwin
import UniformTypeIdentifiers


//----------------------------------------------------------------------------------------------------------------------


// MARK: -

extension URL
{

	// Status
	
	public enum Status : Int
	{
		case doesNotExist
		case accessDenied
		case readOnly
		case readWrite
	}

	/// Gets the file status
	
	public var status: Status
	{
		let cpath = self.path.cString(using: String.Encoding.utf8)
		let exists = access(cpath,F_OK) == 0
		let readable = access(cpath,R_OK) == 0
		let writeable = access(cpath,W_OK) == 0
		
		if !exists
		{
			return Status.doesNotExist
		}
		else  if !readable
		{
			return Status.accessDenied
		}
		else if !writeable
		{
			return Status.readOnly
		}
		
		return Status.readWrite
	}

}


//----------------------------------------------------------------------------------------------------------------------


// MARK: -

extension URL
{

	// FIXME: The following methods could also be implemented on the basis of status
	
	/// Checks if the file exists
	
	public var exists: Bool
	{
		if self.isFileURL
		{
			return FileManager.default.fileExists(atPath: self.path)
		}
		
		return false
	}

	/// Checks if the file is readable
	
	public var isReadable: Bool
	{
		do
		{
			let key = URLResourceKey.isReadableKey
			let values = try self.resourceValues(forKeys: [key])
			if let readable = values.isReadable
			{
				return readable
			}
			else
			{
				return false
			}
		}
		catch
		{
			return false
		}
	}

	/// Checks if the file is writable
	
	public var isWritable: Bool
	{
		do
		{
			let key = URLResourceKey.isWritableKey
			let values = try self.resourceValues(forKeys: [key])
			if let readable = values.isReadable
			{
				return readable
			}
			else
			{
				return false
			}
		}
		catch
		{
			return false
		}
	}
		
}


//----------------------------------------------------------------------------------------------------------------------


// MARK: -

extension URL
{

	/// Checks if the URL points to a directory
	
	public var isDirectory: Bool
	{
		do
		{
			let key = URLResourceKey.isDirectoryKey
			let values = try self.resourceValues(forKeys: [key])
			if let directory = values.isDirectory
			{
				return directory
			}
			else
			{
				return false
			}
		}
		catch
		{
			return false
		}
	}
	
	/// Checks if the URL is a directory with subfolders
	
	public var hasSubfolders: Bool
	{
		guard self.isDirectory else { return false }

		let filenames = (try? FileManager.default.contentsOfDirectory(atPath:self.path)) ?? []
		
		for filename in filenames
		{
			let url = self.appendingPathComponent(filename)
			if url.isDirectory { return true }
		}
		
		return false
	}
	
	/// Checks if the URL points to a package directory
	
	public var isPackage: Bool
	{
		do
		{
			let key = URLResourceKey.isPackageKey
			let values = try self.resourceValues(forKeys: [key])
			if let package = values.isPackage
			{
				return package
			}
			else
			{
				return false
			}
		}
		catch
		{
			return false
		}
	}
	
	/// Checks if the URL points to an invisible file system item

	public var isHidden: Bool
	{
		do
		{
			let key = URLResourceKey.isHiddenKey
			let values = try self.resourceValues(forKeys: [key])
			if let isHidden = values.isHidden
			{
				return isHidden
			}
			else
			{
				return false
			}
		}
		catch
		{
			return false
		}
	}

	/// Checks if the URL points to a symlink

	public var isSymbolicLink: Bool
	{
		do
		{
			let key = URLResourceKey.isSymbolicLinkKey
			let values = try self.resourceValues(forKeys: [key])
			if let package = values.isSymbolicLink
			{
				return package
			}
			else
			{
				return false
			}
		}
		catch
		{
			return false
		}
	}

	/// Returns the UTI of a file URL
	
	public var uti: String?
	{
		do
		{
			let key = URLResourceKey.typeIdentifierKey
			let values = try self.resourceValues(forKeys: [key])
			let uti = values.typeIdentifier
			return uti
		}
		catch // let error
		{
			return nil
		}
	}
 
 	/// Returns the fileSize in bytes
	
	public var fileSize: Int?
	{
		do
		{
			let key = URLResourceKey.fileSizeKey
			let values = try self.resourceValues(forKeys: [key])
			let fileSize = values.fileSize
			return fileSize
		}
		catch // let error
		{
			return nil
		}
	}


	/// Returns the creation date of a file URL
	
	public var creationDate: Date?
	{
		do
		{
			let key = URLResourceKey.creationDateKey
			let values = try self.resourceValues(forKeys: [key])
			let date = values.creationDate
			return date
		}
		catch
		{
			return nil
		}
	}

	/// Returns the modification date of a file URL
	
	public var modificationDate: Date?
	{
		do
		{
			let key = URLResourceKey.contentModificationDateKey
			let values = try self.resourceValues(forKeys: [key])
			let date = values.contentModificationDate
			return date
		}
		catch
		{
			return nil
		}
	}

	/// Does the volume for this URL support hardlinking?
	
	public var volumeSupportsHardlinking: Bool
	{
		guard let volumeURL = self.volumeURL else { return false }
		let key = URLResourceKey.volumeSupportsHardLinksKey
		let values = try? volumeURL.resourceValues(forKeys: [key])
		return values?.volumeSupportsHardLinks ?? false
	}

	/// Is this a readonly volume?
	
	public var volumeIsReadOnly: Bool
	{
		guard let volumeURL = self.volumeURL else { return false }
		let key = URLResourceKey.volumeIsReadOnlyKey
		let values = try? volumeURL.resourceValues(forKeys: [key])
		return values?.volumeIsReadOnly ?? false
	}

	/// Return the URL of the volume
	
	public var volumeURL: URL?
	{
		var value:URL? = nil
		var url = self
		let key = URLResourceKey.volumeURLKey

		repeat
		{
			let values = try? url.resourceValues(forKeys: [key])
			value = values?.volume
			url = url.deletingLastPathComponent()
		}
		while value == nil && url.path.count > 1
		
		return value
	}

	/// Return the UUID of the volume
	
	public var volumeUUID: String?
	{
		guard let volumeURL = self.volumeURL else { return nil }
		let key = URLResourceKey.volumeUUIDStringKey
		let values = try? volumeURL.resourceValues(forKeys: [key])
		return values?.volumeUUIDString
	}

	/// Return the free space on the volume
	
	public var volumeAvailableCapacity: Int?
	{
		guard let volumeURL = self.volumeURL else { return nil }
		let key = URLResourceKey.volumeAvailableCapacityKey
		let values = try? volumeURL.resourceValues(forKeys: [key])
		return values?.volumeAvailableCapacity
	}

	/// Return the free space on the volume
	
	@available (macOS 10.13, *)
	public var volumeAvailableCapacityForImportantUsage: Int?
	{
		guard let volumeURL = self.volumeURL else { return nil }
		let key = URLResourceKey.volumeAvailableCapacityForImportantUsageKey
		let values = try? volumeURL.resourceValues(forKeys: [key])

		guard let bytes = values?.volumeAvailableCapacityForImportantUsage else { return nil }
		return Int(bytes)
	}

	/// Return the free space on the volume
	
	@available (macOS 10.13, *)
	public var volumeAvailableCapacityForOpportunisticUsage: Int?
	{
		guard let volumeURL = self.volumeURL else { return nil }
		let key = URLResourceKey.volumeAvailableCapacityForOpportunisticUsageKey
		let values = try? volumeURL.resourceValues(forKeys: [key])
		guard let bytes = values?.volumeAvailableCapacityForOpportunisticUsage else { return nil }
		return Int(bytes)
	}
	
}


//----------------------------------------------------------------------------------------------------------------------


// MARK: -

#if os(iOS)

extension URL
{
	/// Returns true if this is an URL like ipod-library://item/item.m4a?id=9211483178757089008, which is returned
	/// by the MediaPlayer framework. Unfortunately URLs like this cannot be used with FileManager and other system
	/// level APIs.
	
	public var isiPodLibraryURL:Bool
	{
		return self.scheme == "ipod-library"
	}
}

#endif


//----------------------------------------------------------------------------------------------------------------------


// MARK: -

extension URL
{
	/// Updates the modification date of the file to now
	
	public func touch() throws
	{
		let now = Date()
		let attributes:[FileAttributeKey:Any] = [.modificationDate:now]
		try FileManager.default.setAttributes(attributes, ofItemAtPath:self.path)
	}
}


//----------------------------------------------------------------------------------------------------------------------


// MARK: -

extension URL
{
	public func conforms(to type:UTType) -> Bool
	{
		guard let utiString = self.uti else { return false }
		
		if #available(macOS 12,*)
		{
			guard let uti = UTType(utiString) else { return false }
			return uti.conforms(to:type)
		}
		else
		{
			return UTTypeConformsTo(utiString as CFString, type.identifier as CFString)
		}
	}

}

//----------------------------------------------------------------------------------------------------------------------


