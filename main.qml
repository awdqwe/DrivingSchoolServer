import QtQuick 2.14
import QtQuick.Window 2.14
import QtQuick.Controls 2.14
import QtCharts 2.14
import QtQuick.Layouts 1.14 // 引入专业布局模块
import Backend 1.0
import "qml_helpers.js" as Helpers
Window {
    visible: true
    width: 1200  // 窗口
    height: 600
    title: qsTr("驾校智能车载终端与管理中枢 - 实时监控系统")
    color: "#f0f2f5" // 底色 灰白

    property bool serverRunning: false // 按键状态

    // 负责存储和提供给表格显示的数据模型
    ListModel { id: historyModel }
    ListModel { id: theoryModel }
    ListModel { id: activeSessionModel }

    Timer {
        interval: 1000 // 1秒
        running: serverRunning // 只有服务器启动后才开始计时
        repeat: true
        onTriggered: {
            var sessions = backend.getActiveSessions();
            activeSessionModel.clear();
            for(var i = 0; i < sessions.length; i++) {
                activeSessionModel.append(sessions[i]);
            }
        }
    }

    TcpBackend {
        id: backend
        onMessageReceived: logArea.append("> " + msg)

        // 当收到 C++ 发来的数据库更新信号时，自动刷新界面表格
        onDatabaseUpdated: { 
            Helpers.refreshTable(historyModel, backend)
            Helpers.refreshChart(barSeries, xAxis, yAxis, backend)
            Helpers.refreshTheoryTable(theoryModel, backend)
        }
    }

    // 页面刚加载完毕时，查一次 显示历史记录
    Component.onCompleted: {
        Helpers.refreshTable(historyModel, backend)
        Helpers.refreshChart(barSeries, xAxis, yAxis, backend)
        Helpers.refreshTheoryTable(theoryModel, backend)
    }

    // 主布局
    RowLayout {
        anchors.fill: parent

        // ================= 左侧导航栏 =================
        Rectangle {
            Layout.preferredWidth: 200
            Layout.fillHeight: true
            color: "#2c3e50"

            Column {
                anchors.fill: parent
                anchors.margins: 15
                spacing: 15

                Label {
                    text: "驾校管理系统"
                    color: "white"
                    font.pixelSize: 20
                    font.bold: true
                }

                Button {
                    text: "系统监控"
                    onClicked: stack.currentIndex = 0
                }

                Button {
                    text: "训练记录"
                    onClicked: stack.currentIndex = 1
                }

                Button {
                    text: "学员管理"
                    onClicked: stack.currentIndex = 2
                }

                Button {
                    text: "数据统计"
                    onClicked: stack.currentIndex = 3
                }
            }
        }

        // ================= 右侧内容区域 =================
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // ===== 顶部状态栏 =====
            Rectangle {
                Layout.fillWidth: true
                height: 50
                color: "#ecf0f1"

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10

                    Label {
                        text: "驾校智能车载终端与管理系统"
                        font.pixelSize: 18
                        font.bold: true
                    }

                    Item { Layout.fillWidth: true }

                    Label {
                        text: "数据库记录数: " + historyModel.count
                    }
                }
            }

            // ===== 页面切换区域 =====
            StackLayout {
                id: stack
                Layout.fillWidth: true
                Layout.fillHeight: true

                // ================= 页面1 系统监控 =================
                Item {

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 30

                        Label {
                            text: "系统运行状态"
                            font.pixelSize: 28
                            font.bold: true
                        }

                        Label {
                            text: "服务器端口: 8888"
                            font.pixelSize: 20
                        }

                        Label {
                            text: "历史训练记录: " + historyModel.count
                            font.pixelSize: 20
                        }

                        Button {
                            text: serverRunning ? "服务器运行中 (端口 8888)" : "启动 TCP 服务端"
                            enabled: !serverRunning  // 运行中禁用
                            onClicked: {
                                backend.startServer(8888)
                                serverRunning = true
                            }
                        }

                        // 打开弹窗
                        Button {
                            text: "注册新学员"
                            Layout.fillWidth: true
                            Layout.preferredHeight: 50
                            font.pixelSize: 16
                            background: Rectangle {color: "#3498DB"; radius: 6}
                            contentItem: Text {
                                color: "white"
                                text: parent.text
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            onClicked: registerDialog.open()
                        }
                    }
                }

                // ================= 页面2 训练记录 =================
                Item {

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 20

                        // 左侧日志
                        ColumnLayout {
                            Layout.preferredWidth: 320
                            Layout.fillHeight: true
                            spacing: 10

                            Label {
                                text: "● 实时在线车辆 (" + activeSessionModel.count + ")"
                                color: activeSessionModel.count > 0 ? "#2ecc71" : "#95a5a6"
                                font.bold: true
                            }

                            ListView {
                                id: activeSessionView
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                spacing: 8
                                model: activeSessionModel
                                clip: true

                                delegate: Rectangle {
                                    width: activeSessionView.width - 10
                                    height: 80
                                    color: "white"
                                    radius: 8
                                    border.color: "#e0e0e0"

                                    RowLayout {
                                        anchors.fill: parent; anchors.margins: 10
                                        
                                        // 左侧图标（模拟车牌或车辆）
                                        Rectangle {
                                            width: 40; height: 40; radius: 20
                                            color: "#3498db"
                                            Text { text: "🚗"; anchors.centerIn: parent }
                                        }

                                        Column {
                                            Layout.fillWidth: true
                                            Label { text: "设备: " + model.device_id; font.bold: true; font.pixelSize: 13 }
                                            Label { text: "学员: " + model.card_id; color: "#666"; font.pixelSize: 12 }
                                            Label { 
                                                text: "已练习: " + model.duration_mins + " 分钟"
                                                color: "#e67e22"; font.pixelSize: 11; font.bold: true 
                                            }
                                        }
                                    }
                                }
                            }

                            Button {
                                text: "查看底层原始日志"
                                Layout.fillWidth: true
                                flat: true
                                onClicked: logDialog.open()
                            }

                            ScrollView {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 150

                                TextArea {
                                    id: logArea
                                    readOnly: true
                                    wrapMode: Text.WrapAnywhere // 强制在任何地方换行，防止长 JSON 撑开宽度
                                    clip: true                 // 裁剪超出范围的内容
                                    // 自动滚动
                                    onTextChanged: {
                                        cursorPosition = text.length
                                    }
                                    background: Rectangle {
                                        color: "#1e1e1e" // 控制台背景
                                        radius: 4
                                    }
                                    color: "#dcdcdc"
                                    font.family: "Consolas" // 使用等宽字体
                                    font.pixelSize: 12
                                }
                            }
                        }

                        // 右侧数据库表格 理论成绩
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: 15

                            RowLayout {
                                Label {
                                    text: "打卡历史记录"
                                    font.pixelSize: 18; font.bold: true; color: "#2c3e50"
                                }

                                Item { Layout.fillWidth: true }

                                Button {
                                    text: "刷新"
                                    onClicked:{ // 刷新表格与图表
                                        Helpers.refreshTable(historyModel, backend)
                                        // Helpers.refreshChart(barSeries, xAxis, yAxis, backend)
                                        Helpers.refreshTheoryTable(theoryModel, backend)
                                    }
                                }
                            }

                            // 打卡历史记录 表格 
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 6
                                color: "transparent"
                                border.color: "#dcdde1"

                                ColumnLayout {
                                    anchors.fill: parent
                                    spacing: 0
                                    // 表头
                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 40
                                        color: "#dcdde1"
                                        RowLayout {
                                            anchors.fill: parent; anchors.margins: 15
                                            Label { text: "ID"; Layout.preferredWidth: 40; font.bold: true }
                                            Label { text: "姓名"; Layout.preferredWidth: 100; font.bold: true }
                                            Label { text: "卡号"; Layout.preferredWidth: 100; font.bold: true }
                                            Label { text: "动作"; Layout.preferredWidth: 90; font.bold: true }
                                            Label { text: "时长"; Layout.preferredWidth: 80 ; font.bold: true}
                                            Label { text: "时间"; Layout.fillWidth: true; font.bold: true }
                                        }
                                    }
                                    // 主体
                                    ListView {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        model: historyModel
                                        clip: true

                                        delegate: Rectangle {
                                            width: ListView.view.width
                                            height: 45
                                            color: index % 2 ? "#f9f9f9" : "#ffffff"
                                            border.color: "#eeeeee"
                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.margins: 15
                                                Label { text: model.id; Layout.preferredWidth: 40; color: "#7f8c8d" }
                                                Label { text: model.student_name; Layout.preferredWidth: 100; font.bold: true; color: "#8e44ad" }
                                                Label { text: model.card_id; Layout.preferredWidth: 100; font.bold: true; color: "#2980b9" }
                                                Label {
                                                    text: model.action
                                                    Layout.preferredWidth: 90
                                                    font.bold: true
                                                    color: model.action === "上车签到" ? "green" :
                                                           model.action === "下车签退" ? "orange" : "red"
                                                }
                                                Label {
                                                    text: model.duration > 0 ? model.duration + " 秒" : "--"
                                                    Layout.preferredWidth: 80
                                                    font.bold: true; color: "#e1b12c"
                                                }

                                                Label { text: model.timestamp; Layout.fillWidth: true; color: "#95a5a6" }
                                            }
                                        }
                                    }
                                }
                            }

                            Label {
                                text: "理论考试成绩汇总"
                                font.pixelSize: 18; font.bold: true; color: "#2c3e50"
                            }
                            Rectangle {
                                Layout.fillWidth: true; Layout.preferredHeight: 200
                                radius: 6; border.color: "#dcdde1"
                                ListView {
                                    anchors.fill: parent; model: theoryModel; clip: true
                                    header: Rectangle {
                                        width: parent.width; height: 30; color: "#f0f0f0"
                                        RowLayout {
                                            anchors.fill: parent; anchors.margins: 10
                                            Label { text: "姓名"; Layout.preferredWidth: 100; font.bold: true }
                                            Label { text: "得分"; Layout.preferredWidth: 80; font.bold: true }
                                            Label { text: "总分"; Layout.preferredWidth: 80; font.bold: true }
                                            Label { text: "提交时间"; Layout.fillWidth: true; font.bold: true }
                                        }
                                    }
                                    delegate: Item {
                                        width: parent.width; height: 35
                                        RowLayout {
                                            anchors.fill: parent; anchors.margins: 10
                                            Label { text: model.name; Layout.preferredWidth: 100 }
                                            Label { text: model.score; Layout.preferredWidth: 80; color: "blue"; font.bold: true }
                                            Label { text: model.total; Layout.preferredWidth: 80 }
                                            Label { text: model.time; Layout.fillWidth: true }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // ================= 页面3 学员管理 =================
                Item {
                    id: studentPage
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 12

                        Label {
                            text: "学员管理模块"
                            font.pixelSize: 24
                            font.bold: true
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            // 搜索 / 过滤
                            TextField {
                                id: searchField
                                placeholderText: "按姓名或卡号搜索"
                                Layout.preferredWidth: 300
                                onTextChanged: {
                                    // 简单客户端过滤
                                    studentsModel.clear()
                                    var all = backend.getStudents(); // 预计假设返回 array of {card_id, name}
                                    for (var i=0;i<all.length;i++){
                                        var s = all[i];
                                        if (searchField.text === "" ||
                                            s.name.indexOf(searchField.text) !== -1 ||
                                            s.card_id.indexOf(searchField.text) !== -1) {
                                            studentsModel.append(s);
                                        }
                                    }
                                }
                            }

                            Item { Layout.fillWidth: true }

                            Button {
                                text: "刷新列表"
                                onClicked: {
                                    studentPage.refreshStudents()
                                }
                            }
                        }

                        // 学员列表
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 320
                            radius: 6
                            color: "transparent"
                            border.color: "#dcdde1"

                            ListView {
                                id: studentsListView
                                anchors.fill: parent
                                model: studentsModel
                                clip: true
                                delegate: Rectangle {
                                    width: ListView.view.width
                                    height: 48
                                    color: index % 2 ? "#ffffff" : "#fbfbfb"
                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 12
                                        spacing: 10

                                        Label { text: model.name; Layout.preferredWidth: 180; font.bold: true; color: "#2c3e50" }
                                        Label { text: model.card_id; Layout.preferredWidth: 160; color: "#2980b9" }
                                        Item { Layout.fillWidth: true }
                                        Button {
                                            text: "删除"
                                            background: Rectangle { color: "#e74c3c"; radius: 4 }
                                            contentItem: Text { color: "white"; text: parent.text; horizontalAlignment: Text.AlignHCenter }
                                            onClicked: {
                                                confirmDeleteDialog.cardIdToDelete = model.card_id;
                                                confirmDeleteDialog.studentName = model.name;
                                                confirmDeleteDialog.open();
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // 新增学员区域
                        Rectangle {
                            Layout.fillWidth: true
                            color: "#ffffff"
                            radius: 6
                            border.color: "#e6e6e6"
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 10

                                TextField {
                                    id: newName
                                    placeholderText: "姓名"
                                    Layout.preferredWidth: 240
                                }
                                TextField {
                                    id: newCard
                                    placeholderText: "卡号 (例如 A1B2C3D4)"
                                    Layout.preferredWidth: 240
                                }
                                Button {
                                    text: "新增学员"
                                    background: Rectangle { color: "#27ae60"; radius: 6 }
                                    contentItem: Text { color: "white"; text: parent.text; horizontalAlignment: Text.AlignHCenter }
                                    onClicked: {
                                        if (newName.text === "" || newCard.text === "") {
                                            logArea.append("> [错误] 姓名或卡号不能为空！");
                                            return;
                                        }
                                        var ok = backend.registerNewStudent(newCard.text, newName.text);
                                        if (ok) {
                                            logArea.append("> [系统] 学员 " + newName.text + " 注册成功！");
                                            newName.text = "";
                                            newCard.text = "";
                                            studentPage.refreshStudents();
                                        } else {
                                            logArea.append("> [错误] 注册失败，可能卡号已存在。");
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // 本地 students 模型
                    ListModel { id: studentsModel }

                    // 删除确认弹窗
                    Dialog {
                        id: confirmDeleteDialog
                        title: "确认删除学员"
                        property string cardIdToDelete: ""
                        property string studentName: ""
                        standardButtons: Dialog.Ok | Dialog.Cancel
                        onAccepted: {
                            if (cardIdToDelete !== "") {
                                var ok = backend.deleteStudent(cardIdToDelete);
                                if (ok) {
                                    logArea.append("> [系统] 已删除学员 " + studentName + " (" + cardIdToDelete + ")");
                                    studentPage.refreshStudents();
                                } else {
                                    logArea.append("> [错误] 删除学员失败");
                                }
                            }
                        }
                        Text {
                            text: "确定删除学员 " + confirmDeleteDialog.studentName + " (" + confirmDeleteDialog.cardIdToDelete + ") 吗？"
                            wrapMode: Text.WordWrap
                            width: parent.width - 40
                        }
                    }

                    // 刷新函数：从 backend 拉取学员列表并填充 studentsModel
                    function refreshStudents() {
                        studentsModel.clear();
                        var arr = backend.getStudents(); // 期望返回 JS 数组 [{card_id:"", name:""}, ...]
                        for (var i=0;i<arr.length;i++){
                            studentsModel.append(arr[i]);
                        }
                    }

                    // 当 C++ 发出 studentsUpdated 信号时自动刷新
                    Connections {
                        target: backend
                        onStudentsUpdated: {
                            refreshStudents();
                        }
                    }

                    // 页面首次显示时加载(组件初始化)
                    Component.onCompleted: {
                        refreshStudents();
                    }
                }


                // ================= 页面4 数据统计 =================
                Item {

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 25

                        Label {
                            text: "训练数据统计"
                            font.pixelSize: 28
                            font.bold: true
                        }

                        Label {
                            text: "累计训练记录: " + historyModel.count
                            font.pixelSize: 20
                        }

                        ChartView {
                            id: leaderboardChart
                            title: "学员累计学时排行榜"
                            titleFont.pixelSize: 16
                            titleFont.bold: true
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            antialiasing: true
                            theme: ChartView.ChartThemeLight
                            margins { top: 10; bottom: 10; left: 10; right: 10 }

                            // 背景美化
                            backgroundColor: "#ffffff"
                            dropShadowEnabled: true

                            // 看板
                            BarSeries {
                                id: barSeries
                                axisX: BarCategoryAxis {
                                    id: xAxis
                                    labelsFont.pixelSize: 12
                                }
                                axisY: ValueAxis {
                                    id: yAxis
                                    min: 0
                                    max: 100
                                    titleText: "总计学时 (秒)"
                                    labelFormat: "%d"
                                }
                            }
                        }

                    }
                }
            }
        }
    }

    // 学员发卡注册弹窗
    Dialog {
        id: registerDialog
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        width: 400
        height: 300
        title: "学员开户与发卡"
        standardButtons: Dialog.Save | Dialog.Cancel

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 20

            TextField {
                id: nameInput
                placeholderText: "请输入学员姓名"
                Layout.fillWidth: true
                font.pixelSize: 16
            }

            TextField {
                id: cardInput
                placeholderText: "请输入物理卡号 (如 A1B2C3D4)"
                Layout.fillWidth: true
                font.pixelSize: 16
            }

            Label {
                text: "提示: 请先在车载端刷未注册的卡获取卡号"
                color: "#7f8c8d"
                font.pixelSize: 12
            }
        }

        onAccepted: {
            if (nameInput.text === "" || cardInput.text === "") {
                logArea.append("> [错误] 姓名或卡号不能为空！")
                return
            }
            // 调用 C++ 的注册函数
            var success = backend.registerNewStudent(cardInput.text, nameInput.text)
            if (success) {
                logArea.append("> [系统] 学员 " + nameInput.text + " 注册成功！")
            } else {
                logArea.append("> [错误] 注册失败，可能卡号已存在。")
            }
            nameInput.text = ""
            cardInput.text = ""
        }
    }
    // 显示日志窗
    Dialog {
        id: logDialog
        title: "底层通信原始日志 (JSON)"
        width: 800
        height: 500
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        standardButtons: Dialog.Close

        ScrollView {
            anchors.fill: parent
            TextArea {
                text: logArea.text // 同步主界面的日志内容
                readOnly: true
                font.family: "Consolas"
                background: Rectangle { color: "#f5f5f5" }
            }
        }
    }

}
