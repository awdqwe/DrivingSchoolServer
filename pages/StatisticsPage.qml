// 数据统计
import QtQuick 2.14
import QtQuick.Layouts 1.14
import QtQuick.Controls 2.14
import QtCharts 2.14

Item {
    id: statsPage
    signal refreshRequested()

    // 暴露图表组件给 main.qml 里的 Helpers 使用
    property alias chartSeries: barSeries
    property alias axisX: xAxis
    property alias axisY: yAxis

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 30
        spacing: 20

        RowLayout {
            Layout.fillWidth: true
            Label { text: "训练大数据统计"; font.pixelSize: 22; font.bold: true }
            Item { Layout.fillWidth: true }
            Button {
                text: "刷新排行"
                onClicked: refreshRequested()
            }
        }

        // 图表容器
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "white"
            radius: 12
            clip: true

            ChartView {
                id: chartView
                anchors.fill: parent
                antialiasing: true
                legend.alignment: Qt.AlignBottom
                theme: ChartView.ChartThemeLight

                BarSeries {
                    id: barSeries
                    name: "累计训练学时 (分钟)"
                    axisX: BarCategoryAxis { id: xAxis }
                    axisY: ValueAxis { id: yAxis; min: 0; max: 60; titleText: "分钟" }
                }
            }
        }

        // 底部统计说明
        RowLayout {
            Layout.fillWidth: true
            spacing: 20
            Rectangle {
                Layout.fillWidth: true; height: 80; color: "#fdf2e9"; radius: 8
                Label { anchors.centerIn: parent; text: "💡 统计逻辑：基于所有历史打卡记录的签到/签退差值计算"; color: "#e67e22" }
            }
        }
    }

    // 页面显示时自动刷新一次
    Component.onCompleted: refreshRequested()
}
