// 系统监控
import QtQuick 2.14
import QtQuick.Layouts 1.14
import QtQuick.Controls 2.14

ScrollView {
    id: dashboardPage
    contentWidth: width
    clip: true

    // 接收 main.qml 传来的属性
    property bool isRunning: false
    property int activeCount: 0
    property int historyCount: 0
    signal startServerRequested()
    signal serverStatusChanged(bool running)

    ColumnLayout {
        width: parent.width - 40
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 20
        spacing: 25

        Label {
            text: "系统概览"
            font.pixelSize: 24
            font.bold: true
            color: "#2c3e50"
        }

        // 第一行：统计卡片
        RowLayout {
            Layout.fillWidth: true
            spacing: 20

            // 卡片模板定义（内部）
            Component {
                id: statusCardComponent
                Rectangle {
                    property string title: ""
                    property string value: ""
                    property color themeColor: "#3498db"
                    property string iconTxt: ""

                    Layout.fillWidth: true
                    Layout.preferredHeight: 120
                    radius: 10
                    color: "white"
                    layer.enabled: true

                    RowLayout {
                        anchors.fill: parent; anchors.margins: 20
                        Column {
                            Layout.fillWidth: true
                            spacing: 10
                            Label { text: title; color: "#7f8c8d"; font.pixelSize: 14 }
                            Label { text: value; color: "#2c3e50"; font.pixelSize: 28; font.bold: true }
                        }
                        Text {
                            text: iconTxt; font.pixelSize: 40; color: themeColor; opacity: 0.2
                        }
                    }
                }
            }

            Loader {
                sourceComponent: statusCardComponent
                onLoaded: {
                    item.title = "服务器状态"
                    item.value = isRunning ? "已启动" : "未就绪"
                    item.themeColor = isRunning ? "#2ecc71" : "#e74c3c"
                    item.iconTxt = "⚙"
                }
            }

            Loader {
                sourceComponent: statusCardComponent
                onLoaded: {
                    item.title = "当前在线设备"
                    item.value = activeCount + " 台"
                    item.themeColor = "#3498db"
                    item.iconTxt = "🚗"
                }
            }

            Loader {
                sourceComponent: statusCardComponent
                onLoaded: {
                    item.title = "累计训练次数"
                    item.value = historyCount + " 次"
                    item.themeColor = "#9b59b6"
                    item.iconTxt = "📊"
                }
            }
        }

        // 第二行：操作区与服务器控制
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 200
            radius: 10
            color: "white"

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 20

                Label {
                    text: isRunning ? "服务器正在监听端口 8888..." : "系统准备就绪，请启动通信中枢"
                    font.pixelSize: 16
                    color: "#34495e"
                    Layout.alignment: Qt.AlignHCenter
                }

                Button {
                    text: isRunning ? "服务运行中" : "启动管理服务"
                    enabled: !isRunning
                    Layout.preferredWidth: 200
                    Layout.preferredHeight: 50

                    background: Rectangle {
                        color: isRunning ? "#95a5a6" : "#2ecc71"
                        radius: 25
                    }

                    contentItem: Text {
                        text: parent.text
                        color: "white"
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: {
                        startServerRequested()
                        serverStatusChanged(true)
                    }
                }
            }
        }

        // 第三行：快捷通知
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 100
            color: "#ebf5fb"
            radius: 8
            border.color: "#d4e6f1"

            RowLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 15
                Text { text: "ℹ"; font.pixelSize: 20; color: "#3498db" }
                Label {
                    text: "系统提示：共有 " + historyCount + " 条打卡记录，请及时查看异常记录。"
                    color: "#2980b9"
                    Layout.fillWidth: true
                }
            }
        }
    }
    onIsRunningChanged: {
        serverStatusChanged(isRunning)
    }
}
