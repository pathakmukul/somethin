import Foundation
import MessageUI
import Messages
import Photos
import MediaPlayer
import SafariServices
import EventKit
import Contacts
import Intents
import IntentsUI

class SystemServicesManager: NSObject, ObservableObject {
    static let shared = SystemServicesManager()
    
    @Published var serviceStatus: [String: Bool] = [:]
    @Published var lastActionResult: String = ""
    
    private let eventStore = EKEventStore()
    private let contactStore = CNContactStore()
    
    override init() {
        super.init()
        checkPermissions()
    }
    
    func checkPermissions() {
        checkPhotoLibraryAccess()
        checkContactsAccess()
        checkCalendarAccess()
        checkRemindersAccess()
        checkMusicLibraryAccess()
    }
    
    private func checkPhotoLibraryAccess() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        serviceStatus["photos"] = (status == .authorized || status == .limited)
    }
    
    private func checkContactsAccess() {
        let status = CNContactStore.authorizationStatus(for: .contacts)
        serviceStatus["contacts"] = (status == .authorized)
    }
    
    private func checkCalendarAccess() {
        if #available(iOS 17.0, *) {
            let status = EKEventStore.authorizationStatus(for: .event)
            serviceStatus["calendar"] = (status == .fullAccess || status == .writeOnly)
        } else {
            let status = EKEventStore.authorizationStatus(for: .event)
            serviceStatus["calendar"] = (status == .authorized)
        }
    }
    
    private func checkRemindersAccess() {
        if #available(iOS 17.0, *) {
            let status = EKEventStore.authorizationStatus(for: .reminder)
            serviceStatus["reminders"] = (status == .fullAccess)
        } else {
            let status = EKEventStore.authorizationStatus(for: .reminder)
            serviceStatus["reminders"] = (status == .authorized)
        }
    }
    
    private func checkMusicLibraryAccess() {
        let status = MPMediaLibrary.authorizationStatus()
        serviceStatus["music"] = (status == .authorized)
    }
    
    func requestPhotoLibraryAccess(completion: @escaping (Bool) -> Void) {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            DispatchQueue.main.async {
                let granted = (status == .authorized || status == .limited)
                self.serviceStatus["photos"] = granted
                completion(granted)
            }
        }
    }
    
    func requestContactsAccess(completion: @escaping (Bool) -> Void) {
        contactStore.requestAccess(for: .contacts) { granted, error in
            DispatchQueue.main.async {
                self.serviceStatus["contacts"] = granted
                completion(granted)
            }
        }
    }
    
    func requestCalendarAccess(completion: @escaping (Bool) -> Void) {
        if #available(iOS 17.0, *) {
            eventStore.requestFullAccessToEvents { granted, error in
                DispatchQueue.main.async {
                    self.serviceStatus["calendar"] = granted
                    completion(granted)
                }
            }
        } else {
            eventStore.requestAccess(to: .event) { granted, error in
                DispatchQueue.main.async {
                    self.serviceStatus["calendar"] = granted
                    completion(granted)
                }
            }
        }
    }
    
    func requestRemindersAccess(completion: @escaping (Bool) -> Void) {
        if #available(iOS 17.0, *) {
            eventStore.requestFullAccessToReminders { granted, error in
                DispatchQueue.main.async {
                    self.serviceStatus["reminders"] = granted
                    completion(granted)
                }
            }
        } else {
            eventStore.requestAccess(to: .reminder) { granted, error in
                DispatchQueue.main.async {
                    self.serviceStatus["reminders"] = granted
                    completion(granted)
                }
            }
        }
    }
    
    func requestMusicLibraryAccess(completion: @escaping (Bool) -> Void) {
        MPMediaLibrary.requestAuthorization { status in
            DispatchQueue.main.async {
                let granted = (status == .authorized)
                self.serviceStatus["music"] = granted
                completion(granted)
            }
        }
    }
}