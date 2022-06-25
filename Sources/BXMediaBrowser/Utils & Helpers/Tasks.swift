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


/// This class can be used to suspend all background loading Tasks in BXMediaBrowser. This is useful if the host
/// application performs some long running operation that is performance critical and should not be troubled with
/// unnecessary background work.
	
public final class Tasks
{

	/// Suspends all background work in BXMediaBrowser until resume() is called again.
	
	@MainActor public static func suspend()
	{
		Self.isSuspended = true
	}
	
	/// Resumes all background work that was previously suspended.
	
	@MainActor public static func resume()
	{
		Self.isSuspended = false
	}

	/// Returns true if background work is currently suspended.
	
	public private(set) static var isSuspended = false
	
	
//----------------------------------------------------------------------------------------------------------------------


	/// Call this function from a background Task at approriate intervals to suspend.
	///
	///		Task
	///		{
	///			try await Tasks.canContinue()
	///
	///			for i in 0...n
	///			{
	///				try await Tasks.canContinue()
	///
	///				// Perform expensive background work
	///			}
	///		}
	
	public static func canContinue() async throws
	{
		while Self.isSuspended
		{
			// Sleep for several seconds before checking again
			
			try await Task.sleep(nanoseconds:5_000_000_000)
		}
	}
}


//----------------------------------------------------------------------------------------------------------------------
