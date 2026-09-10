//----------------------------------------------------------------------------------------------------------------------
//
//  Copyright ©2022-2026 Peter Baumgartner. All rights reserved.
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
import Foundation


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
	
	
//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Concurrency Limit
	
	/// Caps how many thumbnails and metadata dictionaries are loaded at the same time.
	///
	/// Every visible ObjectCell kicks off its own unstructured Task, so without a limit the fan-out is only bounded
	/// by how many cells happen to be on screen. That used to be masked by the loaders blocking a cooperative pool
	/// thread each - which is precisely the deadlock that FM-2532 was about. Now that the loaders suspend properly,
	/// the fan-out needs an explicit bound: it keeps the number of in-flight QuickLook requests (and the peak memory
	/// of the decoded images) sane, and leaves cooperative threads for the rest of the app.
	///
	/// activeProcessorCount-2, which measurement rather than intuition picked: thumbnail loading turned out to be
	/// CPU bound (ImageIO decoding), not disk bound, so it scales almost linearly with concurrency and a cautious
	/// limit costs real throughput. Measured on a 10 core M-series with 90 JPEGs, best of 3 passes:
	///
	///		limit  1 →  41 files/s        limit  6 → 222 files/s
	///		limit  2 →  81 files/s        limit  8 → 278 files/s
	///		limit  4 → 156 files/s        limit 10 → 295 files/s
	///		limit  5 → 190 files/s        unlimited → 245 files/s
	///
	/// 118 MB TIFFs gave the same shape. Two things to read out of that: half the cores would give away about a
	/// third of the throughput for nothing, and unlimited is WORSE than a sensible cap, because oversubscribing the
	/// cooperative pool costs more than it gains. Leaving 2 threads free matters because ImageIO decoding is a long
	/// synchronous stretch with no suspension points, so a busy slot really does hold its thread for the duration -
	/// the UI is safe either way (the main thread is not part of this pool), but other background work is not.
	///
	/// The floor of 2 keeps a single slow file from stalling the browser on a low core Mac.
	
	static let concurrencyLimiter = BXConcurrencyLimiter(limit:max(2,ProcessInfo.processInfo.activeProcessorCount-2))
}


//----------------------------------------------------------------------------------------------------------------------
