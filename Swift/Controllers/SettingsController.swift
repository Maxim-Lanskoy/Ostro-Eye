//
//  SettingsController.swift
//  TGBotSwiftTemplate
//
//  Created by Maxim Lanskoy on 13.06.2025.
//

import Foundation
import Lingo
@preconcurrency import SwiftTelegramSdk

// MARK: - Settings Controller Logic
final class SettingsController: TGControllerBase, @unchecked Sendable {
    typealias T = SettingsController
    
    // MARK: - Controller Lifecycle
    override public func attachHandlers(to bot: TGBot, lingo: Lingo) async {
        let router = Router(bot: bot) { router in
            router[Commands.start.command()]     = onStart
            router[Commands.language.command()]  = onLanguage
                        
            let languageLocales = Commands.language.buttonsForAllLocales(lingo: lingo)
            for button in languageLocales { router[button.text] = onLanguage }
            
            let cancelLocales = Commands.cancel.buttonsForAllLocales(lingo: lingo)
            for button in cancelLocales { router[button.text] = onCancel }
                        
            let settingsLocales = Commands.settings.buttonsForAllLocales(lingo: lingo)
            for button in settingsLocales { router[button.text] = onSettingsMenu }
            
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
        
    private func onLanguage(context: Context) async throws -> Bool {
        let prompt = context.lingo.localize("settings.language.prompt", locale: context.session.locale)
        var inlineKeyboard: [[TGInlineKeyboardButton]] = []
        for locale in allSupportedLocales {
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
        try await context.bot.sendMessage(session: context.session, text: prompt, parseMode: .html, replyMarkup: markup)
        return true
    }
        
    private func onSettingsMenu(context: Context) async throws -> Bool {
        try await showSettingsMenu(context: context)
        return true
    }
    
    public func showSettingsMenu(context: Context, text: String? = nil) async throws {
        try await showSettingsMenuLogic(bot: context.bot, session: context.session, lingo: context.lingo, text: text)
    }
    
    public func showSettingsMenuLogic(bot: TGBot, session: User, lingo: Lingo, text: String? = nil) async throws {
        let settings = lingo.localize("settings.title", locale: session.locale)
        let text = text ?? "⚙️ \(settings)"
        let markup = generateControllerKB(session: session, lingo: lingo)
        try await bot.sendMessage(session: session, text: text, parseMode: .html, replyMarkup: markup)
    }
    
    override public func generateControllerKB(session: User, lingo: Lingo) -> TGReplyMarkup? {
        let markup = TGReplyKeyboardMarkup(keyboard: [[
            Commands.language.button(for: session, lingo),
            Commands.cancel.button(for: session, lingo)
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
        guard let data = query.data, data.starts(with: "set_lang:") else { return false }
        let locale = data.replacingOccurrences(of: "set_lang:", with: "")
        context.session.locale = locale
        try await context.session.save(on: context.db)
        try await Controllers.settingsController.showSettingsMenu(context: context)
        return true
    }
} 
