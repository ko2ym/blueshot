import Foundation
import AppKit
import OSLog

/// Manages Security-Scoped Bookmarks for persistent access to user-selected save folders.
actor BookmarkManager {

    static let shared = BookmarkManager()

    private var cachedURL: URL?

    // MARK: - Public API

    /// Returns the resolved save folder URL, or throws if none is configured or bookmark is stale.
    func resolveURL() async throws -> URL {
        if let url = cachedURL { return url }

        let bookmarkData: Data? = await MainActor.run {
            AppPreferences.shared.saveFolderBookmark
        }

        guard let bookmarkData else {
            throw BlueshotError.exportNoDestination
        }

        var isStale = false
        let url = try URL(
            resolvingBookmarkData: bookmarkData,
            options: .withSecurityScope,
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )

        if isStale {
            await MainActor.run { AppPreferences.shared.saveFolderBookmark = nil }
            throw BlueshotError.exportBookmarkStale
        }

        cachedURL = url
        return url
    }

    /// Executes a block inside a security-scoped resource access session.
    func withAccess<T: Sendable>(_ block: @Sendable () throws -> T) async throws -> T {
        let url = try await resolveURL()
        guard url.startAccessingSecurityScopedResource() else {
            throw BlueshotError.exportWriteFailed(underlying: CocoaError(.fileReadNoPermission))
        }
        defer { url.stopAccessingSecurityScopedResource() }
        return try block()
    }

    /// Clears the cached resolved URL (e.g. after the user changes the save folder).
    func invalidateCache() {
        cachedURL = nil
    }
}
