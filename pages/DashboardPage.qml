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

        // 左上角 标题
        Label {
            text: "系统概览"
            font.pixelSize: 24
            font.bold: true
            color: "#2c3e50"
        }

        // 启动服务卡片
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

        // 系统提示卡片
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
                Image {
                    source: "qrc:/res/ico/icon.ico"
                    width: 20; height: 20
                    fillMode: Image.PreserveAspectFit
                }
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
