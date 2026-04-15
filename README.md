# 一、硬件方案
树莓派(4代B型 4G ram) + RC522 RFID 模块（刷卡模块）
在真实的驾校系统中，“学员上车刷卡签到，下车刷卡签退”是最核心的物联网动作。这个硬件能提供实物交互演示
# 二、软件方案
1. 树莓派端软件设计 (C/C++ Linux)
    多线程并发 (std::thread)：
    离线缓存机制：如果在练车过程中网络断开，C++ 程序能将数据暂存在树莓派的本地（写进文件里），等网络恢复后，再把“断网期间的学时数据”补传给 PC。
    JSON 数据格式：树莓派和 PC 通信采用跨平台的 JSON 格式（可以使用轻量级的开源库如 nlohmann/json ）。
2. PC端软件设计 (C++ & Qt)
    TCP 并发服务器：使用 Qt 的 QTcpServer，能够同时接入多个“树莓派车辆”（程序架构上支持多车同时练车，体现扩展性）。
    MVC 架构的 UI 设计：
    大屏监控界面：实时显示车辆状态（学员姓名、已练时长、当前模拟车速）。可以使用 QtCharts 画一个动态折线图，显示车速变化。
    信息管理界面：操作 SQLite 数据库，实现学员信息的录入、RFID 卡号的绑定、学时统计和查询。
    数据库设计 (SQLite)：
    Student_Table（学员表：学号、姓名、绑定的卡号、需完成总学时）
    Record_Table（打卡记录表：卡号、上车时间、下车时间、本次练习时长）
    通信协议选 TCP。TCP 是一种“面向连接”的协议。当树莓派开机连上服务端时，服务端能确切知道“1号车已上线”；如果树莓派断电或开到没有 WiFi 的地方，TCP 连接断开，服务端会立刻触发 disconnected 信号，界面上就能把这辆车标红显示“离线”。UDP 无法原生做到这一点
    多表关联（JOIN）”和“身份解析”

# 三、安装 bcm2835 库
    开启树莓派的 SPI 通信接口
    下载 C++ 硬件驱动库 (bcm2835)
        wget http://www.airspayce.com/mikem/bcm2835/bcm2835-1.73.tar.gz
        tar zxvf bcm2835-1.73.tar.gz
        cd bcm2835-1.73
        ./configure
        make
        sudo make check
        sudo make install
# 四、安装 QT5 环境
    sudo apt update
    sudo apt install qtbase5-dev qt5-qmake qtbase5-dev-tools -y
    sudo apt install qtdeclarative5-dev
    sudo apt install qml-module-qtquick-controls2


# （本系统基于 Linux 环境，通过移植开源的 MFRC522 C++ 类库，调用底层 bcm2835 驱动直接操作硬件 SPI 寄存器。
    实现了对实体射频卡的精准轮询读取，并将物理 UID 序列号进行十六进制序列化后，封装为 JSON 格式实时推送至管理中枢……）
#  TCP 的套接字 sock 是在 RfidThread::run() 里的一个局部变量。
    而 DeviceBackend::uploadTheoryResult 是在主线程（GUI线程）里执行的。
    主线程无法直接跨线程调用局部的 sock 来发送数据。
    为了解决这个问题，需要在 RfidThread 里增加一个线程安全的发送队列（使用 QMutex 锁和 QQueue 队列）。
    主线程把答题成绩塞进队列，RfidThread 在它自己的死循环里不断检查队列并发送出去。
# 系统采用“业务与通信解耦架构”，将数据生成与网络发送分离，
    通过 Qt 信号槽实现跨线程通信，提高系统可维护性与扩展性。

# （陷阱： RFID 刷卡代码里，有一个 while(true) 死循环（无限轮询硬件）。如果把这个死循环直接
    塞进带有 UI 界面的程序里，界面的主线程就会被瞬间卡死（假死），按钮点不动，画面也会卡住。破局方案（下一步）：
    我们将采用**“多线程（Multi-threading）+ 信号槽”**架构
    1、主线程（UI 线程）：负责跑“车载打卡界面”
    2、子线程（工作线程）：把 while(true) 的硬件刷卡代码扔到后台子线程去跑。当子线程读到卡号后，通过跨线程的
        Signal（信号） 发送给前台 UI ）

# 由于车载终端处于复杂的边缘网络环境中，如果有黑客使用网络调试助手，直连服务端
    8888 端口，发送伪造的 JSON（如：{"CardID":"VIP123", "Action":"下车签退", "Duration": 99999}），
    就可以实现恶意刷学时。
    为此，本系统在 TCP 应用层引入了 Salt（加盐）机制与 MD5 数字签名算法，彻底杜绝了数据在传输过程中的篡改与伪造。
    如果黑客篡改了 Duration（比如改成 99999），但他不知道 secretKey，算出来的 MD5 绝对和 clientSign 对不上

# 加入心跳机制 解决设备异常关闭问题
    步骤1，给数据库中的表加一项设备号，表示”学员在哪一个设备练习的“
        区分同一个学员在不同车辆上的练习，避免数据混淆
    步骤2，设备周期性发送心跳包给PC端，内容大概为“卡号为xxx的人，在设备号为xxx的车中练习”。
        感知练习状态
    步骤3，PC端接收心跳，收到即回复（或者可以不回复），一段时间内没收到就认为设备关闭，将自己生成一条下车签退的数据写进数据库。
    步骤4，如果要让步骤3能正常进行，需要给PC端也写一个计时器。
        检测心跳超时







## 回应消息详情
# 刷卡签到 
    触发条件: 数据库插入成功时返回
    {
        "type": "ack",
        "status": "success",
        "CardID": "卡片ID",
        "name": "学员姓名",
        "action": "上车签到/下车签退",
        "duration": 时长数值
    }

# 理论成绩
    触发条件: 理论成绩入库成功时返回
    {
        "type": "ack",
        "status": "theory_ok",
        "CardID": "卡片ID"
    }
    
# 发卡消息
    已注册卡片
    {
        "type": "issue_reply",
        "status": "exists",
        "CardID": "卡片ID",
        "name": "学员姓名"
    }
    新卡
    {
        "type": "issue_reply",
        "status": "new",
        "CardID": "卡片ID"
    }

## 基本结构
C:.
│  dbmanager.cpp
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
│  settings.json
│
├─components
│  NavButton.qml
│  sidebar.qml
│  TopHeader.qml
│
├─dialogs
│  LoginOverlay.qml
│
├─ico
│  add.ico
│  card.ico
│  eye.ico
│  home.ico
│  icon.ico
│  log.ico
│  records.ico
│  score.ico
│  statistics.ico
│  student.ico
│  usr.ico
│
└─pages
    AppointmentPage.qml
    CardIssuePage.qml
    DashboardPage.qml
    LogPage.qml
    MonitorPage.qml
    RecordsPage.qml
    ScorePage.qml
    StatisticsPage.qml
    StudentPage.qml
