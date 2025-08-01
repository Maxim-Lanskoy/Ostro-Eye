//
//  AllControllers.swift
//  Ostro-Eye
//
//  Created by Maxim Lanskoy on 13.06.2025.
//

import Foundation
@preconcurrency import SwiftTelegramSdk

struct Controllers {
    // MARK: - Controllers initialization.
    static let registration       = Registration      (routerName: "registration")
    static let mainController     = MainController    (routerName: "main" )
    static let settingsController = SettingsController(routerName: "settings")
    
    static let all: [TGControllerBase] = [ registration, mainController, settingsController ]
    
    static func attachAllHandlers(for bot: TGBot) async {
        for controller in all {
            await controller.attachHandlers(to: bot)
        }
    }
}
