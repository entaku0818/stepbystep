//
//  AppConfig.swift
//  TaskSteps
//
//  環境変数を管理するための設定クラス
//

import Foundation

enum AppConfig {
    // AdMob設定
    static var adMobAppId: String {
        guard let appId = Bundle.main.object(forInfoDictionaryKey: "GADApplicationIdentifier") as? String else {
            fatalError("GADApplicationIdentifier not found in Info.plist")
        }
        return appId
    }
    
    static var adMobRewardedAdUnitId: String {
        guard let adUnitId = Bundle.main.object(forInfoDictionaryKey: "AdMobRewardedAdUnitId") as? String else {
            #if DEBUG
            // デバッグ時はテスト用IDを使用
            return "ca-app-pub-3940256099942544/1712485313"
            #else
            fatalError("AdMobRewardedAdUnitId not found in Info.plist")
            #endif
        }
        return adUnitId
    }
    
    // Firebase Functions設定
    static var firebaseFunctionsUrl: String {
        guard let url = Bundle.main.object(forInfoDictionaryKey: "FirebaseFunctionsURL") as? String else {
            return "https://us-central1-stepbystep-8a395.cloudfunctions.net"
        }
        return url
    }
    
    // API環境設定
    static var apiEnvironment: String {
        guard let env = Bundle.main.object(forInfoDictionaryKey: "APIEnvironment") as? String else {
            return "production"
        }
        return env
    }
    
    // RevenueCat設定
    static var revenueCatApiKey: String {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "RevenueCatAPIKey") as? String else {
            #if DEBUG
            // デバッグ時はテスト用キーを使用（実際のキーに置き換えてください）
            return "appl_XXXXXXXXXXXXXXXXXXXXXXXXXX"
            #else
            fatalError("RevenueCatAPIKey not found in Info.plist")
            #endif
        }
        return key
    }
}