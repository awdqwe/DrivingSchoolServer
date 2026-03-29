// 发卡注册页
import QtQuick 2.14
import QtQuick.Layouts 1.14
import QtQuick.Controls 2.14

Item {
    id: cardIssuePage
    property alias cardUid: cardUidInput.text
    property bool issueModeActive: false
    property bool serverRunning: false; property bool canOperateIssueMode: serverRunning

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 30
        spacing: 30

        Label { text: "RFID 发卡管理中心"; font.pixelSize: 22; font.bold: true }

        RowLayout {
            Layout.fillWidth: true
            spacing: 30

            // 左侧：发卡操作区
            Rectangle {
                Layout.preferredWidth: 400
                Layout.preferredHeight: 450
                color: "white"
                radius: 12
                border.color: "#e0e0e0"

                ColumnLayout {
                    anchors.centerIn: parent
                    width: parent.width - 60
                    spacing: 20

                    Rectangle {
                        width: 80; height: 80; radius: 40; color: "#f0f7ff"
                        Text { anchors.centerIn: parent; text: "qrc:/res/ico/usr.ico"; font.pixelSize: 40 }
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Label {
                        text: "请在车载端刷未绑定的新卡"
                        font.bold: true; font.pixelSize: 16
                        Layout.alignment: Qt.AlignHCenter
                    }

                    TextField {
                        id: cardUidInput
                        placeholderText: "自动获取的物理卡号"
                        Layout.fillWidth: true
                        readOnly: true
                        background: Rectangle { radius: 6; color: "#f5f6fa"; border.color: "#dcdde1" }
                    }

                    TextField {
                        id: studentNameInput
                        placeholderText: "输入拟绑定学员姓名"
                        Layout.fillWidth: true
                        enabled: serverRunning
                    }

                    Button {
                        text: {
                            if (!serverRunning) return "请先启动管理服务"
                            return issueModeActive ? "关闭发卡模式" : "开启发卡模式"
                        }
                        Layout.fillWidth: true
                        Layout.preferredHeight: 45
                        highlighted: issueModeActive && serverRunning
                        enabled: serverRunning // 服务未运行时禁用按钮
                        background: Rectangle {
                            color: {
                                if (!serverRunning) return "#95a5a6"
                                return issueModeActive ? "#e74c3c" : "#2ecc71"
                            }
                            radius: 8
                        }
                        onClicked: {
                            if (!serverRunning) {
                                console.log("无法操作：管理服务未启动")
                                return
                            }
                            if (issueModeActive) {
                                backend.sendControlCommand("exit_issue_mode")
                                console.log("发卡模式已关闭")
                            } else {
                                backend.sendControlCommand("enter_issue_mode")
                                console.log("发卡模式已开启")
                            }
                            issueModeActive = !issueModeActive
                        }
                    }

                    Button {
                        text: "立即写入档案"
                        Layout.fillWidth: true
                        Layout.preferredHeight: 45
                        highlighted: true
                        enabled: serverRunning
                        onClicked: {
                            if (!serverRunning) return;
                            if (cardUidInput.text.length === 0) return;
                            if (studentNameInput.text.length === 0) return;
                            
                            if (backend.registerNewStudent(cardUidInput.text, studentNameInput.text)) {
                                console.log("注册成功")
                                // 清空
                                cardUidInput.text = ""
                                studentNameInput.text = ""
                                // 关闭发卡模式
                                if (issueModeActive) {
                                    backend.sendControlCommand("exit_issue_mode")
                                    issueModeActive = false
                                }
                            }
                        }
                    }
                }
            }

            // 右侧：说明与指引
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "#f8f9fa"
                radius: 12

                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 25; spacing: 15
                    Label { text: "发卡业务流程"; font.bold: true; font.pixelSize: 16 }
                    Label {
                        text: "1. 准备空白 M1/S50 系列卡片。\n2. 车载端 MFRC522 识别卡片后将 UID 发送至此。\n3. 管理员核对信息并输入姓名。\n4. 点击写入，完成卡片与身份的云端绑定。\n注：使用发卡注册功能需提前开启服务器监听功能"
                        lineHeight: 1.5; color: "#636e72"
                        wrapMode: Text.WordWrap; Layout.fillWidth: true
                    }
                    Item { Layout.fillHeight: true }
                }
            }
        }
    }
}
