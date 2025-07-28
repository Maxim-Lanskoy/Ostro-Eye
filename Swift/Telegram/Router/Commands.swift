//
//  Commands.swift
//  Ostro-Eye
//
//  Created by Maxim Lanskoy on 13.06.2025.
//

import Foundation
@preconcurrency import SwiftTelegramSdk

enum Commands: String, Codable, CaseIterable {
    
    case start  = "start"
    case cancel = "cancel"
    case back   = "back"
    case exit   = "exit"
    case settings = "settings"
    
    var button: TGKeyboardButton {
        return button(for: nil)
    }
    
    func button(for session: User? = nil) -> TGKeyboardButton {
        switch self {
        case .start:
            return TGKeyboardButton(text: "🎬 Розпочати")
        case .cancel:
            return TGKeyboardButton(text: "🙅‍♂️ Скасувати")
        case .exit:
            return TGKeyboardButton(text: "🚪 Вийти")
        case .settings:
            return TGKeyboardButton(text: "⚙️ Налаштування")
        case .back:
            return TGKeyboardButton(text: "🔙 Назад")
        }
    }
        
    func command() -> String {
        return self.rawValue
    }
}
