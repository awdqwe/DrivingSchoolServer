import QtQuick 2.14
import QtQuick.Window 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14 // 引入专业布局模块
import Backend 1.0

Window {
    visible: true
    width: 1080  // 窗口
    height: 600
    title: qsTr("驾校智能车载终端与管理中枢 - 实时监控系统")
    color: "#f0f2f5" // 底色 灰白

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

    // 主布局：左右分栏
    RowLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        // ================= 左侧 控制与日志区 =================
        ColumnLayout {
            Layout.preferredWidth: 350
            Layout.fillHeight: true
            spacing: 15

            Button {
                text: "启动 TCP 服务端"
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                font.pixelSize: 16
                font.bold: true
                onClicked: {
                    backend.startServer(8888)
                    enabled = false
                    text = "服务运行中 (监听端口: 8888)..."
                }
            }

            Label { text: "底层通信实时日志："; font.bold: true; color: "#333" }

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                TextArea {
                    id: logArea
                    readOnly: true
                    text: "系统初始化完毕，等待连接...\n"
                    font.pixelSize: 13
                    background: Rectangle {
                        color: "#282c34" // 控制台 黑色
                        radius: 8
                    }
                    color: "#abb2bf" // 字体 绿色
                }
            }
        }

        // ================= 右侧 SQLite 数据库实时表格 =================
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10

            RowLayout {
                Label {
                    text: "车辆打卡历史记录 (SQLite持久化)"
                    font.bold: true; font.pixelSize: 18; color: "#2c3e50"
                }
                Item { Layout.fillWidth: true } // 占位弹簧
                Button {
                    text: "手动刷新"
                    onClicked: refreshTable()
                }
            }

            // 表头
            Rectangle {
                Layout.fillWidth: true
                height: 40
                color: "#dcdde1"
                radius: 6
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    Label { text: "ID"; Layout.preferredWidth: 50; font.bold: true }
                    Label { text: "学员姓名"; Layout.preferredWidth: 100; font.bold: true }
                    Label { text: "物理卡号"; Layout.preferredWidth: 100; font.bold: true }
                    Label { text: "车辆动作"; Layout.preferredWidth: 100; font.bold: true }
                    Label { text: "服务器落盘时间"; Layout.fillWidth: true; font.bold: true }
                }
            }

            // 表格主体 (ListView 结合 Delegate 渲染)
            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: historyModel
                clip: true
                spacing: 4

                // 定义每一行怎么显示
                delegate: Rectangle {
                    width: ListView.view.width
                    height: 45
                    radius: 6
                    color: index % 2 === 0 ? "#ffffff" : "#f9f9f9" // 斑马线交替背景色
                    border.color: "#eeeeee"

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 15
                        Label { text: model.id; Layout.preferredWidth: 50; color: "#7f8c8d" }
                        // 学员姓名
                        Label {
                            text: model.student_name  // 对应 C++ 的 student_name
                            Layout.preferredWidth: 100
                            font.bold: true
                            color: "#8e44ad"  // 紫色区分
                        }
                        Label { text: model.card_id; Layout.preferredWidth: 100; font.bold: true; color: "#2980b9" }

                        // 动态变色 如果“上车”显示绿色，否则显示橙色
                        Label {
                            text: model.action
                            Layout.preferredWidth: 100
                            font.bold: true
                            color: model.action.indexOf("上车") !== -1 ? "#27ae60" : "#e67e22"
                        }

                        Label { text: model.timestamp; Layout.fillWidth: true; color: "#95a5a6" }
                    }
                }
            }
        }
    }
}
