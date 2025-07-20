// ModernCacheManager.swift - 現代化泛型快取管理器

import Foundation

// MARK: - 泛型快取管理器
class ModernCacheManager<T: Codable> {
    
    // MARK: - 快取條目
    private struct CacheEntry {
        let data: T
        let timestamp: Date
        let expirationInterval: TimeInterval
        
        var isExpired: Bool {
            Date().timeIntervalSince(timestamp) > expirationInterval
        }
    }
    
    // MARK: - Properties
    private var memoryCache: [String: CacheEntry] = [:]
    private let memoryQueue = DispatchQueue(label: "memory_cache_queue", attributes: .concurrent)
    private let diskQueue = DispatchQueue(label: "disk_cache_queue", qos: .utility)
    private let fileManager = FileManager.default
    private let maxMemoryCacheSize: Int
    private let maxDiskCacheSize: Int
    private let cacheDirectory: URL
    
    // MARK: - Initialization
    init(
        cacheDirectory: String,
        maxMemoryCacheSize: Int = 100,
        maxDiskCacheSize: Int = 500
    ) {
        self.maxMemoryCacheSize = maxMemoryCacheSize
        self.maxDiskCacheSize = maxDiskCacheSize
        
        // 設定快取目錄
        let documentsURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        self.cacheDirectory = documentsURL.appendingPathComponent(cacheDirectory)
        
        // 確保快取目錄存在
        createCacheDirectoryIfNeeded()
    }
    
    // MARK: - Public Methods
    
    /// 獲取快取項目
    func get(for key: String) async -> T? {
        // 首先檢查記憶體快取
        if let memoryEntry = getFromMemory(key: key) {
            if !memoryEntry.isExpired {
                return memoryEntry.data
            } else {
                removeFromMemory(key: key)
            }
        }
        
        // 檢查磁碟快取
        return await getFromDisk(key: key)
    }
    
    /// 設定快取項目
    func set(_ value: T, for key: String, expirationInterval: TimeInterval = 300) async {
        let entry = CacheEntry(
            data: value,
            timestamp: Date(),
            expirationInterval: expirationInterval
        )
        
        // 保存到記憶體快取
        setToMemory(key: key, entry: entry)
        
        // 非同步保存到磁碟快取
        await setToDisk(key: key, value: value, expirationInterval: expirationInterval)
    }
    
    /// 移除特定快取項目
    func remove(for key: String) async {
        removeFromMemory(key: key)
        await removeFromDisk(key: key)
    }
    
    /// 清除所有快取
    func clearAll() async {
        clearMemoryCache()
        await clearDiskCache()
    }
    
    /// 清除過期快取
    func cleanupExpired() async {
        cleanupExpiredMemoryCache()
        await cleanupExpiredDiskCache()
    }
    
    /// 獲取快取統計資訊
    func getCacheStats() async -> CacheStats {
        let memoryCount = memoryCache.count
        let diskCount = await getDiskCacheCount()
        let memorySize = await getMemoryCacheSize()
        let diskSize = await getDiskCacheSize()
        
        return CacheStats(
            memoryCount: memoryCount,
            diskCount: diskCount,
            memorySize: memorySize,
            diskSize: diskSize
        )
    }
    
    // MARK: - Memory Cache Operations
    
    private func getFromMemory(key: String) -> CacheEntry? {
        return memoryQueue.sync {
            return memoryCache[key]
        }
    }
    
