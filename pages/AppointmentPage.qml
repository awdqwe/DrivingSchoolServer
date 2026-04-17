// 练习预约
import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14

Item {
    id: appointPage
    property var backend
    
    //直接刷新 model
    function refresh() {
        appointList.model = backend.getAppointments()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 25
        spacing: 20

        Label {
            text: "学员练车预约申请"
            font.pixelSize: 24; font.bold: true
            color: "#333"
        }

        // 预约列表预览
        ListView {
            id: appointList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: backend.getAppointments()
            spacing: 10

            delegate: Rectangle {
                id: delegateRoot
                width: ListView.view.width
                height: 80

                property bool statusBusy: false
                property bool deleteBusy: false
                color: modelData.status === 0 ? "#FFF8E1" : "#F5F5F5"
                radius: 8
                border.color: modelData.status === 0 ? "#FFC107" : "#DDD"

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    
                    Column {
                        Layout.preferredWidth: 200
                        Label { text: modelData.name; font.bold: true; font.pixelSize: 18 }
                        Label { text: "卡号: " + modelData.card_id; color: "#666" }
                        Label { text: "收到时间: " + modelData.received_time; color: "#888"; font.pixelSize: 12 }
                    }

                    Label {
                        text: modelData.subject
                        Layout.preferredWidth: 100
                        font.pixelSize: 16
                        color: "#1976D2"
                    }

                    Label {
                        text: "预约时间: " + modelData.date
                        Layout.fillWidth: true
                        font.pixelSize: 16
                    }

                    Row {
                        spacing: 10
                        // 状态切换按钮
                        Button {
                            id: statusBtn
                            enabled: !delegateRoot.statusBusy // 切换状态时禁用按钮，防止重复点击

                            contentItem:Item {
                                implicitWidth: statusRow.implicitWidth
                                implicitHeight: statusRow.implicitHeight

                                Row {
                                    id: statusRow
                                    anchors.centerIn: parent
                                    spacing: 6
                                    BusyIndicator {
                                        running: delegateRoot.statusBusy
                                        visible: delegateRoot.statusBusy
                                        width: 16; height: 16
                                    }
                                    Text {
                                        text: delegateRoot.statusBusy ? "处理中..." : (modelData.status === 0 ? "标为已读" : "标为未读")
                                        color: "#333"
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                }
                            }
                            onClicked: {
                                delegateRoot.statusBusy = true
                                var delayCall = Qt.createQmlObject("import QtQuick 2.14; Timer { interval: 50; repeat: false }", delegateRoot);
                                delayCall.triggered.connect(function() {
                                    backend.updateAppointStatus(modelData.id, modelData.status === 0 ? 1 : 0);
                                    delayCall.destroy(); // 任务执行完销毁定时器
                                });
                                delayCall.start(); // 启动定时器，模拟异步处理
                            }
                        }

                        // 删除按钮
                        Button {
                            id: deleteBtn
                            enabled: !delegateRoot.deleteBusy
                            contentItem: Text {
                                text: "删除"
                                color: "#e74c3c"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            onClicked: deleteConfirmDialog.open()
                        }
                    }
                }

                // 删除确认对话框
                Dialog {
                    id: deleteConfirmDialog
                    parent: appointPage
                    x: (parent.width - width) / 2
                    y: (parent.height - height) / 2
                    width: 300
                    modal: true
                    title: "确认删除"
                    standardButtons: Dialog.NoButton

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 15
                        Label {
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            text: "确定删除学员 " + modelData.name + " 的预约申请吗？"
                        }
                        RowLayout {
                            Layout.alignment: Qt.AlignRight
                            Button {
                                text: "取消"
                                onClicked: deleteConfirmDialog.close()
                            }
                            Button {
                                text: "确定"
                                highlighted: true
                                onClicked: {
                                    deleteConfirmDialog.close()
                                    delegateRoot.deleteBusy = true
                                    backend.deleteAppoint(modelData.id)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    // 监听后端信号自动刷新，并重置忙碌标志
    Connections {
        target: backend
        onAppointmentsUpdated: refresh()
    }
}
