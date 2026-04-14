// 训练记录
import QtQuick 2.14
import QtQuick.Layouts 1.14
import QtQuick.Controls 2.14

Item {
    id: recordsPage
    property var model: null
    signal refreshRequested()
    signal exportRequested() 

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 30
        spacing: 20

        RowLayout {
            Layout.fillWidth: true
            Label { text: "训练打卡流水"; font.pixelSize: 22; font.bold: true }
            Item { Layout.fillWidth: true }
            Button {
                text: "刷新数据"
                highlighted: true
                onClicked: refreshRequested()
            }
            Button { 
                text: "导出 CSV"
                highlighted: true
                onClicked: exportRequested()
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "white"
            radius: 8
            border.color: "#e0e0e0"

            ListView {
                id: recordListView
                anchors.fill: parent
                model: recordsPage.model
                clip: true
                header: Rectangle {
                    width: recordListView.width; height: 50; color: "#f1f2f6"
                    RowLayout {
                        anchors.fill: parent; anchors.margins: 15
                        Label { text: "ID"; Layout.preferredWidth: 50; font.bold: true }
                        Label { text: "学员姓名"; Layout.preferredWidth: 120; font.bold: true }
                        Label { text: "行为类型"; Layout.preferredWidth: 100; font.bold: true }
                        Label { text: "本次时长"; Layout.preferredWidth: 100; font.bold: true }
                        Label { text: "打卡时间"; Layout.fillWidth: true; font.bold: true }
                    }
                }

                delegate: Item {
                    width: recordListView.width; height: 50
                    RowLayout {
                        anchors.fill: parent; anchors.margins: 15
                        Label { text: model.id; Layout.preferredWidth: 50; color: "#7f8c8d" }
                        Label { text: model.student_name; Layout.preferredWidth: 120; font.bold: true }

                        // 行为高亮显示
                        Rectangle {
                            Layout.preferredWidth: 80; height: 26; radius: 4
                            color: model.action === "上车签到" ? "#dcfce7" : "#fee2e2"
                            Text {
                                anchors.centerIn: parent
                                text: model.action
                                color: model.action === "上车签到" ? "#166534" : "#991b1b"
                                font.pixelSize: 12
                            }
                        }

                        Label {
                            text: model.duration > 0 ? model.duration + "s" : "-"
                            Layout.preferredWidth: 100
                            color: "#e67e22"
                        }
                        Label { text: model.timestamp; Layout.fillWidth: true; color: "#636e72" }
                    }
                    Rectangle {
                        anchors.bottom: parent.bottom; width: parent.width; height: 1
                        color: "#f1f2f6"
                    }
                }
            }
        }
    }
}
