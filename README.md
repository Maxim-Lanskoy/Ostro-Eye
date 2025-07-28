# Ostromag Eye Bot 👁️

[![Build Status](https://img.shields.io/badge/Build-Passing-brightgreen)](https://github.com/Maxim-Lanskoy/OstromagEyeBot/actions)
[![Swift](https://img.shields.io/badge/Swift-6.1-orange)](https://github.com/swiftlang/swift/releases/tag/swift-6.1-RELEASE)
[![Vapor](https://img.shields.io/badge/Vapor-4.115.0-mediumslateblue)](https://github.com/vapor/vapor/releases/tag/4.115.0)

A Telegram Bot for **Ostromag**, a Ukrainian-inspired text-based RPG. This bot allows players to compare progress, track development, and view visualized player stats through a structured and persistent state-based interaction.

<p align="center">[ <a href="https://docs.vapor.codes">Vapor Documentation</a> ]  
  [ <a href="https://docs.vapor.codes/fluent/overview/#fluent">Fluent ORM / SQLite</a> ]  
  [ <a href="https://core.telegram.org/bots/api">Telegram Bot API</a> ]  
  [ <a href="https://github.com/nerzh/swift-telegram-sdk">Swift Telegram SDK</a> ]  
</p>

## 🌟 Purpose

**Ostromag Eye** is a specialized Telegram bot built for:

* Comparing RPG player profiles visually and textually
* Persistently tracking progress
* Delivering personalized RPG statistics over time

Built using modern Swift, actor-based concurrency, and a clean architecture designed for extensibility.

## 🏐 Architecture Overview

```
┌────────────────────────────┐
│      OstromagEyeActor      │
│ Telegram bot core actor    │
└────────────────────────────┘
           │
           ▼
┌────────────────────────────┐
│        Router System       │
└────────────────────────────┘
           │
   ┌───────┴────────┐
   ▼                ▼
Controllers      User Sessions
(Stats UI)       (Progress data)
```

Controllers are assigned to specific parts of the RPG experience (profile overview, progress updates, comparison leaderboard, etc.).

## 📁 Structure

```
OstromagEyeBot/
├── Swift/
│   ├── Controllers/              # Main interaction points
│   │   ├── ....swift
│   │   ├── ....swift
│   │   ├── ....swift
│   │   └── EverywhereController.swift
│   │
│   ├── Models/
│   │   └── User.swift           # User metadata, progress, locale
│   ├── Telegram/
│   │   ├── Router/
│   │   │   ├── Router.swift
│   │   │   ├── Context.swift
│   │   │   └── Commands.swift
│   │   └── TGBot/
│   │       └── ....swift
│   ├── Migrations/
│   ├── Helpers/
│   ├── entrypoint.swift
│   ├── configure.swift
│   └── routes.swift
├── SQLite/
├── Package.swift
├── .env.example
└── .gitignore
```

## 🚀 Getting Started

### Prerequisites

* Swift 6.1+
* Telegram Bot Token from [@BotFather](https://t.me/botfather)

### Setup

```bash
git clone https://github.com/Maxim-Lanskoy/OstromagEyeBot.git
cd OstromagEyeBot
cp .env.example .env
# Fill TELEGRAM_BOT_TOKEN= in .env
```

### Run

```bash
swift build
swift run
```

Or with Vapor CLI:

```bash
vapor build
vapor run
```

## 🌎 Features

* **Player Stats Controller**: Sends visual summary of user's progress
* **Compare Controller**: Shows progress changes over time
* **Global Commands**: `/help`, `/profile`
* **Database-Backed**: Player data and profiles saved across sessions

## 📆 Dependencies

* Vapor 4
* Fluent SQLite
* SwiftTelegramSDK

---

Built for **Ostromag**. Powered by Swift. Honoring Ukrainian culture through tech and storytelling.