    private func setToMemory(key: String, entry: CacheEntry) {
        memoryQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            self.memoryCache[key] = entry
            
            // 如果超過最大記憶體快取大小，移除最舊的項目
            if self.memoryCache.count > self.maxMemoryCacheSize {
                self.removeOldestMemoryEntries()
            }
        }
    }
    
    private func removeFromMemory(key: String) {
        memoryQueue.async(flags: .barrier) { [weak self] in
            self?.memoryCache.removeValue(forKey: key)
        }
    }
    
    private func clearMemoryCache() {
        memoryQueue.async(flags: .barrier) { [weak self] in
            self?.memoryCache.removeAll()
        }
    }
    
    private func cleanupExpiredMemoryCache() {
        memoryQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            let expiredKeys = self.memoryCache.compactMap { key, entry in
                entry.isExpired ? key : nil
            }
            
            for key in expiredKeys {
                self.memoryCache.removeValue(forKey: key)
            }
        }
    }
    
    private func removeOldestMemoryEntries() {
        let sortedEntries = memoryCache.sorted { $0.value.timestamp < $1.value.timestamp }
        let entriesToRemove = sortedEntries.prefix(memoryCache.count - maxMemoryCacheSize + 1)
        
        for (key, _) in entriesToRemove {
            memoryCache.removeValue(forKey: key)
        }
    }
    
    // MARK: - Disk Cache Operations
    
    private func getFromDisk(key: String) async -> T? {
        return await withCheckedContinuation { continuation in
            diskQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let fileURL = self.diskCacheURL(for: key)
                
                guard let data = try? Data(contentsOf: fileURL),
                      let cacheItem = try? JSONDecoder().decode(DiskCacheItem<T>.self, from: data) else {
                    continuation.resume(returning: nil)
                    return
                }
                
                // 檢查是否過期
                if Date().timeIntervalSince(cacheItem.timestamp) > cacheItem.expirationInterval {
                    try? self.fileManager.removeItem(at: fileURL)
                    continuation.resume(returning: nil)
                    return
                }
                
                continuation.resume(returning: cacheItem.data)
            }
        }
    }
    
    private func setToDisk(key: String, value: T, expirationInterval: TimeInterval) async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            diskQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume()
                    return
                }
                
                let cacheItem = DiskCacheItem(
                    data: value,
                    timestamp: Date(),
                    expirationInterval: expirationInterval
                )
                
                do {
                    let data = try JSONEncoder().encode(cacheItem)
                    let fileURL = self.diskCacheURL(for: key)
                    try data.write(to: fileURL)
                } catch {
                    print("磁碟快取寫入失敗: \(error)")
                }
                
                continuation.resume()
            }
        }
    }
    
    private func removeFromDisk(key: String) async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            diskQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume()
                    return
                }
                
                let fileURL = self.diskCacheURL(for: key)
                try? self.fileManager.removeItem(at: fileURL)
                continuation.resume()
            }
        }
    }
    
    private func clearDiskCache() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            diskQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume()
                    return
                }
                
                try? self.fileManager.removeItem(at: self.cacheDirectory)
                self.createCacheDirectoryIfNeeded()
                continuation.resume()
            }
        }
    }
    
    private func cleanupExpiredDiskCache() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            diskQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume()
                    return
                }
                
                do {
                    let fileURLs = try self.fileManager.contentsOfDirectory(
                        at: self.cacheDirectory,
                        includingPropertiesForKeys: nil
                    )
                    
                    for fileURL in fileURLs {
                        guard let data = try? Data(contentsOf: fileURL),
                              let cacheItem = try? JSONDecoder().decode(DiskCacheItem<T>.self, from: data) else {
                            continue
                        }
                        
                        if Date().timeIntervalSince(cacheItem.timestamp) > cacheItem.expirationInterval {
                            try? self.fileManager.removeItem(at: fileURL)
                        }
                    }
                } catch {
                    print("清理過期磁碟快取失敗: \(error)")
                }
                
                continuation.resume()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func diskCacheURL(for key: String) -> URL {
        let hashedKey = key.sha256
        return cacheDirectory.appendingPathComponent("\(hashedKey).cache")
    }
    
    private func createCacheDirectoryIfNeeded() {
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    private func getDiskCacheCount() async -> Int {
        return await withCheckedContinuation { continuation in
            diskQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(returning: 0)
                    return
                }
                
                do {
                    let contents = try self.fileManager.contentsOfDirectory(at: self.cacheDirectory, includingPropertiesForKeys: nil)
                    continuation.resume(returning: contents.count)
                } catch {
                    continuation.resume(returning: 0)
                }
            }
        }
    }
    
    private func getDiskCacheSize() async -> Int64 {
        return await withCheckedContinuation { continuation in
            diskQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(returning: 0)
                    return
                }
                
                var totalSize: Int64 = 0
                
                do {
                    let fileURLs = try self.fileManager.contentsOfDirectory(
                        at: self.cacheDirectory,
                        includingPropertiesForKeys: [.fileSizeKey]
                    )
                    
                    for fileURL in fileURLs {
                        let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey])
                        totalSize += Int64(resourceValues.fileSize ?? 0)
                    }
                } catch {
                    print("計算磁碟快取大小失敗: \(error)")
                }
                
                continuation.resume(returning: totalSize)
            }
        }
    }
    
    private func getMemoryCacheSize() async -> Int {
        return memoryQueue.sync {
            return memoryCache.count
        }
    }
}

// MARK: - 支援型別

private struct DiskCacheItem<T: Codable>: Codable {
    let data: T
    let timestamp: Date
    let expirationInterval: TimeInterval
}

struct CacheStats {
    let memoryCount: Int
    let diskCount: Int
    let memorySize: Int
    let diskSize: Int64
}

// MARK: - String 擴展
private extension String {
    var sha256: String {
        let data = Data(self.utf8)
        let hashedData = data.withUnsafeBytes { bytes in
            var hash = [UInt8](repeating: 0, count: 32)
            // 簡化版 hash，實際專案應使用 CryptoKit
            for (index, byte) in bytes.enumerated() {
                hash[index % 32] ^= byte
            }
            return hash
        }
        return hashedData.map { String(format: "%02x", $0) }.joined()
    }
}