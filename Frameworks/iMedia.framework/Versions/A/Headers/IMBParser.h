/*
 iMedia Browser Framework <http://karelia.com/imedia/>
 
 Copyright (c) 2005-2012 by Karelia Software et al.
 
 iMedia Browser is based on code originally developed by Jason Terhorst,
 further developed for Sandvox by Greg Hulands, Dan Wood, and Terrence Talbot.
 The new architecture for version 2.0 was developed by Peter Baumgartner.
 Contributions have also been made by Matt Gough, Martin Wennerberg and others
 as indicated in source files.
 
 The iMedia Browser Framework is licensed under the following terms:
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in all or substantial portions of the Software without restriction, including
 without limitation the rights to use, copy, modify, merge, publish,
 distribute, sublicense, and/or sell copies of the Software, and to permit
 persons to whom the Software is furnished to do so, subject to the following
 conditions:
 
	Redistributions of source code must retain the original terms stated here,
	including this list of conditions, the disclaimer noted below, and the
	following copyright notice: Copyright (c) 2005-2012 by Karelia Software et al.
 
	Redistributions in binary form must include, in an end-user-visible manner,
	e.g., About window, Acknowledgments window, or similar, either a) the original
	terms stated here, including this list of conditions, the disclaimer noted
	below, and the aforementioned copyright notice, or b) the aforementioned
	copyright notice and a link to karelia.com/imedia.
 
	Neither the name of Karelia Software, nor Sandvox, nor the names of
	contributors to iMedia Browser may be used to endorse or promote products
	derived from the Software without prior and express written permission from
	Karelia Software or individual contributors, as appropriate.
 
 Disclaimer: THE SOFTWARE IS PROVIDED BY THE COPYRIGHT OWNER AND CONTRIBUTORS
 "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
 LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE,
 AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 LIABLE FOR ANY CLAIM, DAMAGES, OR OTHER LIABILITY, WHETHER IN AN ACTION OF
 CONTRACT, TORT, OR OTHERWISE, ARISING FROM, OUT OF, OR IN CONNECTION WITH, THE
 SOFTWARE OR THE USE OF, OR OTHER DEALINGS IN, THE SOFTWARE.
*/


//----------------------------------------------------------------------------------------------------------------------


// Author: Peter Baumgartner, Mike Abdullah


//----------------------------------------------------------------------------------------------------------------------


#pragma mark HEADERS

#import "IMBCommon.h"


//----------------------------------------------------------------------------------------------------------------------


#pragma mark CLASSES

@class IMBNode;
@class IMBObject;
@class IMBParserMessenger;


//----------------------------------------------------------------------------------------------------------------------


#pragma mark 

@interface IMBParser : NSObject
{
	@private
	
	NSString* _identifier;
	NSString* _mediaType;
	NSURL* _mediaSource;
}

// Together these parameters uniquely specify a parser instance. The values are taken from IMBParserFacrtory...

@property (copy) NSString* identifier;	
@property (copy) NSString* mediaType;	
@property (retain) NSURL* mediaSource;

// The following three methods are at the heart of parser classes and must be implemented. They will be called on
// on the XPC service side: Together they create the iMedia data model tree, which gets serialized and sent back
// to the host app, where it is given to and owned by the IMBLibraryController. The first method is only called
// once at startup to create an empty toplevel node, while the second method may be called multiple times. The
// third method has a generic implementation that may be sufficient for most subclasses...

- (IMBNode*) unpopulatedTopLevelNode:(NSError**)outError;
- (BOOL) populateNode:(IMBNode*)inNode error:(NSError**)outError;
- (IMBNode*) reloadNodeTree:(IMBNode*)inNode error:(NSError**)outError;

// The following three methods are used to load thumbnails or metadata, or create a security-scoped bookmark for  
// full media file access. They are called on the XPC service side...

- (id) thumbnailForObject:(IMBObject*)inObject error:(NSError**)outError;
- (NSDictionary*) metadataForObject:(IMBObject*)inObject error:(NSError**)outError;
- (NSData*) bookmarkForObject:(IMBObject*)inObject error:(NSError**)outError;

// Get parser's media source current accessibility status. Defaults to imb_accessibility of media source URL.
// Override in subclass to suit other parsers' needs.

- (IMBResourceAccessibility) mediaSourceAccessibility;

// Subclasses have the opportunity to return a more specific error intended to be presented to the user
// if media source is not accessible.

- (NSError *)mediaSourceAccessibilityError;

// Get object's resource current accessibility status

- (IMBResourceAccessibility) accessibilityForObject:(IMBObject*)inObject;

@end


//----------------------------------------------------------------------------------------------------------------------


#pragma mark 

// Helper method for subclasses...

@interface IMBParser (Helpers)

// Can be used to construct IMBNode identifiers...

- (NSString*) identifierForPath:(NSString*)inPath;

// Can be used to construct IMBObject identifiers...

- (NSString*) identifierForObject:(IMBObject*)inObject;

// Returns an identifier for the resource that self denotes and that is meant to be persistent across launches
// (e.g. when host app developers need to persist usage info of media files when implementing the badging delegate API).
// This standard implementation is based on file reference URLs - so it will only work for file based URLs.
// Subclass to adjust to the needs of your parser.

- (NSString*) persistentResourceIdentifierForObject:(IMBObject*)inObject;

// Returns the form of the persistent resource identifier for inObject that was used in iMedia2.
// You can use this string to compare against your app's stored identifiers and convert them to
// their new identifiers (persistentResourceIdentifierForObject:).
// NOTE: This method should only be invoked for such purpose. It might be removed from the framework
//       in future versions.

- (NSString*) iMedia2PersistentResourceIdentifierForObject:(IMBObject*)inObject;

// Subclasses may want to override this method to provide a backward compatible string. 
// See further comments in implementation file...

- (NSString*) iMedia2PersistentResourceIdentifierPrefix;

// Returns a minimal image for a given file system item that can be used as an icon for IMBNode...

- (NSImage*) iconForItemAtURL:(NSURL*)url error:(NSError **)error;

// Default implementation for getting thumbnails...

- (CGImageRef) thumbnailFromLocalImageFileForObject:(IMBObject*)inObject error:(NSError**)outError;
- (CGImageRef) thumbnailFromQuicklookForObject:(IMBObject*)inObject error:(NSError**)outError;

// Default implementation for getting a bookmark for an existing local file...

- (NSData*) bookmarkForLocalFileObject:(IMBObject*)inObject error:(NSError**)outError;

@end


//----------------------------------------------------------------------------------------------------------------------


