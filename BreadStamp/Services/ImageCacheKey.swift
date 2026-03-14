import Foundation
import CryptoKit

struct ImageCacheKey {
    enum Kind: String {
        case bakery
        case bread
    }

    let kind: Kind
    let id: UUID
    let version: String

    private struct MemoKey: Hashable {
        let kind: Kind
        let id: UUID
        let updatedAt: Date
    }

    private static let memoLock = NSLock()
    private static let memoLimit = 2048
    private static var hashMemo: [MemoKey: String] = [:]

    init(kind: Kind, id: UUID, updatedAt: Date, imageData: Data?) {
        self.kind = kind
        self.id = id
        self.version = Self.versionToken(
            for: MemoKey(kind: kind, id: id, updatedAt: updatedAt),
            imageData: imageData
        )
    }

    var rawValue: String {
        "\(kind.rawValue):\(id.uuidString):\(version)"
    }

    private static func versionToken(for memoKey: MemoKey, imageData: Data?) -> String {
        guard let imageData else {
            return "none"
        }

        memoLock.lock()
        if let cached = hashMemo[memoKey] {
            memoLock.unlock()
            return cached
        }
        memoLock.unlock()

        let digest = SHA256.hash(data: imageData)
        let token = digest.map { String(format: "%02x", $0) }.joined()

        memoLock.lock()
        if hashMemo.count >= memoLimit {
            hashMemo.removeAll(keepingCapacity: true)
        }
        hashMemo[memoKey] = token
        memoLock.unlock()
        return token
    }
}

extension Bakery {
    var imageCacheKey: String {
        ImageCacheKey(kind: .bakery, id: id, updatedAt: updatedAt, imageData: imageData).rawValue
    }
}

extension Bread {
    var imageCacheKey: String {
        ImageCacheKey(kind: .bread, id: id, updatedAt: updatedAt, imageData: imageData).rawValue
    }
}
