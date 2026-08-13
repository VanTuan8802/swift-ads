//
//  PreloadCallbackStore.swift
//  AdsSwift
//
//  Created by VanTuan8802 on 13/8/26.
//
//  Bookkeeping chung cho 4 class Preload (Inter/Rewards/AppOpen/RewardedInter):
//  map ad object đang present → adUnitId + callbacks, kèm buffer size.
//  Thread-safe bằng NSLock — GMA callback chủ yếu trên main nhưng các class
//  Preload đã tuyên bố Sendable nên state phải được bảo vệ đầy đủ.
//

import Foundation

final class PreloadCallbackStore: @unchecked Sendable {

    struct Entry {
        var adUnitId: String
        var onWillPresent: (() -> Void)?
        var onDismiss: ((Bool) -> Void)?
        var onFailedToPresent: ((Error) -> Void)?
        var onRewarded: (() -> Void)?
        var wasRewarded = false
    }

    private var entries: [ObjectIdentifier: Entry] = [:]
    private var bufferSizeByAdUnitId: [String: Int] = [:]
    private let lock = NSLock()

    // MARK: - Buffer size

    func setBuffer(_ size: Int, for adUnitId: String) {
        lock.lock(); defer { lock.unlock() }
        bufferSizeByAdUnitId[adUnitId] = size
    }

    func buffer(for adUnitId: String) -> Int {
        lock.lock(); defer { lock.unlock() }
        return bufferSizeByAdUnitId[adUnitId] ?? 0
    }

    // MARK: - Entries

    func register(_ oid: ObjectIdentifier,
                  adUnitId: String,
                  onWillPresent: (() -> Void)? = nil,
                  onDismiss: ((Bool) -> Void)? = nil,
                  onFailedToPresent: ((Error) -> Void)? = nil,
                  onRewarded: (() -> Void)? = nil) {
        lock.lock(); defer { lock.unlock() }
        entries[oid] = Entry(adUnitId: adUnitId,
                             onWillPresent: onWillPresent,
                             onDismiss: onDismiss,
                             onFailedToPresent: onFailedToPresent,
                             onRewarded: onRewarded)
    }

    func adUnitId(for oid: ObjectIdentifier) -> String? {
        lock.lock(); defer { lock.unlock() }
        return entries[oid]?.adUnitId
    }

    /// Đọc entry mà không xoá — dùng cho willPresent.
    func peek(_ oid: ObjectIdentifier) -> Entry? {
        lock.lock(); defer { lock.unlock() }
        return entries[oid]
    }

    /// Đánh dấu user đã nhận reward, trả về entry hiện tại để bắn callback.
    func markRewarded(_ oid: ObjectIdentifier) -> Entry? {
        lock.lock(); defer { lock.unlock() }
        entries[oid]?.wasRewarded = true
        return entries[oid]
    }

    /// Lấy và XOÁ entry — dùng cho dismiss / failedToPresent (kết thúc vòng đời ad).
    func take(_ oid: ObjectIdentifier) -> Entry? {
        lock.lock(); defer { lock.unlock() }
        return entries.removeValue(forKey: oid)
    }
}
