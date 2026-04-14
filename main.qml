// 入口
import QtQuick 2.14
import QtQuick.Window 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14
import Qt.labs.platform 1.1 // FileDialog
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
    property bool isAdmin: false
    property string currentUser: "" // 登录用户名，控制权限显示

    // ============== 全局数据模型 (由各子页面共享) =========
        ListModel { id: historyModel }        // 训练打卡记录
    ListModel { id: theoryModel }         // 理论考试成绩
    ListModel { id: activeSessionModel }  // 实时在线设备
    ListModel { id: connectedDevicesModel } // 已连接设备（发卡页选择）
    ListModel { id: studentsModel }       // 学员名册
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
        onDevicesUpdated: {
            refreshConnectedDevices()
        }
    }

    Connections {
        target: backend

        function onNewCardDetected(cardId, status, name) {
            console.log("检测到新卡:", cardId, status, name)

            // 写入发卡页面输入框并通知发卡页面当前卡状态
            cardIssuePage.cardUid = cardId
            cardIssuePage.detectedCardStatus = status
            cardIssuePage.detectedCardName = name
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

    function refreshConnectedDevices() {
        connectedDevicesModel.clear()
        var devices = backend.getConnectedDevices()
        for (var i = 0; i < devices.length; i++) {
            connectedDevicesModel.append(devices[i])
        }
        if (cardIssuePage && cardIssuePage.restoreDeviceSelection) {
            cardIssuePage.restoreDeviceSelection()
        }
    }
   
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
            refreshConnectedDevices()
        }
    }

    // 初始化 页面刚加载完毕时 查一次 显示历史记录
    Component.onCompleted: {
        refreshStudentsList()
        refreshConnectedDevices()
        Helpers.refreshTable(historyModel, backend)
        Helpers.refreshTheoryTable(theoryModel, backend)
    }

    // ================= 全局组件 =======================
    // 导出 CSV 报表对话框 
    FileDialog {
        id: exportDialog
        title: "导出 CSV 报表"
        fileMode: FileDialog.SaveFile // 模式为保存
        nameFilters: ["CSV 文件 (*.csv)"]
        onAccepted: {
            // 如果用户选择了同一路径文件，直接覆盖
            backend.exportToCSV(file)
        }
        onRejected: {
            // 取消导出
            logPage.appendLog("[系统] 已取消导出操作")
        }
    }

    // ================= 界面布局 =======================
    LoginOverlay {
        id: loginOverlay
        anchors.fill: parent
        visible: !isLoggedIn
        z: 999
        onLoginSuccess: {
            isLoggedIn = true
            currentUser = username
            isAdmin = (username === "root")
            sideBar.isAdmin = isAdmin
            // 更新头部和记录页权限
            topHeader.isAdmin = isAdmin
            topHeader.currentUser = currentUser
            recordsPage.isAdmin = isAdmin
            // 控制日志页可见性
            logPage.visible = isAdmin
        }
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
            isAdmin: root.isAdmin
            onNavClicked: stack.currentIndex = index
        }

        // 右侧内容区
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            TopHeader {
                id: topHeader
                Layout.fillWidth: true
                Layout.preferredHeight: 60
                recordCount: historyModel.count
                serverStatus: root.serverRunning
                isAdmin: root.isAdmin
                currentUser: root.currentUser
            }

            StackLayout {
                id: stack
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: 0 // 由 SideBar 控制切换
                onCurrentIndexChanged: {
                    if (currentIndex === 1)
                    refreshStudentsList()
                }

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
                    id: recordsPage
                    model: historyModel
                    onRefreshRequested: Helpers.refreshTable(historyModel, backend)
                    onExportRequested: exportDialog.open()
                    isAdmin: root.isAdmin
                }

                MonitorPage {
                    model: activeSessionModel
                }

                StatisticsPage {
                    id: statsPage
                    studentListModel: studentsModel
                }

                ScorePage {
                    model: theoryModel
                }

                LogPage {
                    id: logPage
                    visible: root.isAdmin
                }

                CardIssuePage {
                    id: cardIssuePage
                    activeDevicesModel: connectedDevicesModel
                }

                AppointmentPage {
                   id: appointPage
                   backend: backend
                }
            }
        }
    }
}

