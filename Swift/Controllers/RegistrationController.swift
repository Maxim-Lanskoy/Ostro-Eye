//
//  RegistrationController.swift
//  Ostro-Eye
//
//  Created by Maxim Lanskoy on 13.06.2025.
//

import Foundation
@preconcurrency import SwiftTelegramSdk

// MARK: - Registrarion Controller Logic
final class Registration: TGControllerBase, @unchecked Sendable {
    typealias T = Registration
        
    // MARK: - Controller Lifecycle
    override public func attachHandlers(to bot: TGBot) async {
        let router = Router(bot: bot) { router in
            router[Commands.start.command()]     = onStart
            router.unmatched                     = unmatched
            router[.callback_query(data: nil)]   = Registration.onCallbackQuery
        }
        await processRouterForEachName(router)
    }
    
    public func onStart(context: Context) async throws -> Bool {
        guard let message = context.update.message else { return false }
        let chatId = TGChatId.chat(message.chat.id)
        let deleteParams = TGDeleteMessageParams(chatId: chatId, messageId: message.messageId)
        try await context.bot.deleteMessage(params: deleteParams)
        let mainController = Controllers.mainController
        context.session.routerName = mainController.routerName
        try await context.session.save(on: context.db)
        try await mainController.showMainMenu(context: context)
        return true
    }
        
    private func onCancel(context: Context) async throws -> Bool {
        return try await onStart(context: context)
    }
    
    override func unmatched(context: Context) async throws -> Bool {
        return try await onStart(context: context)
    }
    
    override public func generateControllerKB(session: User) -> TGReplyMarkup? {
        return TGReplyMarkup.replyKeyboardRemove(TGReplyKeyboardRemove(removeKeyboard: true))
    }
}

// MARK: - Callback Queries Processing
extension Registration {
    static func onCallbackQuery(context: Context) async throws -> Bool {
        guard let query = context.update.callbackQuery else { return false }
        guard let message = query.message else { return false }
        let chatId = TGChatId.chat(message.chat.id)
        let deleteParams = TGDeleteMessageParams(chatId: chatId, messageId: message.messageId)
        try await context.bot.deleteMessage(params: deleteParams)
        context.session.routerName = Controllers.mainController.routerName
        try await context.session.save(on: context.db)
        try await Controllers.mainController.showMainMenu(context: context)
        return true
    }
}
