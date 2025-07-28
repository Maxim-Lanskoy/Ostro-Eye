//
//  RegistrationController.swift
//  TGBotSwiftTemplate
//
//  Created by Maxim Lanskoy on 13.06.2025.
//

import Foundation
import LingoVapor
import Lingo
@preconcurrency import SwiftTelegramSdk

// MARK: - Registrarion Controller Logic
final class Registration: TGControllerBase, @unchecked Sendable {
    typealias T = Registration
        
    // MARK: - Controller Lifecycle
    override public func attachHandlers(to bot: TGBot, lingo: Lingo) async {
        let router = Router(bot: bot) { router in
            router[Commands.start.command()]     = onStart
            router.unmatched                     = unmatched
            router[.callback_query(data: nil)]   = Registration.onCallbackQuery
        }
        await processRouterForEachName(router)
    }
    
    public func onStart(context: Context) async throws -> Bool {
        var greeting = "👋 Welcome to TGBotSwiftTemplate bot!\n"
        var inlineKeyboard: [[TGInlineKeyboardButton]] = []
        for locale in allSupportedLocales {
            greeting.append("\n- \(context.lingo.localize("registration", locale: locale))")
            let flag: String
            switch locale {
            case "en": flag = "🇬🇧"
            case "ru-UA": flag = "🇺🇦"
            default: flag = "🏳️"
            }
            let langName = context.lingo.localize("lang.name", locale: locale)
            let button = TGInlineKeyboardButton(text: "\(flag) \(langName)", callbackData: "set_lang:\(locale)")
            inlineKeyboard.append([button])
        }
        let markup = TGReplyMarkup.inlineKeyboardMarkup(TGInlineKeyboardMarkup(inlineKeyboard: inlineKeyboard))
        try await context.bot.sendMessage(session: context.session, text: greeting, parseMode: .html, replyMarkup: markup)
        return true
    }
        
    private func onCancel(context: Context) async throws -> Bool {
        return try await onStart(context: context)
    }
    
    override func unmatched(context: Context) async throws -> Bool {
        return try await onStart(context: context)
    }
    
    override public func generateControllerKB(session: User, lingo: Lingo) -> TGReplyMarkup? {
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
        guard let data = query.data, data.starts(with: "set_lang:") else { return false }
        let locale = data.replacingOccurrences(of: "set_lang:", with: "")
        let mainController = Controllers.mainController
        context.session.locale = locale
        context.session.routerName = mainController.routerName
        try await context.session.save(on: context.db)
        try await mainController.showMainMenu(context: context)
        return true
    }
}
