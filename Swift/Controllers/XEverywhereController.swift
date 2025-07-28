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
            guard let message = unsafeMessage?.text, let fromId = unsafeMessage?.from else { return }
            guard let chatId = update.editedMessage?.chat ?? update.message?.chat else { return }
            let session = try await User.session(for: fromId, db: app.db)
            let containsEnergy = message.contains("🔋")
            let containsHealth = message.contains("❤️")
            let seemsProfile = containsEnergy && containsHealth
            if message.starts(with: "⚔️") && seemsProfile {
                
                try await bot.sendMessage(chat: chatId, text: "🙌 Профіль оновлено!", parseMode: .html)
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
