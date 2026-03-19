<div align="center">

# 📡 Crisis Mesh Messenger

**Infrastructure-Free Decentralized Communications**

*Децентрализованный мессенджер для экстренных ситуаций, не требующий инфраструктуры связи (в стиле Meshtastic).*

<p>
  <a href="#-технологии">
    <img src="https://img.shields.io/badge/Tech-Flutter_&_Dart-02569B?style=for-the-badge&logo=flutter" alt="Technology">
  </a>
  <a href="https://github.com/coolmag/meshtresh/actions" target="_blank">
    <img src="https://img.shields.io/badge/Build-Codemagic-brightgreen?style=for-the-badge&logo=codemagic" alt="Codemagic Build">
  </a>
  <a href="https://github.com/coolmag/meshtresh" target="_blank">
    <img src="https://img.shields.io/badge/Platform-iOS_&_Android-blue?style=for-the-badge&logo=apple" alt="Platforms">
  </a>
</p>

**[🚀 Скачать для Android / iOS](https://github.com/coolmag/meshtresh/actions)**

</div>

---

**Crisis Mesh Messenger** — это спасательный круг, когда традиционная инфраструктура (интернет, сотовые вышки) выходит из строя из-за стихийных бедствий, военных конфликтов или блокировок. Сообщения, фото и координаты передаются напрямую от устройства к устройству по Bluetooth и WiFi Direct.

## 🧬 Ключевые возможности

| Функция | Описание |
| :--- | :--- |
| 🛜 **P2P Mesh Network** | Не нужен интернет и сотовая связь. Прямое подключение и прыжки через другие устройства (Mesh Hops). |
| 📟 **Retro Terminal UI** | Черно-зеленый терминальный стиль для максимальной читаемости и минимализма. |
| 🆘 **Emergency SOS** | Система экстренных оповещений с градацией по типам (Медицина, Заблокирован, Опасность). |
| 📷 **Geo & Photo Share** | Отправка геолокации в один клик и фото с автоматическим жестким сжатием для узких каналов. |
| 🔋 **Survival Mode** | Эко-режим для жесткой экономии батареи и кнопка полного уничтожения данных (Burn After Read). |

## 🛠️ Технологии

- **Framework**: `Flutter 3.29+` (Dart)
- **Networking**: `flutter_nearby_connections` (Google Nearby Connections API, Bluetooth LE, WiFi Direct)
- **Data Storage**: `Hive` (локальная NoSQL база)
- **State Management**: `Provider` + `GetIt` (MVVM)
- **Infrastructure**: `Codemagic CI/CD` (автоматическая сборка `.ipa` с обходом подписей Apple для Sideloadly)

## 🗂️ Репозитории проекта

Проект разделен на ветки для удобства разработки:
1. **[Основной репозиторий (Hospicjum)](https://github.com/FundacjaHospicjum/crisis-mesh-messenger)** — Базовый код гуманитарного фонда.
2. **[Ветка с новыми фичами (Meshtresh)](https://github.com/coolmag/meshtresh)** — Текущая ветка со всеми ретро-интерфейсами, русской локализацией, фото, геолокациями, SOS и CI/CD.

## 💖 Поддержать проект

Проект разрабатывается силами энтузиастов. Ваша поддержка помогает развивать приложение, добавлять шифрование, фоновую работу на iOS и оплачивать ресурсы для тестирования.

<div align="center">

**[>> 🚀 Отправить донат через DonatePay <<](https://donatepay.ru/don/1480259)**

**[>> 🔔 Оповещения о донатах <<](https://widget.donatepay.ru/alert-box/widget/11cbd6bc2d99c42feb866fa80432f47569a4c632d42ec8b10fb2bda4b694f8f4)**

</div>

---

## 🚀 Быстрый старт (Сборка)

1.  **Клонировать репозиторий:**
    ```bash
    git clone https://github.com/coolmag/meshtresh.git
    cd meshtresh
    ```
2.  **Установить зависимости:**
    ```bash
    flutter pub get
    ```
3.  **Собрать проект:**
    - **Для Android (.apk):** `flutter build apk --release`
    - **Для iOS (.ipa):** В репозитории лежит готовый `codemagic.yaml` с инъекциями макросов для обхода системы подписей Apple. Подключите репозиторий к Codemagic, и он выдаст `.ipa` файл, готовый к установке через Sideloadly (режим Normal Install).

> **Лицензия:** MIT License — Бесплатно для гуманитарного использования.