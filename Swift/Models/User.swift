//
//  User.swift
//  Ostro-Eye
//
//  Created by Maxim Lanskoy on 13.06.2025.
//

import Vapor
import Fluent
import Foundation
@preconcurrency import SwiftTelegramSdk

/// Property wrappers interact poorly with `Sendable` checking, causing a warning for the `@ID` property
/// It is recommended you write your model with sendability checking on and then suppress the warning
/// afterwards with `@unchecked Sendable`.
final public class User: Model, @unchecked Sendable {
    public static let schema = "users"

    @ID(key: .id)
    public var id: UUID?

    @Field(key: "telegram_id")
    var telegramId: Int64

    @Field(key: "router_name")
    var routerName: String

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Field(key: "user_name")
    var userName: String?
    
    @Field(key: "first_name")
    var firstName: String?
    
    @Field(key: "last_name")
    var lastName: String?
    
    @Field(key: "profiles")
    var profiles: [Profile]
                
    var name: String {
        if let firstName = firstName, let lastName = lastName {
            return "\(firstName) \(lastName)"
        } else if let firstName = firstName {
            return firstName
        } else if let lastName = lastName {
            return lastName
        } else if let userName = userName {
            return userName
        } else {
            return "🧑‍💻 User"
        }
    }

    public init() {}

    init(id: UUID? = nil, telegramId: Int64, userName: String? = nil, firstName: String? = nil, lastName: String? = nil) {
        self.id = id
        self.telegramId = telegramId
        self.routerName = "registration"
        self.userName   = userName
        self.firstName  = firstName
        self.lastName   = lastName
        self.createdAt  = Date()
        self.profiles   = []
    }
    
    typealias ProfileTyple = (profile: Profile?, error: String?)
    
    func updateProfile(from message: String, date: Date, db: any Database) async throws -> ProfileTyple {
        if let profile = Profile(from: message, timestamp: date) {
            if self.profiles.contains(where: {$0 == profile}) {
                return (nil, "⚠️ Такий профіль вже збережено.")
            }
            self.profiles.append(profile)
            if self.profiles.count > 100 {
                self.profiles = Array(self.profiles.suffix(100))
            }
            try await self.update(on: db)
            return (profile, nil)
        } else {
            return (nil, nil)
        }
    }
    
    static func session(for tgUser: TGUser, locale: String = "en", db: any Database) async throws -> User {
        if let found = try await User.query(on: db).filter(\.$telegramId, .equal, tgUser.id).first() {
            return try await updateIfNeeded(for: found, with: tgUser, db: db)
        } else {
            let newUser = User(telegramId: tgUser.id, userName: tgUser.username, firstName: tgUser.firstName, lastName: tgUser.lastName)
            try await newUser.save(on: db)
            return newUser
        }
    }
    
    static func updateIfNeeded(for user: User, with tgUser: TGUser, db: any Database) async throws -> User {
        var updated = false
        if user.userName != tgUser.username {
            user.userName = tgUser.username
            updated = true
        }
        if user.firstName != tgUser.firstName {
            user.firstName = tgUser.firstName
            updated = true
        }
        if user.lastName != tgUser.lastName {
            user.lastName = tgUser.lastName
            updated = true
        }
        if updated {
            try await user.update(on: db)
        }
        return user
    }
}
