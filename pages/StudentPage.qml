// 学员管理
import QtQuick 2.14
import QtQuick.Layouts 1.14
import QtQuick.Controls 2.14

Item {
    id: studentPage

    // 接收 main.qml 的模型和信号
    property var model: null
    signal actionRegister(string name, string card)
    signal actionDelete(string card)


    ListModel { id: filteredModel } // 本地过滤模型

    // 过滤函数
    function rebuildFiltered(){
        filteredModel.clear()
        if (!studentPage.model) return
        var q = searchInput.text ? searchInput.text.toLowerCase() : ""
        for (var i = 0; i < studentPage.model.count; i++){
            var item = studentPage.model.get(i)
            if (q === "" || (item.name && item.name.toLowerCase().indexOf(q) !== -1) || (item.card_id && item.card_id.toLowerCase().indexOf(q) !== -1)){
                // 显式拷贝角色，避免跨 ListModel 引用未按值复制导致_delegate 不更新
                filteredModel.append({
                    name: item.name,
                    card_id: item.card_id
                })
            }
        }
    }

    onModelChanged: rebuildFiltered() // 当外部 model 被替换时刷新列表

    // 同一 ListModel 引用下 clear/append 不会触发 onModelChanged，需监听 count
    Connections {
        target: studentPage.model
        function onCountChanged() { rebuildFiltered() }
    }

    Component.onCompleted: rebuildFiltered()

    onVisibleChanged: {
        if (visible)
            rebuildFiltered()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 30
        spacing: 20

        // 标题与搜索栏
        RowLayout {
            Layout.fillWidth: true
            Column {
                Label { text: "学员档案库"; font.pixelSize: 22; font.bold: true }
                Label { text: "管理所有已绑定的 RFID 学员卡信息"; color: "#7f8c8d" }
            }
            Item { Layout.fillWidth: true }

            TextField {
                id: searchInput
                placeholderText: "输入姓名或卡号搜索…"
                Layout.preferredWidth: 300
                background: Rectangle { radius: 20; border.color: "#dcdde1" }
                onTextChanged: rebuildFiltered()
            }

            // 简单过滤实现：基于传入的 model（学生列表）构建本地 filteredModel
            // 当外部 model 变化或输入框变化时调用 rebuildFiltered()

            Button {
                text: "新增学员"
                highlighted: true
                onClicked: registerPopup.open()
            }
        }

        // 学员列表表格容器
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "white"
            radius: 8
            border.color: "#e0e0e0"

            ColumnLayout {
                anchors.fill: parent; spacing: 0

                // 表头
                Rectangle {
                    Layout.fillWidth: true; height: 50; color: "#f8f9fa"; radius: 8
                    RowLayout {
                        anchors.fill: parent; anchors.margins: 15
                        Label { text: "学员姓名"; Layout.preferredWidth: 200; font.bold: true }
                        Label { text: "物理卡号 (UID)"; Layout.preferredWidth: 200; font.bold: true }
                        Label { text: "状态"; Layout.preferredWidth: 150; font.bold: true }
                        Item { Layout.fillWidth: true }
                        Label { text: "操作"; Layout.preferredWidth: 100; font.bold: true }
                    }
                }

                // 表体
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    ListView {
                        id: studentList
                        anchors.fill: parent
                        clip: true
                        model: filteredModel

                        delegate: Rectangle {
                            width: studentList.width; height: 60
                            color: index % 2 === 0 ? "white" : "#fafafa"

                            RowLayout {
                                anchors.fill: parent; anchors.margins: 15
                                Label { text: model.name; Layout.preferredWidth: 200; font.pixelSize: 14 }
                                Label { text: model.card_id; Layout.preferredWidth: 200; color: "#2980b9"; font.family: "Consolas" }
                                Rectangle {
                                    Layout.preferredWidth: 60; height: 24; radius: 12
                                    color: "#e8f5e9"
                                    Text { anchors.centerIn: parent; text: "正常"; color: "#2e7d32"; font.pixelSize: 11 }
                                }
                                Item { Layout.fillWidth: true }
                                Button {
                                    text: "删除"
                                    flat: true
                                    contentItem: Text { text: "删除"; color: "#e74c3c" }
                                    onClicked: {
                                        deleteConfirmDialog.cardToDelete = model.card_id
                                        deleteConfirmDialog.open()
                                    }
                                }
                            }
                        }
                    }

                    Label {
                        anchors.centerIn: parent
                        width: parent.width - 40
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        visible: filteredModel.count === 0
                        text: searchInput.text.length > 0
                              ? "未找到匹配的学员，请尝试其他关键词"
                              : "暂无学员记录。可点击「新增学员」录入，或在「发卡中心」绑卡。"
                        color: "#95a5a6"
                        font.pixelSize: 14
                    }
                }
            }
        }
    }

    // 新增学员弹窗（自定义按钮：校验未通过时不关闭）
    Dialog {
        id: registerPopup
        title: "录入新学员"
        standardButtons: Dialog.NoButton
        modal: true
        anchors.centerIn: parent
        width: 350

        ColumnLayout {
            width: parent.width
            spacing: 15
            TextField { id: nIn; placeholderText: "姓名"; Layout.fillWidth: true }
            TextField { id: cIn; placeholderText: "RFID卡号 (8位十六进制)"; Layout.fillWidth: true }
            RowLayout {
                Layout.alignment: Qt.AlignRight
                spacing: 8
                Button {
                    text: "取消"
                    onClicked: registerPopup.close()
                }
                Button {
                    text: "确定"
                    highlighted: true
                    onClicked: {
                        var nm = nIn.text.trim()
                        var cd = cIn.text.trim()
                        if (nm.length === 0 || cd.length === 0)
                            return
                        actionRegister(nm, cd)
                        nIn.text = ""
                        cIn.text = ""
                        registerPopup.close()
                    }
                }
            }
        }
    }

    Dialog {
        id: deleteConfirmDialog
        property string cardToDelete: ""
        title: "确认删除学员"
        standardButtons: Dialog.Ok | Dialog.Cancel
        anchors.centerIn: parent
        width: 360
        ColumnLayout {
            width: parent.width
            Label {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                text: deleteConfirmDialog.cardToDelete.length
                      ? ("确定从档案中删除卡号「" + deleteConfirmDialog.cardToDelete + "」对应的学员吗？此操作不可撤销。")
                      : ""
            }
        }
        onAccepted: {
            if (cardToDelete.length)
                actionDelete(cardToDelete)
            cardToDelete = ""
        }
        onRejected: cardToDelete = ""
    }
}
