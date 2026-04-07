import QtQuick 2.14
import QtQuick.Layouts 1.14
import QtQuick.Controls 2.14

Rectangle {
    id: sideBar
    color: "#2c3e50" // 深色背景

    // 信号：通知 main.qml 切换 StackLayout 索引
    signal navClicked(int index)

    // 记录当前选中的索引 用于高亮
    property int currentIndex: 0

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 5

        // 系统标题区
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 80
            Column {
                anchors.centerIn: parent
                spacing: 5
                Label {
                    text: "驾校中枢系统"
                    color: "white"
                    font.pixelSize: 18
                    font.bold: true
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                Rectangle {
                    width: 40; height: 3
                    color: "#3498db"
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }

        // 模块按钮
        NavButton { text: "系统监控"; iconSource: "qrc:/res/ico/home.ico"; targetIndex: 0; currentIndex: sideBar.currentIndex; onClicked: { sideBar.currentIndex = targetIndex; sideBar.navClicked(targetIndex) } }
        NavButton { text: "学员档案"; iconSource: "qrc:/res/ico/student.ico"; targetIndex: 1; currentIndex: sideBar.currentIndex; onClicked: { sideBar.currentIndex = targetIndex; sideBar.navClicked(targetIndex) } }
        NavButton { text: "训练记录"; iconSource: "qrc:/res/ico/records.ico"; targetIndex: 2; currentIndex: sideBar.currentIndex; onClicked: { sideBar.currentIndex = targetIndex; sideBar.navClicked(targetIndex) } }
        NavButton { text: "实时监控"; iconSource: "qrc:/res/ico/eye.ico"; targetIndex: 3; currentIndex: sideBar.currentIndex; onClicked: { sideBar.currentIndex = targetIndex; sideBar.navClicked(targetIndex) } }
        NavButton { text: "数据统计"; iconSource: "qrc:/res/ico/statistics.ico"; targetIndex: 4; currentIndex: sideBar.currentIndex; onClicked: { sideBar.currentIndex = targetIndex; sideBar.navClicked(targetIndex) } }
        NavButton { text: "成绩管理"; iconSource: "qrc:/res/ico/score.ico"; targetIndex: 5; currentIndex: sideBar.currentIndex; onClicked: { sideBar.currentIndex = targetIndex; sideBar.navClicked(targetIndex) } }
        NavButton { text: "系统日志"; iconSource: "qrc:/res/ico/log.ico"; targetIndex: 6; currentIndex: sideBar.currentIndex; onClicked: { sideBar.currentIndex = targetIndex; sideBar.navClicked(targetIndex) } }
        NavButton { text: "发卡中心"; iconSource: "qrc:/res/ico/card.ico"; targetIndex: 7; currentIndex: sideBar.currentIndex; onClicked: { sideBar.currentIndex = targetIndex; sideBar.navClicked(targetIndex) } }
        NavButton { text: "练习预约"; iconSource: "qrc:/res/ico/home.ico"; targetIndex: 8; currentIndex: sideBar.currentIndex; onClicked: { sideBar.currentIndex = targetIndex; sideBar.navClicked(targetIndex) } }

        Item { Layout.fillHeight: true } // 弹簧 将按钮推向顶部

        Label {
            text: "v2.1.0 Stable"
            color: "#7f8c8d"
            font.pixelSize: 10
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: 10
        }
    }
}
