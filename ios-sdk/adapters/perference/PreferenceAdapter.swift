//
//  PreferenceAdapter.swift
//  consolebus-ios-sdk
//
//  Created by PonyCui on 2025/1/31.
//

import Foundation

open class PreferenceAdapter {
    static var currentPreferenceAdapter: PreferenceAdapter?
    open func getAll() {}
    open func setValue(key: String, value: Any) {}
}
