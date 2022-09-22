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


// Common

#import <iMedia/IMBCommon.h>
#import <iMedia/IMBConfig.h>

// Controllers

#import <iMedia/IMBPanelController.h>
#import <iMedia/IMBParserController.h>
#import <iMedia/IMBLibraryController.h>
#import <iMedia/IMBAccessRightsController.h>
#import <iMedia/IMBFileSystemObserver.h>

#import <iMedia/IMBNodeViewController.h>
#import <iMedia/IMBImageNodeViewController.h>
#import <iMedia/IMBAudioNodeViewController.h>
#import <iMedia/IMBMovieNodeViewController.h>
#import <iMedia/IMBLinkNodeViewController.h>

#import <iMedia/IMBObjectViewController.h>
#import <iMedia/IMBImageObjectViewController.h>
#import <iMedia/IMBAudioObjectViewController.h>
#import <iMedia/IMBMovieObjectViewController.h>
#import <iMedia/IMBLinkObjectViewController.h>
#import <iMedia/IMBSkimmableObjectViewController.h>
#import <iMedia/IMBiPhotoEventObjectViewController.h>
#import <iMedia/IMBFaceObjectViewController.h>
#import <iMedia/IMBAccessRightsViewController.h>

// Parsers

#import <iMedia/IMBParserMessenger.h>
#import <iMedia/IMBFolderParserMessenger.h>
#import <iMedia/IMBImageFolderParserMessenger.h>
#import <iMedia/IMBAudioFolderParserMessenger.h>
#import <iMedia/IMBMovieFolderParserMessenger.h>
#import <iMedia/IMBAppleMediaParserMessenger.h>
#import <iMedia/IMBGarageBandParserMessenger.h>
#import <iMedia/IMBSafariParserMessenger.h>
#import <iMedia/IMBiPhotoParserMessenger.h>
#import <iMedia/IMBiTunesParserMessenger.h>
#import <iMedia/IMBLightroomParserMessenger.h>

#import <iMedia/IMBParser.h>
#import <iMedia/IMBImageFolderParser.h>
#import <iMedia/IMBAudioFolderParser.h>
#import <iMedia/IMBMovieFolderParser.h>

// Model

#import <iMedia/IMBNode.h>

#import <iMedia/IMBObject.h>
#import <iMedia/IMBNodeObject.h>
#import <iMedia/IMBButtonObject.h>
#import <iMedia/IMBFolderObject.h>
#import <iMedia/IMBSmartFolderObject.h>
#import <iMedia/IMBLinkObject.h>
#import <iMedia/IMBSkimmableObject.h>
#import <iMedia/IMBLightroomObject.h>
#import <iMedia/IMBiPhotoEventNodeObject.h>

#import <iMedia/IMBObjectFifoCache.h>

// View

#import <iMedia/IMBPanel.h>
#import <iMedia/IMBProgressWindowController.h>
#import <iMedia/IMBOutlineView.h>
#import <iMedia/IMBNodeCell.h>
#import <iMedia/IMBTableView.h>
#import <iMedia/IMBDynamicTableView.h>
#import <iMedia/IMBComboTableView.h>
#import <iMedia/IMBComboTextCell.h>
#import <iMedia/IMBTextFieldCell.h>
#import <iMedia/IMBImageBrowserView.h>
#import <iMedia/IMBImageBrowserCell.h>
#import <iMedia/IMBViewAppearance.h>
#import <iMedia/IMBTableViewAppearance.h>
#import <iMedia/IMBComboTableViewAppearance.h>

// Categories

#import <iMedia/NSPasteboard+iMedia.h>
#import <iMedia/NSWorkspace+iMedia.h>
#import <iMedia/NSView+iMedia.h>
#import <iMedia/NSURL+iMedia.h>
#import <iMedia/NSString+iMedia.h>
#import <iMedia/NSKeyedArchiver+iMedia.h>
#import <iMedia/NSImage+iMedia.h>
#import <iMedia/NSFileManager+iMedia.h>
#import <iMedia/NSDictionary+iMedia.h>
#import <iMedia/NSData+SKExtensions.h>

// Misc

#import <iMedia/IMBDisableTitleToColorTransformer.h>
#import <iMedia/IMBTimecodeTransformer.h>
#import <iMedia/IMBMetadataTransformer.h>
#import <iMedia/SBUtilities.h>

//#import <iMedia/IMBKQueue.h>
//#import <iMedia/IMBMainThreadProxy.h>
//#import <iMedia/IMBFileWatcher.h>
//#import <iMedia/IMBFSEventsWatcher.h>
//#import <iMedia/IMBFNSubscribeFileWatcher.h>


//----------------------------------------------------------------------------------------------------------------------


