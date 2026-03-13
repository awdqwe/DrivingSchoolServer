import QtQuick 2.14
import QtQuick.Window 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14 // 引入专业布局模块
import Backend 1.0

Window {
    visible: true
    width: 1200  // 窗口
    height: 600
    title: qsTr("驾校智能车载终端与管理中枢 - 实时监控系统")
    color: "#f0f2f5" // 底色 灰白

    property bool serverRunning: false // 按键状态

    // 负责存储和提供给表格显示的数据模型
    ListModel {
        id: historyModel
    }

    TcpBackend {
        id: backend

        onMessageReceived: {
            logArea.append("> " + msg)
        }

        // 当收到 C++ 发来的数据库更新信号时，自动刷新界面表格
        onDatabaseUpdated: {
            refreshTable()
        }
    }

    // 页面刚加载完毕时，查一次数据库，显示历史记录
    Component.onCompleted: {
        refreshTable()
    }

    // 封装 刷新表格的函数
    function refreshTable() {
        historyModel.clear() // 先清空旧数据
        var records = backend.getHistoryRecords() // 调用 C++ 获取最新数据
        for (var i = 0; i < records.length; i++) {
            historyModel.append(records[i]) // 塞入模型，界面自动渲染
        }
    }

    // 主布局
    RowLayout {
        anchors.fill: parent

        // ================= 左侧导航栏 =================
        Rectangle {
            Layout.preferredWidth: 200
            Layout.fillHeight: true
            color: "#2c3e50"

            Column {
                anchors.fill: parent
                anchors.margins: 15
                spacing: 15

                Label {
                    text: "驾校管理系统"
                    color: "white"
                    font.pixelSize: 20
                    font.bold: true
                }

                Button {
                    text: "系统监控"
                    onClicked: stack.currentIndex = 0
                }

                Button {
                    text: "训练记录"
                    onClicked: stack.currentIndex = 1
                }

                Button {
                    text: "学员管理"
                    onClicked: stack.currentIndex = 2
                }

                Button {
                    text: "数据统计"
                    onClicked: stack.currentIndex = 3
                }
            }
        }

        // ================= 右侧内容区域 =================
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // ===== 顶部状态栏 =====
            Rectangle {
                Layout.fillWidth: true
                height: 50
                color: "#ecf0f1"

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10

                    Label {
                        text: "驾校智能车载终端与管理系统"
                        font.pixelSize: 18
                        font.bold: true
                    }

                    Item { Layout.fillWidth: true }

                    Label {
                        text: "数据库记录数: " + historyModel.count
                    }
                }
            }

            // ===== 页面切换区域 =====
            StackLayout {
                id: stack
                Layout.fillWidth: true
                Layout.fillHeight: true

                // ================= 页面1 系统监控 =================
                Item {

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 30

                        Label {
                            text: "系统运行状态"
                            font.pixelSize: 28
                            font.bold: true
                        }

                        Label {
                            text: "服务器端口: 8888"
                            font.pixelSize: 20
                        }

                        Label {
                            text: "历史训练记录: " + historyModel.count
                            font.pixelSize: 20
                        }

                        Button {
                            text: serverRunning ? "服务器运行中 (端口 8888)" : "启动 TCP 服务端"
                            enabled: !serverRunning  // 运行中禁用
                            onClicked: {
                                backend.startServer(8888)
                                serverRunning = true
                            }
                        }
                    }
                }

                // ================= 页面2 训练记录 =================
                Item {

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 20

                        // 左侧日志
                        ColumnLayout {
                            Layout.preferredWidth: 300
                            Layout.fillHeight: true

                            Label {
                                text: "通信日志"
                                font.bold: true
                            }

                            ScrollView {
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                TextArea {
                                    id: logArea
                                    readOnly: true
                                    text: "系统初始化完成...\n"

                                    background: Rectangle {
                                        color: "#282c34"
                                    }

                                    color: "#abb2bf"
                                }
                            }
                        }

                        // 右侧数据库表格
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            RowLayout {

                                Label {
                                    text: "训练历史记录"
                                    font.pixelSize: 18
                                    font.bold: true
                                }

                                Item { Layout.fillWidth: true }

                                Button {
                                    text: "刷新"
                                    onClicked: refreshTable()
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 40
                                color: "#dcdde1"

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 10

                                    Label { text: "ID"; Layout.preferredWidth: 40 }
                                    Label { text: "姓名"; Layout.preferredWidth: 100 }
                                    Label { text: "卡号"; Layout.preferredWidth: 120 }
                                    Label { text: "动作"; Layout.preferredWidth: 100 }
                                    Label { text: "时长"; Layout.preferredWidth: 80 }
                                    Label { text: "时间"; Layout.fillWidth: true }
                                }
                            }

                            ListView {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                model: historyModel
                                spacing: 4

                                delegate: Rectangle {

                                    width: ListView.view.width
                                    height: 45
                                    color: index % 2 ? "#f9f9f9" : "#ffffff"

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 10

                                        Label { text: model.id; Layout.preferredWidth: 40 }
                                        Label { text: model.student_name; Layout.preferredWidth: 100 }
                                        Label { text: model.card_id; Layout.preferredWidth: 120 }

                                        Label {
                                            text: model.action
                                            Layout.preferredWidth: 100
                                            color: model.action === "上车签到" ? "green" :
                                                   model.action === "下车签退" ? "orange" : "red"
                                        }

                                        Label {
                                            text: model.duration > 0 ? model.duration + " 秒" : "--"
                                            Layout.preferredWidth: 80
                                        }

                                        Label { text: model.timestamp; Layout.fillWidth: true }
                                    }
                                }
                            }
                        }
                    }
                }

                // ================= 页面3 学员管理 =================
                Item {

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 20

                        Label {
                            text: "学员管理模块"
                            font.pixelSize: 24
                        }

                        Button { text: "新增学员" }

                        Button { text: "删除学员" }
                    }
                }

                // ================= 页面4 数据统计 =================
                Item {

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 25

                        Label {
                            text: "训练数据统计"
                            font.pixelSize: 28
                            font.bold: true
                        }

                        Label {
                            text: "累计训练记录: " + historyModel.count
                            font.pixelSize: 20
                        }
                    }
                }
            }
        }
    }

}
