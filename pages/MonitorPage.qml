// 实时监控
import QtQuick 2.14
import QtQuick.Layouts 1.14
import QtQuick.Controls 2.14

Item {
    id: monitorPage
    property var model: null // 绑定 activeSessionModel

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 30
        spacing: 20

        RowLayout {
            Layout.fillWidth: true
            Column {
                Label { text: "实时在线监控"; font.pixelSize: 22; font.bold: true }
                Label {
                    text: "当前共有 " + (monitorPage.model ? monitorPage.model.count : 0) + " 台设备正在训练"
                    color: "#27ae60"; font.bold: true
                }
            }
            Item { Layout.fillWidth: true }
            // 模拟刷新动画
            BusyIndicator {
                running: true
                Layout.preferredWidth: 30; Layout.preferredHeight: 30
            }
        }

        // 网格布局显示在线车辆卡片
        GridView {
            id: monitorGrid
            Layout.fillWidth: true
            Layout.fillHeight: true
            cellWidth: 300
            cellHeight: 180
            model: monitorPage.model
            clip: true

            delegate: Rectangle {
                width: 280; height: 160
                radius: 12
                color: "white"
                border.color: "#3498db"
                border.width: 2

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 15

                    RowLayout {
                        Layout.fillWidth: true
                        Rectangle {
                            width: 40; height: 40; radius: 20; color: "#ebf5fb"
                            Text { anchors.centerIn: parent; text: "🚗"; font.pixelSize: 20 }
                        }
                        Column {
                            Label { text: "终端编号: " + model.device_id; font.bold: true }
                            Label { text: "通信状态: 良好"; color: "#2ecc71"; font.pixelSize: 11 }
                        }
                        Item { Layout.fillWidth: true }
                        // 在线闪烁绿点
                        Rectangle {
                            width: 10; height: 10; radius: 5; color: "#2ecc71"
                            OpacityAnimator on opacity { from: 1; to: 0.2; duration: 800; loops: Animation.Infinite }
                        }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: "#f0f0f0" }

                    Grid {
                        columns: 2; spacing: 10
                        Label { text: "当前学员:"; color: "#7f8c8d" }
                        Label { text: model.card_id; font.bold: true; color: "#2c3e50" }
                        Label { text: "训练时长:"; color: "#7f8c8d" }
                        Label { text: model.duration_mins + " 分钟"; color: "#e67e22"; font.bold: true }
                    }

                }
            }
        }
    }
}
