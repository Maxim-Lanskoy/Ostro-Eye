//
//  configure.swift
//  Ostro-Eye
//
//  Created by Maxim Lanskoy on 13.06.2025.
//

import FluentSQLiteDriver
import Vapor
import SwiftDotenv
@preconcurrency import SwiftTelegramSdk

let store = RouterStore()

let owner: Int64          = 327887608
let superAdmins: [Int64]  = [owner]

// MARK: - Setting up Vapor Application.
public func configure(_ app: Application) async throws {

    let projectPath: String = "/home/rpi5/Ostro-Eye"
    app.directory = DirectoryConfiguration(workingDirectory: projectPath)
    try Dotenv.configure(atPath: "\(projectPath)/.env", overwrite: false)
    
    // MARK: - Vapor.
    
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    app.databases.use(DatabaseConfigurationFactory.sqlite(.file("\(projectPath)/SQLite/Ostro-EyeDB.sqlite")), as: .sqlite)
    // app.databases.use(.sqlite(.memory), as: .sqlite)

    app.migrations.add(CreateUser())
    
    try await app.autoMigrate()
    
    // MARK: - Telegram.
    
    let botActor: TGBotActor = .init()
    let tgApi: String = try Env.get("TELEGRAM_BOT_TOKEN")

    // Setting the level of debug
    app.logger.logLevel = .info
    let bot: TGBot = try await .init(connectionType: .longpolling(limit: nil, timeout: nil, allowedUpdates: nil),
                                     dispatcher: nil, tgClient: VaporTGClient(client: app.client),
                                     tgURI: TGBot.standardTGURL, botId: tgApi, log: app.logger)
    await botActor.setBot(bot)
    
    await EverywhereController.addHandlers(bot: botActor.bot, app: app)
    
    await botActor.bot.dispatcher.add(TGBaseHandler({ update in
        let unsafeMessage = update.editedMessage?.from ?? update.message?.from
        guard let entity = unsafeMessage ?? update.callbackQuery?.from else { return }
        let session = try await User.session(for: entity, db: app.db)
        let unsafeChat = update.editedMessage?.chat.id ?? update.message?.chat.id
        guard let chatId = unsafeChat, chatId == entity.id else { return }
        let props: [String: User] = ["session": session]
        let key = session.routerName
        let db = app.db
        _ = try await store.process(key: key, update: update, properties: props, db: db)
    }))
    
    await Controllers.attachAllHandlers(for: bot)
    
    try await botActor.bot.start()

    // MARK: - Finish configuration
    
    try routes(app)
    
    // MARK: - Notify admins about starting bot
    for user in superAdmins {
        let chatId = TGChatId.chat(user)
        let text = "📟 Bot started."
        let messageToSend = TGSendMessageParams(chatId: chatId, text: text, disableNotification: true)
        if let sentMessage = try? await botActor.bot.sendMessage(params: messageToSend) {
            try? await Task.sleep(for: .seconds(5))
            let deleteParams = TGDeleteMessageParams(chatId: chatId, messageId: sentMessage.messageId)
            _ = try? await botActor.bot.deleteMessage(params: deleteParams)
        }
    }
}
