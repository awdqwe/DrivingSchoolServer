// 系统日志
import QtQuick 2.14
import QtQuick.Layouts 1.14
import QtQuick.Controls 2.14

Item {
    id: logPage

    // 提供给外部调用的追加日志方法
    function appendLog(msg) {
        logArea.append("[%1] > %2".arg(Qt.formatDateTime(new Date(), "hh:mm:ss")).arg(msg))
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 30
        spacing: 15

        RowLayout {
            Layout.fillWidth: true
            Column {
                Label { text: "系统底层日志"; font.pixelSize: 22; font.bold: true }
                Label { text: "实时监控 TCP 通信原始报文与底层数据库事务"; color: "#7f8c8d" }
            }
            Item { Layout.fillWidth: true }
            Button {
                text: "清空日志"
                highlighted: true
                onClicked: logArea.clear()
            }
        }

        // 黑色控制台
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#1e1e1e"
            radius: 8
            border.color: "#333"

            ScrollView {
                anchors.fill: parent
                anchors.margins: 10
                clip: true

                TextArea {
                    id: logArea
                    readOnly: true
                    selectByMouse: true
                    selectionColor: "#3498db"
                    selectedTextColor: "white"
                    font.family: "Consolas"
                    font.pixelSize: 12
                    color: "#dcdcdc"
                    wrapMode: TextArea.WrapAnywhere

                    background: null // 去掉自带背景

                    // 自动滚动到底部
                    onTextChanged: {
                        cursorPosition = text.length
                    }
                }
            }
        }
    }
}
