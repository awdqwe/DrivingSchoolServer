// 数据统计
import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14
import QtCharts 2.14
import "../qml_helpers.js" as Helpers
Item {
    id: statsPage

    // 与学员管理共用 ListModel；勿用 backend.getStudents() 直接作 model（绑定不会随库更新而重算）
    property var studentListModel: null

    property string selectedStudentId: ""
    function safeProgressForSubject(subjectName) {
        if (selectedStudentId === "")
            return 0

        var rawValue = backend.getStudentProgress(selectedStudentId, subjectName)
        var numericValue = Number(rawValue)
        if (!isFinite(numericValue))
            return 0

        return Math.max(0, Math.min(1, numericValue))
    }

    function validateStudentSelection() {
        if (!studentListModel || selectedStudentId === "")
            return
        var found = false
        for (var i = 0; i < studentListModel.count; i++) {
            if (studentListModel.get(i).card_id === selectedStudentId) {
                found = true
                break
            }
        }
        if (!found) {
            selectedStudentId = ""
            studentSelector.currentIndex = -1
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 30
        spacing: 25

        // 1. 顶部选择栏
        RowLayout {
            spacing: 15
            Label { text: "请选择学员查询进度:"; font.pixelSize: 18 }
            
            ComboBox {
                id: studentSelector
                Layout.preferredWidth: 250
                model: statsPage.studentListModel
                textRole: "name"
                onActivated: {
                    if (index < 0 || !statsPage.studentListModel)
                        return
                    selectedStudentId = statsPage.studentListModel.get(index).card_id
                    refreshProgress()
                }
            }
            
            Button {
                text: "刷新数据"
                onClicked: refreshProgress()
            }
        }

        // 2. 进度条展示区
        GridLayout {
            columns: 2
            Layout.fillWidth: true
            rowSpacing: 20; columnSpacing: 40
            visible: selectedStudentId !== ""

            // 定义重复项组件
            Repeater {
                model: ["科目一", "科目二", "科目三", "科目四"]
                
                ColumnLayout {
                    Layout.fillWidth: true
                    RowLayout {
                        Label { text: modelData; font.bold: true; font.pixelSize: 16 }
                        Item { Layout.fillWidth: true }
                        Label { 
                            text: Math.round(statsPage.safeProgressForSubject(modelData) * 100) + "%"
                        }
                    }

                    ProgressBar {
                        id: progBar
                        Layout.fillWidth: true
                        height: 15
                        value: statsPage.safeProgressForSubject(modelData) // 绑定后端进度（带类型兜底）
                        
                        background: Rectangle {
                            implicitHeight: 15
                            color: "#E0E0E0"
                            radius: 7
                        }
                        contentItem: Item {
                            Rectangle {
                                width: progBar.visualPosition * parent.width
                                height: parent.height
                                radius: 7
                                color: (modelData.indexOf("一") !== -1 || modelData.indexOf("四") !== -1) ? "#4CAF50" : "#2196F3"
                            }
                        }
                    }
                }
            }
        }

        // 3. 排行榜图表
        Label { text: "全校学时排行 (Top 5)"; font.bold: true; padding: 10 }
        Rectangle {
            Layout.fillWidth: true; Layout.fillHeight: true
            color: "#F9F9F9"; radius: 10; border.color: "#EEE"
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
    }

    Component.onCompleted: {
        Helpers.refreshChart(barSeries, xAxis, yAxis, backend)
    }

    Connections {
        target: backend
        function onStudentsUpdated() {
            validateStudentSelection()
            Helpers.refreshChart(barSeries, xAxis, yAxis, backend)
        }
        function onDatabaseUpdated() {
            Helpers.refreshChart(barSeries, xAxis, yAxis, backend)
        }
    }

    function refreshProgress() {
        // 仅触发重新绑定：强制刷新 selectedStudentId 的值即可
        if (selectedStudentId === "") return
            var temp = selectedStudentId
            selectedStudentId = ""
            selectedStudentId = temp
    }
}
