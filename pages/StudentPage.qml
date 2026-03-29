// 学员管理
import QtQuick 2.14
import QtQuick.Layouts 1.14
import QtQuick.Controls 2.14

Item {
    id: studentPage

    // 接收 main.qml 的模型和信号
    property var model: null
    signal actionRegister(string name, string card)
    signal actionDelete(string card)

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 30
        spacing: 20

        // 标题与搜索栏
        RowLayout {
            Layout.fillWidth: true
            Column {
                Label { text: "学员档案库"; font.pixelSize: 22; font.bold: true }
                Label { text: "管理所有已绑定的 RFID 学员卡信息"; color: "#7f8c8d" }
            }
            Item { Layout.fillWidth: true }

            TextField {
                id: searchInput
                placeholderText: "🔍 输入姓名或卡号搜索..."
                Layout.preferredWidth: 300
                background: Rectangle { radius: 20; border.color: "#dcdde1" }
            }

            Button {
                text: "新增学员"
                highlighted: true
                onClicked: registerPopup.open()
            }
        }

        // 学员列表表格容器
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "white"
            radius: 8
            border.color: "#e0e0e0"

            ColumnLayout {
                anchors.fill: parent; spacing: 0

                // 表头
                Rectangle {
                    Layout.fillWidth: true; height: 50; color: "#f8f9fa"; radius: 8
                    RowLayout {
                        anchors.fill: parent; anchors.margins: 15
                        Label { text: "学员姓名"; Layout.preferredWidth: 200; font.bold: true }
                        Label { text: "物理卡号 (UID)"; Layout.preferredWidth: 200; font.bold: true }
                        Label { text: "状态"; Layout.preferredWidth: 150; font.bold: true }
                        Item { Layout.fillWidth: true }
                        Label { text: "操作"; Layout.preferredWidth: 100; font.bold: true }
                    }
                }

                // 表体
                ListView {
                    id: studentList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: studentPage.model

                    delegate: Rectangle {
                        width: studentList.width; height: 60
                        color: index % 2 === 0 ? "white" : "#fafafa"

                        RowLayout {
                            anchors.fill: parent; anchors.margins: 15
                            Label { text: model.name; Layout.preferredWidth: 200; font.pixelSize: 14 }
                            Label { text: model.card_id; Layout.preferredWidth: 200; color: "#2980b9"; font.family: "Consolas" }
                            Rectangle {
                                Layout.preferredWidth: 60; height: 24; radius: 12
                                color: "#e8f5e9"
                                Text { anchors.centerIn: parent; text: "正常"; color: "#2e7d32"; font.pixelSize: 11 }
                            }
                            Item { Layout.fillWidth: true }
                            Button {
                                text: "删除"
                                flat: true
                                contentItem: Text { text: "删除"; color: "#e74c3c" }
                                onClicked: actionDelete(model.card_id)
                            }
                        }
                    }
                }
            }
        }
    }

    // 新增学员弹窗
    Dialog {
        id: registerPopup
        title: "录入新学员"
        standardButtons: Dialog.Ok | Dialog.Cancel
        anchors.centerIn: parent
        width: 350

        ColumnLayout {
            width: parent.width; spacing: 15
            TextField { id: nIn; placeholderText: "姓名"; Layout.fillWidth: true }
            TextField { id: cIn; placeholderText: "RFID卡号 (8位十六进制)"; Layout.fillWidth: true }
        }

        onAccepted: {
            actionRegister(nIn.text, cIn.text)
            nIn.text = ""; cIn.text = ""
        }
    }
}
