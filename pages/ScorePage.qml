// 成绩管理
import QtQuick 2.14
import QtQuick.Layouts 1.14
import QtQuick.Controls 2.14

Item {
    id: scorePage
    property var model: null

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
                    }
                }

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

                        // 及格判定逻辑（假设 90 分及格）
                        Rectangle {
                            Layout.preferredWidth: 80; height: 26; radius: 13
                            color: (model.score >= 90) ? "#e8f5e9" : "#ffebee"
                            Text {
                                anchors.centerIn: parent
                                text: (model.score >= 90) ? "合格" : "不合格"
                                color: (model.score >= 90) ? "#2e7d32" : "#c62828"
                                font.pixelSize: 12
                            }
                        }

                        Label { text: model.subject ? model.subject : "-"; Layout.preferredWidth: 120 }

                        Label { text: model.time; Layout.fillWidth: true; color: "#95a5a6" }
                    }
                }
            }
        }
    }
}
