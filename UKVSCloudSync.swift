//
//  UKVSCloudSync.swift
//
//  Created by Doug Robison on 4/17/20.
//  Copyright © 2020 Doug Robison. All rights reserved.
//
// Orignally created by:
//  Created by Mugunth Kumar (@mugunthkumar) on 20/11/11.
//  Copyright (C) 2011-2020 by Steinlogic
//  https://github.com/MugunthKumar/MKiCloudSync
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

import Foundation

class UKVSCloudSync {
    static let kUKVSCloudSyncNotification = Notification.Name("UKVSCloudSyncDidUpdateToLatest")
    private var prefixKeys: [String] = []

    @objc func updateToiCloud(_: Notification?) {
        let dict = UserDefaults.standard.dictionaryRepresentation()

        dict.forEach { key, value in
            prefixKeys.forEach { prefix in
                if key.hasPrefix(prefix) {
                    NSUbiquitousKeyValueStore.default.set(value, forKey: key)
                }
            }
        }

        NSUbiquitousKeyValueStore.default.synchronize()
    }

    @objc func updateFromiCloud(_: Notification?) {
        let dict = NSUbiquitousKeyValueStore.default.dictionaryRepresentation

        // Previent NSUserDefaultsDidChangeNotification from being posted while we update from iCloud
        NotificationCenter.default.removeObserver(self, name: UserDefaults.didChangeNotification, object: nil)

        // Update user defaults
        dict.forEach { key, value in
            prefixKeys.forEach { prefix in
                if key.hasPrefix(prefix) {
                    UserDefaults.standard.set(value, forKey: key)
                }
            }
        }

        UserDefaults.standard.synchronize()

        // Enable NSUserDefaultsDidChangeNotification notifications again
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateToiCloud(_:)),
                                               name: UserDefaults.didChangeNotification,
                                               object: nil)

        // Signal that an update has ptoentailly happened.
        NotificationCenter.default.post(name: UKVSCloudSync.kUKVSCloudSyncNotification, object: nil)
    }

    func start(withPrefixKey prefixKeyToSync: String) {
        start(withPrefixKey: [prefixKeyToSync])
    }

    func start(withPrefixKey prefixKeysToSync: [String]) {
        prefixKeys = prefixKeysToSync

        // Check to see if the user is log into his/her cloud account. However, this still doesn't indicate if a cloud container has been set up.
        if FileManager.default.ubiquityIdentityToken != nil {
            addNotificationObservers()

            // Kickstart to get the latest iCloud data
            NSUbiquitousKeyValueStore.default.synchronize()
        } else {
            
            // Do what you want here
            fatalError("Cloud not enabled")
        }
    }

    private func addNotificationObservers() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateFromiCloud(_:)),
                                               name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateToiCloud(_:)),
                                               name: UserDefaults.didChangeNotification, object: nil)
    }

    private func removeNotificationObservers() {
        NotificationCenter.default.removeObserver(self,
                                                  name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
                                                  object: nil)
        NotificationCenter.default.removeObserver(self,
                                                  name: UserDefaults.didChangeNotification,
                                                  object: nil)
    }

    deinit {
        removeNotificationObservers()
    }
}
