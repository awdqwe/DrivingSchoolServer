# 一、硬件方案
树莓派 + RC522 RFID 模块（刷卡模块）
在真实的驾校系统中，“学员上车刷卡签到，下车刷卡签退”是最核心的物联网动作。这个硬件能提供实物交互演示
# 二、软件方案
1. 树莓派端软件设计 (C/C++ Linux)
    多线程并发 (std::thread)：
    线程 A（硬件交互）：循环读取 RFID 模块，检测是否有学员刷卡。
    线程 B（数据模拟与生成）：当学员刷卡上车后，启动该线程，每隔 1 秒生成一组车辆状态数据（如：当前车速、虚拟坐标、学习时长）。
    线程 C（网络通信）：负责与 PC 端保持 TCP 长连接，并发送心跳包（Heartbeat）和业务数据。
    离线缓存机制（重点）：如果在练车过程中网络断开了（WiFi信号不好），C++ 程序能将数据暂存在树莓派的本地（写进文件里），等网络恢复后，再把“断网期间的学时数据”补传给 PC。
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















# （本系统基于 Linux 环境，通过移植开源的 MFRC522 C++ 类库，调用底层 bcm2835 驱动直接操作硬件 SPI 寄存器。实现了对实体射频卡的精准轮询读取，并将物理 UID 序列号进行十六进制序列化后，封装为 JSON 格式实时推送至管理中枢……）

# （陷阱： 我们刚才写的 RFID 刷卡代码里，有一个 while(true) 死循环（无限轮询硬件）。如果把这个死循环直接塞进带有 UI 界面的程序里，界面的主线程就会被瞬间卡死（假死），按钮点不动，画面也会卡住。破局方案（下一步）： 我们将采用**“多线程（Multi-threading）+ 信号槽”**架构！
 1、主线程（UI 线程）：负责跑“车载打卡界面”
 2、子线程（工作线程）：把 while(true) 的硬件刷卡代码扔到后台子线程去跑。当子线程读到卡号后，通过跨线程的 Signal（信号） 发送给前台 UI ）
