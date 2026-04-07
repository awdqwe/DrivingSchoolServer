// 发卡注册页
import QtQuick 2.14
import QtQuick.Layouts 1.14
import QtQuick.Controls 2.14

Item {
    id: cardIssuePage
    property alias cardUid: cardUidInput.text
    property bool issueModeActive: false
    property bool serverRunning: false
    property bool canOperateIssueMode: serverRunning

    // 由 main.qml 注入在线设备模型
    property var activeDevicesModel: null
    // 用户手动选择的设备ID（用于抵抗列表刷新造成的 currentIndex 丢失）
    property string selectedDeviceId: ""

    function findDeviceIndex(deviceId) {
        if (!activeDevicesModel || !deviceId || deviceId.length === 0) return -1
        for (var i = 0; i < activeDevicesModel.count; i++) {
            if (activeDevicesModel.get(i).device_id === deviceId) return i
        }
        return -1
    }

    function restoreDeviceSelection() {
        deviceSelector.currentIndex = findDeviceIndex(selectedDeviceId)
    }

    Connections {
        target: activeDevicesModel
        function onCountChanged() {
            restoreDeviceSelection()
        }
    }

    onActiveDevicesModelChanged: restoreDeviceSelection()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 30
        spacing: 30

        Label { text: "RFID 发卡管理中心"; font.pixelSize: 22; font.bold: true }

        RowLayout {
            spacing: 15

            Label { text: "目标注册设备:"; font.bold: true }

            ComboBox {
                id: deviceSelector
                Layout.preferredWidth: 250
                model: activeDevicesModel
                textRole: "device_id"
                displayText: currentIndex === -1 ? "请选择指定车辆..." : currentText
                onActivated: selectedDeviceId = currentText

                background: Rectangle {
                    border.color: "#3498db"
                    radius: 5
                }
            }

            Rectangle {
                width: 12
                height: 12
                radius: 6
                color: deviceSelector.count > 0 ? "#2ecc71" : "#95a5a6"
            }

            Label {
                text: deviceSelector.count > 0 ? "检测到在线设备" : "无可用设备"
                font.pixelSize: 12
                color: "#7f8c8d"
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 30

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
                        width: 80
                        height: 80
                        radius: 40
                        color: "#f0f7ff"

                        Image {
                            anchors.centerIn: parent
                            width: 40
                            height: 40
                            source: "qrc:/res/ico/usr.ico"
                            fillMode: Image.PreserveAspectFit
                        }
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Label {
                        text: "请在车载端刷未绑定的新卡"
                        font.bold: true
                        font.pixelSize: 16
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
                        enabled: serverRunning && findDeviceIndex(selectedDeviceId) !== -1

                        background: Rectangle {
                            color: {
                                if (!serverRunning) return "#95a5a6"
                                return issueModeActive ? "#e74c3c" : "#2ecc71"
                            }
                            radius: 8
                        }

                        onClicked: {
                            var targetId = selectedDeviceId
                            if (!serverRunning || targetId.length === 0) return

                            if (issueModeActive) {
                                backend.sendControlToDevice(targetId, "exit_issue_mode")
                                console.log("发卡模式已关闭")
                            } else {
                                backend.sendControlToDevice(targetId, "enter_issue_mode")
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
                            if (!serverRunning) return
                            if (cardUidInput.text.length === 0) return
                            if (studentNameInput.text.length === 0) return

                            if (backend.registerNewStudent(cardUidInput.text, studentNameInput.text)) {
                                console.log("注册成功")
                                cardUidInput.text = ""
                                studentNameInput.text = ""

                                if (issueModeActive && findDeviceIndex(selectedDeviceId) !== -1) {
                                    backend.sendControlToDevice(selectedDeviceId, "exit_issue_mode")
                                    issueModeActive = false
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "#f8f9fa"
                radius: 12

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 25
                    spacing: 15

                    Label { text: "发卡业务流程"; font.bold: true; font.pixelSize: 16 }
                    Label {
                        text: "1. 准备空白 M1/S50 系列卡片。\n2. 车载端识别卡片后将 UID 发送至此。\n3. 管理员核对信息并输入姓名。\n4. 点击写入，完成卡片与身份绑定。\n注：使用发卡注册功能需提前开启服务器监听功能"
                        lineHeight: 1.5
                        color: "#636e72"
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                    Item { Layout.fillHeight: true }
                }
            }
        }
    }
}
