//
//  SettingsController.swift
//  Ostro-Eye
//
//  Created by Maxim Lanskoy on 13.06.2025.
//

import Foundation
@preconcurrency import SwiftTelegramSdk

// MARK: - Settings Controller Logic
final class SettingsController: TGControllerBase, @unchecked Sendable {
    typealias T = SettingsController
    
    // MARK: - Controller Lifecycle
    override public func attachHandlers(to bot: TGBot) async {
        let router = Router(bot: bot) { router in
            router[Commands.start.command()]      = onStart
            router[Commands.cancel.button.text]   = onCancel
            router[Commands.back.button.text]     = onCancel
            router[Commands.settings.button.text] = onSettingsMenu
            router.unmatched = unmatched
            router[.callback_query(data: nil)] = SettingsController.onCallbackQuery
        }
        await processRouterForEachName(router)
    }
    
    public func onStart(context: Context) async throws -> Bool {
        let mainController = Controllers.mainController
        try await mainController.showMainMenu(context: context)
        context.session.routerName = mainController.routerName
        try await context.session.save(on: context.db)
        return true
    }
    
    private func onCancel(context: Context) async throws -> Bool {
        return try await onStart(context: context)
    }
    
    override func unmatched(context: Context) async throws -> Bool {
        guard try await super.unmatched(context: context) else { return false }
        return try await onStart(context: context)
    }
                
    private func onSettingsMenu(context: Context) async throws -> Bool {
        try await showSettingsMenu(context: context)
        return true
    }
    
    public func showSettingsMenu(context: Context, text: String? = nil) async throws {
        try await showSettingsMenuLogic(bot: context.bot, session: context.session, text: text)
    }
    
    public func showSettingsMenuLogic(bot: TGBot, session: User, text: String? = nil) async throws {
        let text = text ?? "⚙️ Налаштування"
        let markup = generateControllerKB(session: session)
        try await bot.sendMessage(session: session, text: text, parseMode: .html, replyMarkup: markup)
    }
    
    override public func generateControllerKB(session: User) -> TGReplyMarkup? {
        let markup = TGReplyKeyboardMarkup(keyboard: [[
            Commands.back.button(for: session)
        ]], resizeKeyboard: true)
        return TGReplyMarkup.replyKeyboardMarkup(markup)
    }
    
    // MARK: - Custom Methods
}
 
// MARK: - Callback Queries Processing
extension SettingsController {
    static func onCallbackQuery(context: Context) async throws -> Bool {
        guard let query = context.update.callbackQuery else { return false }
        guard let message = query.message else { return false }
        let chatId = TGChatId.chat(message.chat.id)
        let deleteParams = TGDeleteMessageParams(chatId: chatId, messageId: message.messageId)
        try await context.bot.deleteMessage(params: deleteParams)
        try await Controllers.settingsController.showSettingsMenu(context: context)
        return true
    }
} 
