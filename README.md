# BXMediaBrowser

BXMediaBrowser is the modern replacement for the popular (but aging) open source iMediaBrowser framework. 

BXMediaBrowser is supported on both macOS and iOS. 

BXMediaBrowser is asynchrounous by design, so that both local and remote media sources can be browsed. Think of Lightroom CC or unsplash.com. For this reason it needs to be higly efficient, with fast loading times and doing work lazily only when requested. 

BXMediaBrowser needs to be extensible (the model layer) and highly customizable (the user interface), so that it can be used by a wide variety of host apps.

BXMediaBrowser is written in Swift and uses Swift 5.5 concurrency features like async-await and actors to be thread-safe. For this reason the minimum deployment target for host apps needs to be macOS Catalina or iOS 13.



## 1) The Data Model

All model classes conform to ObservableObject to be SwiftUI compatible. They also conform to Hashable, so that they can be used with the modern diffable data sources APIs. Here is a list of the data model classes and how they relate to each other:

### BXMediaBrowser.Library	

The Library is the root object in the model graph. It contains an array of Sections. This corresponds to IMBLibraryController in iMedia.

### BXMediaBrowser.Section

A Section can have an optional name (like "Libraries", "Internet", "Folders", etc…). Each Section contains an array of Sources. Section has no equivalent in iMedia.

### BXMediaBrowser.Source

A Source is the abstract base class for providing access to media files. Concrete subclasses of Source are provided for Apple Photos.app, Music.app, Adobe Lightroom.app, or Finder folders. The host app can also create its own custom subclasses. Each Source can have 1 or more top-level Containers. In iMedia this was called an IMBParser.

### BXMediaBrowser.Container

A Container has a list of Objects. It can also have a list of sub-containers. That way tree-like hierarchies can be represented. Depending on the Source that created a Container, a Container can represent a folder, an album, a collection, a playlist, etc. In iMedia this was called an IMBNode.

### BXMediaBrowser.Object

An Object represents a single media file. This can be an image, video, or audio file, depending on the Source that created this Object. In iMedia this was called an IMBObject.


## 2) The User Interface Components

Documentation forthcoming
