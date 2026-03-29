// 入口
import QtQuick 2.14
import QtQuick.Window 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14
import Backend 1.0
import "pages"
import "dialogs"
import "components"
import "qml_helpers.js" as Helpers

Window {
    id: root
    visible: true; width: 1250; height: 750
    title: "四川民族学院驾校智能管理中枢"
    color: "#f0f2f5"

    // ================= 全局状态 ====================
    property bool serverRunning: false
    property bool isLoggedIn: false

    // ============== 全局数据模型 (由各子页面共享) =========
    ListModel { id: historyModel }        // 训练打卡记录
    ListModel { id: theoryModel }         // 理论考试成绩
    ListModel { id: activeSessionModel }  // 实时在线设备
    ListModel { id: studentsModel }       // 学员名册

    // ================= 后端通信 =================
    TcpBackend {
        id: backend
        onMessageReceived: logPage.appendLog(">" + msg)

        // 数据库更新时触发所有模型刷新
        onDatabaseUpdated: {
            Helpers.refreshTable(historyModel, backend)
            Helpers.refreshTheoryTable(theoryModel, backend)
            // 图表刷新交由具体页面调用，不在这里全局调用
        }
        onStudentsUpdated: {
            refreshStudentsList()
        }
    }

    Connections {
        target: backend

        function onNewCardDetected(cardId) {
            console.log("检测到新卡:", cardId)

            // 写入发卡页面输入框
            cardIssuePage.cardUid = cardId
        }
    }

    // 系统监控 发卡注册
    Connections {
        target: dashboardPage
        onServerStatusChanged: {
            // 当服务状态变化时，更新发卡页面的服务运行状态
            cardIssuePage.serverRunning = running
            
            // 如果服务关闭且发卡模式开启，自动关闭发卡模式
            if (!running && cardIssuePage.issueModeActive) {
                backend.sendControlCommand("exit_issue_mode")
                cardIssuePage.issueModeActive = false
                console.log("服务已关闭，自动退出发卡模式")
            }
        }
    }

    // 定义刷新学员列表函数
    function refreshStudentsList() {
        studentsModel.clear()
        var data = backend.getStudents()
        for (var i = 0; i < data.length; i++) {
            studentsModel.append(data[i])
        }
    }

    // 定时器 刷新设备状态
    Timer {
        interval: 2000
        running: serverRunning
        repeat: true
        onTriggered: {
            var sessions = backend.getActiveSessions()
            activeSessionModel.clear()
            for (var i = 0; i < sessions.length; i++) {
                activeSessionModel.append(sessions[i])
            }
        }
    }

    // 初始化 页面刚加载完毕时 查一次 显示历史记录
    Component.onCompleted: {
        refreshStudentsList()
        Helpers.refreshTable(historyModel, backend)
        Helpers.refreshTheoryTable(theoryModel, backend)
    }

    // ================= 界面布局 =======================
    LoginOverlay {
        id: loginOverlay
        anchors.fill: parent
        visible: !isLoggedIn
        z: 999
        onLoginSuccess: isLoggedIn = true
    }

    RowLayout {
        anchors.fill: parent
        visible: isLoggedIn
        spacing: 0

        // 左侧导航栏
        SideBar {
            id: sideBar
            Layout.preferredWidth: 220
            Layout.fillHeight: true
            onNavClicked: stack.currentIndex = index
        }

        // 右侧内容区
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            TopHeader {
                Layout.fillWidth: true
                Layout.preferredHeight: 60
                recordCount: historyModel.count
                serverStatus: root.serverRunning
            }

            StackLayout {
                id: stack
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: 0 // 由 SideBar 控制切换

                DashboardPage {
                    id: dashboardPage
                    isRunning: root.serverRunning
                    activeCount: activeSessionModel.count
                    historyCount: historyModel.count
                    onStartServerRequested: {
                        backend.startServer(8888)
                        root.serverRunning = true
                    }
                }

                StudentPage {
                    model: studentsModel
                    onActionRegister: (name, card) => {
                        if (backend.registerNewStudent(card, name)) refreshStudentsList()
                    }
                    onActionDelete: (card) => {
                        if (backend.deleteStudent(card)) refreshStudentsList()
                    }
                }

                RecordsPage {
                    model: historyModel
                    onRefreshRequested: Helpers.refreshTable(historyModel, backend)
                }

                MonitorPage {
                    model: activeSessionModel
                }

                StatisticsPage {
                    onRefreshRequested: {
                        Helpers.refreshChart(chartSeries, axisX, axisY, backend)
                    }
                }

                ScorePage {
                    model: theoryModel
                }

                LogPage {
                    id: logPage
                }

                CardIssuePage {
                    id: cardIssuePage
                }

//                SettingPage {
//                    onSaveConfig: { /* 保存端口、IP等 */ }
//                }
            }
        }
    }
}
