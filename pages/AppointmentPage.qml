// 练习预约
import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14

Item {
    id: appointPage
    property var backend
    
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
                width: ListView.view.width
                height: 80
                color: modelData.status === 0 ? "#FFF8E1" : "#F5F5F5" // 未读显示黄色
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
                        Button {
                            text: modelData.status === 0 ? "标为已读" : "标为未读"
                            onClicked: {
                                backend.updateAppointStatus(modelData.id, modelData.status === 0 ? 1 : 0)
                                appointPage.refresh()
                            }
                        }
                        Button {
                            text: "删除"
                            palette.buttonText: "red"
                            onClicked: {
                                backend.deleteAppoint(modelData.id)
                                appointPage.refresh()
                            }
                        }
                    }
                }
            }
        }
    }

    // 监听后端信号自动刷新
    Connections {
        target: backend
        onAppointmentsUpdated: refresh()
    }
}
