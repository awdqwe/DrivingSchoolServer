// 成绩管理
import QtQuick 2.14
import QtQuick.Layouts 1.14
import QtQuick.Controls 2.14

Item {
    id: scorePage
    property var model: null
    signal deleteScore(var item)
    property int pendingDeleteId: -1 // 待删除记录的 ID，避免 index 不一致问题
    property int pendingDeleteIndex: -1 // 待删除记录的 index，仅用于 UI 定位，实际删除通过 ID 进行

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 30
        spacing: 20

        Label { text: "理论考试成绩中枢"; font.pixelSize: 22; font.bold: true }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "white"
            radius: 8
            border.color: "#e0e0e0"

            ListView {
                id: scoreListView
                anchors.fill: parent
                model: scorePage.model
                clip: true
                header: Rectangle {
                    width: scoreListView.width; height: 50; color: "#f8f9fa"
                    RowLayout {
                        anchors.fill: parent; anchors.margins: 15
                        Label { text: "学员姓名"; Layout.preferredWidth: 150; font.bold: true }
                        Label { text: "得分 / 总分"; Layout.preferredWidth: 150; font.bold: true }
                        Label { text: "考核结果"; Layout.preferredWidth: 120; font.bold: true }
                        Label { text: "科目"; Layout.preferredWidth: 120; font.bold: true }
                        Label { text: "提交时间"; Layout.fillWidth: true; font.bold: true }
                        Label { text: "操作"; Layout.preferredWidth: 90; font.bold: true }
                    }
                }
                // 定义成绩记录的外观和布局
                delegate: Rectangle {
                    width: scoreListView.width; height: 55
                    color: index % 2 === 0 ? "white" : "#fafafa"

                    RowLayout {
                        anchors.fill: parent; anchors.margins: 15
                        Label { text: model.name; Layout.preferredWidth: 150; font.bold: true }
                        Label {
                            text: model.score + " / " + model.total
                            Layout.preferredWidth: 150
                            color: "#2980b9"
                            font.pixelSize: 16
                        }

                        // 及格判定逻辑（假设 8 分及格）
                        Rectangle {
                            Layout.preferredWidth: 80; height: 26; radius: 13
                            color: (model.score >= 8) ? "#e8f5e9" : "#ffebee"
                            Text {
                                anchors.centerIn: parent
                                text: (model.score >= 8) ? "合格" : "不合格"
                                color: (model.score >= 8) ? "#2e7d32" : "#c62828"
                                font.pixelSize: 12
                            }
                        }

                        Label { text: model.subject ? model.subject : "-"; Layout.preferredWidth: 120 }

                        Label { text: model.time; Layout.fillWidth: true; color: "#95a5a6" }
                        Button {
                            text: "删除"
                            Layout.preferredWidth: 80
                            onClicked: {
                                scorePage.pendingDeleteId = model.id
                                scorePage.pendingDeleteIndex = index
                                confirmDialog.open()
                            }
                        }
                    }
                }
            }
        }
    }

    Dialog {
        id: confirmDialog
        property int idToDelete: -1
        title: "确认删除成绩"
        standardButtons: Dialog.NoButton
        anchors.centerIn: parent
        width: 360

        ColumnLayout {
            width: parent.width
            spacing: 10

            Label {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                text: confirmDialog.idToDelete > 0
                      ? ("确定要删除 ID 为 " + confirmDialog.idToDelete + " 的理论成绩记录吗？此操作不可恢复。")
                      : "确定要删除该条理论成绩记录吗？此操作不可恢复。"
            }

            RowLayout {
                Layout.alignment: Qt.AlignRight
                spacing: 8

                Button {
                    text: "取消"
                    onClicked: {
                        confirmDialog.idToDelete = -1
                        confirmDialog.close()
                    }
                }

                Button {
                    text: "确定"
                    highlighted: true
                    onClicked: {
                        var id = confirmDialog.idToDelete
                        if (id > 0) {
                            var ok = backend.deleteTheoryResult(id)
                            if (ok) {
                                for (var i = 0; i < scoreListView.model.count; i++) {
                                    if (scoreListView.model.get(i).id === id) {
                                        scoreListView.model.remove(i)
                                        break
                                    }
                                }
                                confirmDialog.idToDelete = -1
                                confirmDialog.close()
                                return
                            }
                        }
                        errorDialog.text = "删除失败，请检查日志或稍后重试。"
                        errorDialog.open()
                    }
                }
            }
        }
    }

    Dialog {
        id: errorDialog
        title: "错误"
        standardButtons: Dialog.NoButton
        anchors.centerIn: parent
        width: 320

        ColumnLayout {
            width: parent.width
            spacing: 10
            Label { id: errLabel; Layout.fillWidth: true; wrapMode: Text.WordWrap; text: "" }
            RowLayout { Layout.alignment: Qt.AlignRight
                Button { text: "确定"; onClicked: errorDialog.close() }
            }
        }
        onOpened: { errLabel.text = errorDialog.text }
    }
}
