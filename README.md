# 软件方案
C++ & Qt
    TCP 并发服务器：使用 Qt 的 QTcpServer，能够同时接入多个“树莓派车辆”（程序架构上支持多车同时练车，体现扩展性）。
    MVC 架构的 UI 设计：
    大屏监控界面：实时显示车辆状态（学员姓名、已练时长、当前模拟车速）。可以使用 QtCharts 画一个动态折线图，显示车速变化。
    信息管理界面：操作 SQLite 数据库，实现学员信息的录入、RFID 卡号的绑定、学时统计和查询。
    数据库设计 (SQLite)：
    Student_Table（学员表：学号、姓名、绑定的卡号、需完成总学时）
    Record_Table（打卡记录表：卡号、上车时间、下车时间、本次练习时长）
    通信协议选 TCP。TCP 是一种“面向连接”的协议。当树莓派开机连上服务端时，服务端能确切知道“1号车已上线”；如果树莓派断电或开到没有 WiFi 的地方，TCP 连接断开，服务端会立刻触发 disconnected 信号，界面上就能把这辆车标红显示“离线”。UDP 无法原生做到这一点
    多表关联（JOIN）”和“身份解析”

# DrivingSchoolServer (服务端)
    简介
    这是驾校管理中枢的服务端桌面应用，基于 C++/Qt（QML 前端 + C++ 后端），负责：
    - 接收并解析来自车载终端（树莓派）的 TCP JSON 消息；
    - 持久化学员与打卡记录（使用 SQLite，通过 `DbManager` 封装）；
    - 为 QML 界面提供应用层 API（通过 `TcpBackend` 暴露的 `Q_INVOKABLE` 方法）；
    - 提供管理界面用于监控在线设备、查看/导出记录、发卡与预约管理。

    项目定位
    - 本仓库为服务端（Server）。客户端（车载或管理移动端）位于：
      - C:\Users\vvvvvv\Desktop\Proj\GUI_CLIENT_G\README.md（独立仓库/路径）

    主要文件与位置
    - 入口与 UI: [main.qml](main.qml)
    - 服务后端实现: [tcpbackend.h](tcpbackend.h), [tcpbackend.cpp](tcpbackend.cpp)
    - 数据库封装: [dbmanager.h](dbmanager.h), [dbmanager.cpp](dbmanager.cpp)
    - QML 页面: [pages/LogPage.qml](pages/LogPage.qml), [pages/DashboardPage.qml](pages/DashboardPage.qml) 等
    - 项目文件: [DrivingSchoolServer.pro](DrivingSchoolServer.pro)

    协议概览（JSON over TCP）
    - 常见消息类型：`card`, `theory`, `heartbeat`, `issue_card`, `appointment` 等；
    - 后端要求消息以换行符 `\n` 结束，一条消息一行；
    - 为防篡改，消息携带签名字段 `sign` 与 `timestamp`；签名服务端校验逻辑见 [tcpbackend.cpp](tcpbackend.cpp) 的 `verifySignature()`：
      - 签名原文示例：`CardID + type + timestamp + subject + secretKey`，然后取 MD5；
      - secretKey 在 [tcpbackend.h](tcpbackend.h) 中有默认字符串（可在编译时或配置中修改）。

    数据库与表（概要）
    - 使用 SQLite，通过 `DbManager` 管理。常见表包括：`students`, `records`, `users`, `appointments`, `theory_scores`（名称可能略有不同，详见 `dbmanager.*`）。

    构建与运行（推荐）
    - 推荐使用 Qt Creator 打开 `DrivingSchoolServer.pro` 并运行；或使用命令行：

    ```bash
    # 在 Qt 环境下（Windows 示例，使用 MinGW）
    qmake DrivingSchoolServer.pro
    mingw32-make
    ./DrivingSchoolServer.exe
    ```

    配置与启动
    - 默认服务端口可由 UI 触发启动（代码示例在 [main.qml](main.qml) 中调用 `backend.startServer(8888)`）；
    - 如果你需要修改端口或 secretKey，请在 [tcpbackend.h](tcpbackend.h) 中更新或将其改为通过外部配置加载。

    主要运行时行为
    - 当设备连接/断开会在 UI 生成通知（`messageReceived` 信号）；
    - 收到 `card` 类型并校验通过后会写入记录并返回 `ack`；
    - `heartbeat` 用于维持在线状态；后端有定期检查定时器，会自动超时结算异常断开的会话。

    调试与日志
    - UI 内的 `系统日志` 页面由 [pages/LogPage.qml](pages/LogPage.qml) 提供；仅管理员可见（管理员判定与用户表有关，UI 中用户名为 `root` 的账号会被视作管理员）。

    已知/修复事项
    - 为避免 `LogPage` 在非激活页面发生“重影”的显示问题，推荐在 `main.qml` 中根据 `StackLayout` 的 `currentIndex` 控制 `LogPage` 的 `visible` 属性（项目中已将其改为：`visible: root.isAdmin && stack.children.indexOf(logPage) === stack.currentIndex`）。

    扩展与开发建议
    - 考虑使用 `Loader` 或 `StackView` 延迟加载较重页面以节省内存；
    - 将 `secretKey` 与可变配置移动到外部配置文件或命令行参数，避免硬编码；
    - 为生产环境提升签名到 HMAC-SHA256，并在设备端与服务端统一实现签名细节。

    ---
    （本 README 依据工程源码自动整理；如需把 README 进一步本地化为部署文档或运维手册，我可以继续补充）

## 工程结构
C:.
│  dbmanager.cpp
│  dbmanager.cpp.autosave
│  dbmanager.h
│  DrivingSchoolServer.pro
│  DrivingSchoolServer.pro.user
│  main.cpp
│  main.qml
│  qml.qrc
│  qml_helpers.js
│  README.md
│  res.qrc
│  tcpbackend.cpp
│  tcpbackend.h
│
├─.vscode
│      settings.json
│
├─components
│      NavButton.qml
│      sidebar.qml
│      TopHeader.qml
│
├─dialogs
│      LoginOverlay.qml
│
├─ico
│      add.ico
│      card.ico
│      eye.ico
│      home.ico
│      icon.ico
│      log.ico
│      records.ico
│      score.ico
│      statistics.ico
│      student.ico
│      usr.ico
│
├─pages
│      AppointmentPage.qml
│      CardIssuePage.qml
│      DashboardPage.qml
│      LogPage.qml
│      MonitorPage.qml
│      RecordsPage.qml
│      ScorePage.qml
│      StatisticsPage.qml
│      StudentPage.qml
│
└─tools