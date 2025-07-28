//
//  EverywhereController.swift
//  Ostro-Eye
//
//  Created by Maxim Lanskoy on 13.06.2025.
//

import Vapor
@preconcurrency import SwiftTelegramSdk

final class EverywhereController {

    static func addHandlers(bot: TGBot, app: Application) async {
        await tryToParseProfile(bot: bot, app: app)
        await showHelpHandler(bot: bot, app: app)

        // TODO: - Deprecate later.
        // await defaultBaseHandler(bot: bot)
        // await commandPingHandler(bot: bot)
        // await commandShowButtonsHandler(bot: bot)
        // await buttonsActionHandler(bot: bot)
    }
    
    private static func tryToParseProfile(bot: TGBot, app: Application) async {
        await bot.dispatcher.add(TGBaseHandler({ update in
            let unsafeMessage = update.message ?? update.editedMessage
            guard let message = unsafeMessage, let text = message.text, let fromId = unsafeMessage?.from else { return }
            guard let chatId = update.editedMessage?.chat ?? update.message?.chat else { return }
            let session = try await User.session(for: fromId, db: app.db)
            let containsEnergy = text.contains("🔋")
            let containsHealth = text.contains("❤️")
            let seemsProfile = containsEnergy && containsHealth
            if text.starts(with: "⚔️") && seemsProfile {
                let stamp = Date(timeIntervalSince1970: TimeInterval(message.date))
                let adjustedStamp = Calendar.current.date(byAdding: .hour, value: 3, to: stamp) ?? stamp
                let lastProfileUnsafe = session.profiles.last
                let tuple = try await session.updateProfile(from: text, date: adjustedStamp, db: app.db)
                guard let newProfile = tuple.profile else {
                    let error = tuple.error ?? "❌ Помилка при оновленні профілю. Перевірте формат."
                    try await bot.sendMessage(chat: chatId, text: error, parseMode: .html)
                    return
                }
                if let lastProfile = lastProfileUnsafe {
                    let compare = Profile.compareProfiles(old: lastProfile, new: newProfile)
                    try await bot.sendMessage(chat: chatId, text: compare, parseMode: .html)
                } else {
                    try await bot.sendMessage(chat: chatId, text: "🙌 Профіль збережено!", parseMode: .html)
                }
            }
        }))
    }
        
    private static func showHelpHandler(bot: TGBot, app: Application) async {
        await bot.dispatcher.add(TGCommandHandler(commands: ["/help"]) { update in
            // let unsafeMessage = update.message?.from ?? update.editedMessage?.from
            // guard let fromId = unsafeMessage else {return }
            guard let chatId = update.editedMessage?.chat ?? update.message?.chat else { return }
            // let session = try await User.session(for: fromId, db: app.db)
            let helpText = """
            👁️ <b>Як користуватись:</b>
            • Надішліть ігровий профіль, щоб зберігти.
            • Надішліть профіль ще раз, щоб порівняти.
            """
            try await bot.sendMessage(chat: chatId, text: helpText, parseMode: .html)
        })
    }

    private static func defaultBaseHandler(bot: TGBot) async {
        await bot.dispatcher.add(TGBaseHandler({ update in
            guard let message = update.message else { return }
            let params: TGSendMessageParams = .init(chatId: .chat(message.chat.id), text: "TGBaseHandler")
            try await bot.sendMessage(params: params)
        }))
    }

    private static func commandPingHandler(bot: TGBot) async {
        await bot.dispatcher.add(TGCommandHandler(commands: ["/ping"]) { update in
            try await update.message?.reply(text: "pong", bot: bot)
        })
    }

    private static func commandShowButtonsHandler(bot: TGBot) async {
        await bot.dispatcher.add(TGCommandHandler(commands: ["/show_buttons"]) { update in
            guard let userId = update.message?.from?.id else { fatalError("user id not found") }
            let buttons: [[TGInlineKeyboardButton]] = [
                [.init(text: "Button 1", callbackData: "press 1"), .init(text: "Button 2", callbackData: "press 2")]
            ]
            let keyboard: TGInlineKeyboardMarkup = .init(inlineKeyboard: buttons)
            let params: TGSendMessageParams = .init(chatId: .chat(userId),
                                                    text: "Keyboard active",
                                                    replyMarkup: .inlineKeyboardMarkup(keyboard))
            try await bot.sendMessage(params: params)
        })
    }

    private static func buttonsActionHandler(bot: TGBot) async {
        await bot.dispatcher.add(TGCallbackQueryHandler(pattern: "press 1") { update in
            bot.log.info("press 1")
            guard let userId = update.callbackQuery?.from.id else { fatalError("user id not found") }
            let params: TGAnswerCallbackQueryParams = .init(callbackQueryId: update.callbackQuery?.id ?? "0",
                                                            text: update.callbackQuery?.data  ?? "data not exist",
                                                            showAlert: nil,
                                                            url: nil,
                                                            cacheTime: nil)
            try await bot.answerCallbackQuery(params: params)
            try await bot.sendMessage(params: .init(chatId: .chat(userId), text: "press 1"))
        })
        
        await bot.dispatcher.add(TGCallbackQueryHandler(pattern: "press 2") { update in
            bot.log.info("press 2")
            guard let userId = update.callbackQuery?.from.id else { fatalError("user id not found") }
            let params: TGAnswerCallbackQueryParams = .init(callbackQueryId: update.callbackQuery?.id ?? "0",
                                                            text: update.callbackQuery?.data  ?? "data not exist",
                                                            showAlert: nil,
                                                            url: nil,
                                                            cacheTime: nil)
            try await bot.answerCallbackQuery(params: params)
            try await bot.sendMessage(params: .init(chatId: .chat(userId), text: "press 2"))
        })
    }
}
