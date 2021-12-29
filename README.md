# BXMediaBrowser

BXMediaBrowser is the modern replacement for the popular open source iMediaBrowser framework. 

BXMediaBrowser is supported on both macOS and iOS. 

BXMediaBrowser is written in Swift and uses Swift 5.5 concurrency features like async-await and actors to be thread-safe. There are two parts to this package:

## 1) The Data Model

All model classes conform to ObservableObject to be SwiftUI compaatible. Here is a list of the data model classes and how they relate to each other:

### BXMediaBrowser.Library	

The Library is the root object in the model graph. It contains an array of Sections

### BXMediaBrowser.Section

A Section can have an optional name (like "Libraries", "Internet", "Folders", etc...). Each Section contains an array of Sources.

### BXMediaBrowser.Source

Source is the abstract base class for providing access to media files. Concrete subclasses of Source are provided for Apple Photos.app, Music.app, Adobe Lightroom.app, or Finder folders. The host app can also create its own custom subclasses. Each Source can have 1 or more top-level Containers. 

### BXMediaBrowser.Container

A Container has a list of Objects. It can also have a list of sub-containers. That way tree-like hierarchies can be represented. Depending on the Source that created a Container, a Container can represent a folder, an album or collection, or a playlist.

### BXMediaBrowser.Object

An Object represents a single media file. This can be an image, video, or audio file, depending on the Source that created this Object.


	[BXMediaBrowser.Section]
		[BXMediaBrowser.Source]
			[BXMediaBrowser.Container]			IMBNode				e.g. Album, Playlist, Folder
				[BXMediaBrowser.Container]		IMBNode
				[BXMediaBrowser.Object]			IMBObject			e.g. Image, Video, Audio file

## 2) The User Interface Components
