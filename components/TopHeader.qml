// 顶部状态栏
import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14

Rectangle {
    property int recordCount: 0
    property bool serverStatus: false
    color: "white"

    RowLayout {
        anchors.fill: parent; anchors.margins: 20
        Label {
            text: "驾校智能化管理后台"; font.pixelSize: 18; font.bold: true
        }
        Item { Layout.fillWidth: true }
        Rectangle {
            width: 12; height: 12; radius: 6
            color: serverStatus ? "#2ecc71" : "#e74c3c"
        }
        Label { text: serverStatus ? "服务器已就绪" : "服务器未启动" }
        Label { text: " | 历史总记: " + recordCount + "条" }
    }
}
