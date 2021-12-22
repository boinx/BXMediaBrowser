//
//  Container+Loader.swift
//  MediaBrowserTest
//  Created by Peter Baumgartner on 04.12.21.
//


import Foundation


//----------------------------------------------------------------------------------------------------------------------


extension Container
{
	public enum Error : Swift.Error
	{
		case notFound
		case accessDenied
		case loadContentsCancelled
		case loadContentsFailed
	}
}


//----------------------------------------------------------------------------------------------------------------------
