// 配置管理
import QtQuick 2.14
import QtQuick.Layouts 1.14
import QtQuick.Controls 2.14

ScrollView {
    clip: true
    id: settingPage
    contentWidth: width
    signal saveConfig()

    ColumnLayout {
        width: parent.width - 60
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 30
        spacing: 25

        Label { text: "系统配置管理"; font.pixelSize: 22; font.bold: true }

        // 配置组 1: 网络通信
        GroupBox {
            title: "网络通信设置"
            Layout.fillWidth: true
            ColumnLayout {
                anchors.fill: parent; spacing: 10
                RowLayout {
                    Label { text: "TCP 监听端口: "; Layout.preferredWidth: 100 }
                    TextField { text: "8888"; Layout.preferredWidth: 150 }
                }
                Label { text: "提示：修改端口需要重启服务器方可生效。"; color: "#95a5a6"; font.pixelSize: 12 }
            }
        }

        // 配置组 2: 数据库管理
        GroupBox {
            title: "数据安全与维护"
            Layout.fillWidth: true
            RowLayout {
                anchors.fill: parent; spacing: 20
                Button {
                    text: "备份当前数据库"
                    onClicked: console.log("执行 sqlite 备份逻辑")
                }
                Button {
                    text: "清理训练记录"
                    contentItem: Text { text: "清理训练记录"; color: "red" }
                }
            }
        }

        // 配置组 3: 关于系统
        GroupBox {
            title: "关于系统"
            Layout.fillWidth: true
            ColumnLayout {
                anchors.fill: parent; spacing: 8
                Label { text: "驾校智能车载终端与管理中枢系统"; font.bold: true }
                Label { text: "软件版本: V2.1.0 (Stable Build)" }
                Label { text: "硬件支持: 树莓派 4B + MFRC522" }
                Label { text: "© 2024 毕业设计作品 版权所有" }
            }
        }

        Item { Layout.preferredHeight: 50 } // 底部留白
    }
}
