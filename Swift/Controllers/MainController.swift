//
//  MainController.swift
//  Ostro-Eye
//
//  Created by Maxim Lanskoy on 13.06.2025.
//

import Foundation
@preconcurrency import SwiftTelegramSdk

// MARK: - Main Controller Logic
final class MainController: TGControllerBase, @unchecked Sendable {
    typealias T = MainController
        
    // MARK: - Controller Lifecycle
    override public func attachHandlers(to bot: TGBot) async {
        let router = Router(bot: bot) { router in
            router[Commands.start.command()]      = onStart
            router[Commands.settings.command()]   = onSettings
            router[Commands.cancel.button.text]   = onCancel
            router[Commands.back.button.text]     = onCancel
            router[Commands.settings.button.text] = onSettings
            router.unmatched                      = unmatched
            router[.callback_query(data: nil)]    = MainController.onCallbackQuery
        }
        await processRouterForEachName(router)
    }
    
    public func onStart(context: Context) async throws -> Bool {
        try await showMainMenu(context: context)
        return true
    }
        
    private func onCancel(context: Context) async throws -> Bool {
        return try await onStart(context: context)
    }
    
    override func unmatched(context: Context) async throws -> Bool {
        guard try await super.unmatched(context: context) else { return false }
        return try await onStart(context: context)
    }
        
    private func onSettings(context: Context) async throws -> Bool {
        let settingsController = Controllers.settingsController
        try await settingsController.showSettingsMenu(context: context)
        context.session.routerName = settingsController.routerName
        try await context.session.save(on: context.db)
        return true
    }
                
    public func showMainMenu(context: Context, text: String? = nil) async throws {
        let text = text ??  """
        👋 Вітаю у боті Ostro-Eye!
        Надішліть мені профіль із гри, щоб я його зберіг.
        Надішліть мені профіль ще раз, щоб я їх порівняв.
        """
        let markup = generateControllerKB(session: context.session)
        try await context.bot.sendMessage(session: context.session, text: text, parseMode: .html, replyMarkup: markup)
    }
    
    override public func generateControllerKB(session: User) -> TGReplyMarkup? {
        //let markup = TGReplyKeyboardMarkup(keyboard: [
        //    [ Commands.settings.button(for: session) ]
        //], resizeKeyboard: true)
        //return TGReplyMarkup.replyKeyboardMarkup(markup)
        let markup = TGReplyKeyboardRemove(removeKeyboard: true)
        return TGReplyMarkup.replyKeyboardRemove(markup)
    }
    
    // MARK: - Custom Methods
}

// MARK: - Callback Queries Processing
extension MainController {
    static func onCallbackQuery(context: Context) async throws -> Bool {
        guard let query = context.update.callbackQuery else { return false }
        guard let message = query.message else { return false }
        let chatId = TGChatId.chat(message.chat.id)
        let deleteParams = TGDeleteMessageParams(chatId: chatId, messageId: message.messageId)
        try await context.bot.deleteMessage(params: deleteParams)
        return true
    }
}
