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


public extension String
{
	// General metadata
	
	static var fileSizeKey = kMDItemFSSize as String
	static var kindKey = kMDItemKind as String
	static var descriptionKey = "description"
	static var creationDateKey = "creationDate"
	static var modificationDateKey = "modificationDate"
	
	// Image metadata
	
	static var widthKey = kMDItemPixelWidth as String
	static var heightKey = kMDItemPixelHeight as String
	static var profileNameKey = "ProfileName"

	static var exifApertureKey = "ApertureValue"
	static var exifExposureTimeKey = "ExposureTime"
	static var exifFocalLengthKey = "FocalLenIn35mmFilm"
	static var exifCaptureDateKey = "DateTimeOriginal"
	
	// Video metadata
	
	static var codecsKey = kMDItemCodecs as String
	static var videoCodecKey = "videoCodec"
	static var audioCodecKey = "audioCodec"
	static var fpsKey = "fps"

	// Audio metadata
	
	static var durationKey = kMDItemDurationSeconds as String
	static var titleKey = kMDItemTitle as String
	static var albumKey = kMDItemAlbum as String
	static var authorsKey = kMDItemAuthors as String
	static var composerKey = kMDItemComposer as String
	static var genreKey = kMDItemMusicalGenre as String
	static var tempoKey = kMDItemTempo as String
	static var whereFromsKey = kMDItemWhereFroms as String
}


//----------------------------------------------------------------------------------------------------------------------
