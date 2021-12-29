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


extension Container
{

	/// Requests the purging of cached data for the objects in this container. This reduces the memory footprint.
	///
	/// Please note that cached data will not be purged immediately, but after the specified delay.

	func purgeCachedDataOfObjects(after delay:Double = 20)
	{
		self.purgeTask = Task
		{
			let ns = UInt64(delay * 1_000_000_000)
			try? await Task.sleep(nanoseconds:ns)
			
			if Task.isCancelled
			{
				self.purgeTask = nil
				return
			}
			
			await MainActor.run
			{
				self.objects.forEach { $0.purge() }
				self.purgeTask = nil
			}
		}
	}
	
	/// Cancels the request to purge cached data. This is useful when selecting a different Container
	/// (which triggers a request to purge cached data), and then selecting the same Container again.
	/// In this case we do not want the cached data to be purges after all, because that would require
	/// the app to load that data again. Instead it would be more convenient to keep the cached data.
	
	public func cancelPurgeCachedDataOfObjects()
	{
		self.purgeTask?.cancel()
	}
	
}


//----------------------------------------------------------------------------------------------------------------------
