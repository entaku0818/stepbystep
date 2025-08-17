//
//  UsageLimitClient.swift
//  TaskSteps
//
//  使用制限管理のDependency Client
//

import Foundation
import Dependencies

// MARK: - Usage Limit Client Protocol

struct UsageLimitClient {
    var currentUsageCount: () -> Int
    var remainingUsage: () -> Int
    var hasReachedLimit: () -> Bool
    var incrementUsage: () -> Void
    var getLimitMessage: () -> String
    var setUnlimited: (Bool) -> Void
    var resetUsageForDebug: () -> Void
}

// MARK: - Live Implementation

extension UsageLimitClient {
    static let live = Self(
        currentUsageCount: {
            UsageLimitManager.shared.currentUsageCount
        },
        remainingUsage: {
            UsageLimitManager.shared.remainingUsage
        },
        hasReachedLimit: {
            UsageLimitManager.shared.hasReachedLimit
        },
        incrementUsage: {
            UsageLimitManager.shared.incrementUsage()
        },
        getLimitMessage: {
            UsageLimitManager.shared.getLimitMessage()
        },
        setUnlimited: { unlimited in
            UsageLimitManager.shared.setUnlimited(unlimited)
        },
        resetUsageForDebug: {
            UsageLimitManager.shared.resetUsageForDebug()
        }
    )
}

// MARK: - Test Implementation

extension UsageLimitClient {
    static let test = Self(
        currentUsageCount: { 0 },
        remainingUsage: { 5 },
        hasReachedLimit: { false },
        incrementUsage: { },
        getLimitMessage: { "テスト用: 残り使用回数 5回" },
        setUnlimited: { _ in },
        resetUsageForDebug: { }
    )
    
    static func testLimited(current: Int = 0, limit: Int = 5) -> Self {
        var count = current
        let isUnlimited = false
        
        return Self(
            currentUsageCount: { count },
            remainingUsage: { max(0, limit - count) },
            hasReachedLimit: { count >= limit },
            incrementUsage: { count += 1 },
            getLimitMessage: {
                if count >= limit {
                    return "本日のAI分割使用回数（\(limit)回）に達しました。"
                } else {
                    return "本日の残り使用回数: \(max(0, limit - count))回"
                }
            },
            setUnlimited: { _ in },
            resetUsageForDebug: { count = 0 }
        )
    }
    
    static let testUnlimited = Self(
        currentUsageCount: { 0 },
        remainingUsage: { 999 },
        hasReachedLimit: { false },
        incrementUsage: { },
        getLimitMessage: { "Pro会員は無制限でご利用いただけます。" },
        setUnlimited: { _ in },
        resetUsageForDebug: { }
    )
}

// MARK: - Dependency Key

private enum UsageLimitClientKey: DependencyKey {
    static let liveValue = UsageLimitClient.live
    static let testValue = UsageLimitClient.test
}

extension DependencyValues {
    var usageLimitClient: UsageLimitClient {
        get { self[UsageLimitClientKey.self] }
        set { self[UsageLimitClientKey.self] = newValue }
    }
}