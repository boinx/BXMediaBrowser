//**********************************************************************************************************************
//
//  URL+downloadWithProgress.swift
//	Downloads cloud based files while reporting real download progress
//  Copyright ©2026 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


#if os(macOS)

import Foundation


//----------------------------------------------------------------------------------------------------------------------


extension URL
{
	/// Makes sure that the file at this URL is available locally, downloading it from the cloud (e.g. iCloud Drive)
	/// if needed, and returns the URL of the local file.
	///
	/// A plain coordinated read would download the file too, but it is a black box that blocks until the download
	/// has finished. While downloading, the file provider publishes a file Progress for the URL (this is what feeds
	/// the download pie in the Finder), so we subscribe to it and mirror its fractionCompleted into the supplied
	/// progress. If no progress is published (e.g. some third party cloud providers), the supplied progress simply
	/// stays at 0 until the download has finished.
	///
	/// Cancelling the supplied progress (or the calling Task) aborts waiting for the download.

	public func downloadFromCloud(reportingTo progress:Progress) async throws -> URL
	{
		defer { progress.completedUnitCount = progress.totalUnitCount }

		// Subscribe to published progress, but only if a download is actually needed

		var subscriber:Any? = nil

		if self.isEvictedCloudItem
		{
			let observer = CloudDownloadObserver(progress:progress)
			subscriber = Progress.addSubscriber(forFileURL:self) { observer.observe($0) }
		}

		defer { if let subscriber { Progress.removeSubscriber(subscriber) } }

		// The coordinated read blocks until the download has finished, so it must not run on a cooperative pool
		// thread (see FM-2532). Instead run it on a GCD queue. Cancelling the coordinator makes the pending
		// coordination fail with NSUserCancelledError, which the closure below passes on.

		// NSFileCoordinator is not marked Sendable, but cancel() is explicitly documented to be callable from any thread
		
		nonisolated(unsafe) let coordinator = NSFileCoordinator(filePresenter:nil)
		progress.cancellationHandler = { coordinator.cancel() }

		return try await withTaskCancellationHandler
		{
			try await withCheckedThrowingContinuation
			{
				continuation in

				DispatchQueue.global(qos:.userInitiated).async
				{
					var error:NSError? = nil
					var localURL:URL? = nil

					coordinator.coordinate(readingItemAt:self, options:[.resolvesSymbolicLink], error:&error)
					{
						localURL = $0
					}

					if let localURL
					{
						continuation.resume(returning:localURL)
					}
					else
					{
						continuation.resume(throwing:error ?? CocoaError(.fileReadUnknown))
					}
				}
			}
		}
		onCancel:
		{
			coordinator.cancel()
		}
	}
}


//----------------------------------------------------------------------------------------------------------------------


/// Mirrors the fractionCompleted of published (cross-process) Progress objects into a local Progress

fileprivate final class CloudDownloadObserver : @unchecked Sendable
{
	private let progress:Progress
	private var observations:[ObjectIdentifier:NSKeyValueObservation] = [:]
	private var maxFraction:Double = 0.0
	private let lock = NSLock()


	init(progress:Progress)
	{
		self.progress = progress
	}


	/// Called on the main thread whenever a progress is published for the URL. The returned closure is called
	/// once the progress gets unpublished again (or when the subscriber is removed).

	func observe(_ published:Progress) -> (@Sendable () -> Void)?
	{
		let id = ObjectIdentifier(published)

		let observation = published.observe(\.fractionCompleted, options:[.initial,.new])
		{
			[weak self] published,_ in self?.update(with:published.fractionCompleted)
		}

		lock.withLock { observations[id] = observation }

		let unpublish:@Sendable () -> Void =
		{
			[weak self] in
			guard let self else { return }
			let observation = self.lock.withLock { self.observations.removeValue(forKey:id) }
			observation?.invalidate()
		}
		
		return unpublish
	}


	/// Never lets the local progress go backwards. The provider may republish its progress, or several progress
	/// objects may be published for the same file, and a progress bar that jumps back looks broken.

	private func update(with fraction:Double)
	{
		guard fraction.isFinite else { return }

		let units:Int64? = lock.withLock
		{
			guard fraction > maxFraction else { return nil }
			maxFraction = min(fraction,1.0)
			return Int64(maxFraction * Double(progress.totalUnitCount))
		}

		if let units
		{
			progress.completedUnitCount = units
		}
	}


	deinit
	{
		observations.values.forEach { $0.invalidate() }
	}
}


//----------------------------------------------------------------------------------------------------------------------


#endif
