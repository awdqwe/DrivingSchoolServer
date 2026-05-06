import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14

Rectangle {
    id: loginRoot
    gradient: Gradient {
        GradientStop { position: 0.0; color: "#2c3e50" }
        GradientStop { position: 0.5; color: "#34495e" }
        GradientStop { position: 1.0; color: "#22313f" }
    }

    signal loginSuccess(string username) // 登录成功信号，传递用户名
    property bool isRegisterMode: false

    // 几何图形装饰
    Rectangle {
        width: 260
        height: 260
        radius: 130
        color: "white"
        opacity: 0.04
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: -80
        rotation: 18
    }

    Rectangle {
        width: 180
        height: 180
        radius: 30
        color: "white"
        opacity: 0.06
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: -40
        rotation: 32
    }

    Rectangle {
        width: 120
        height: 120
        radius: 60
        color: "white"
        opacity: 0.03
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 60
    }
    // LOGO和标题
    Row {
        spacing: 18
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.margins: 45 // 顶部间距

        Image {
            source: "qrc:/res/ico/overlay.png"
            width: 296; height: 70
            fillMode: Image.PreserveAspectFit
            smooth: true
            anchors.verticalCenter: parent.verticalCenter
        }

        Column {
            spacing: 4 // 标题和副标题间距
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: 2 // 微调垂直位置
            Label {
                text: "驾校智能管理中枢"
                color: "white"
                font.pixelSize: 28; font.bold: true // 主标题
            }
            Label {
                text: "Driving School Smart Management Center"
                color: "white"
                font.pixelSize: 16 // 副标题
            }
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        width: 300; spacing: 20

        Label {
            text: isRegisterMode ? "管理员注册" : "管理中枢登录"
            color: "white"
            font.pixelSize: 24; Layout.alignment: Qt.AlignHCenter
        }

        TextField {
            id: userField; placeholderText: "用户名"
            Layout.fillWidth: true // 占满宽度
            maximumLength: 20
        }

        TextField {
            id: passField; placeholderText: "密码"
            echoMode: TextInput.Password; Layout.fillWidth: true
            maximumLength: 20
        }

        Button {
            text: isRegisterMode ? "注册" : "登录"
            Layout.fillWidth: true
            onClicked: {
                // 账号密码规范检查
                var username = userField.text.trim() 
                var password = passField.text.trim()
                if (username.length === 0) {
                    errorText.color = "#e74c3c"
                    errorText.text = "用户名不能为空"
                    return
                } else if (username.length < 1 || username.length > 20) {
                    errorText.color = "#e74c3c"
                    errorText.text = "用户名长度必须在1-20位之间"
                    return
                }

                if (password.length === 0) {
                    errorText.color = "#e74c3c"
                    errorText.text = "密码不能为空"
                    return
                } else if (password.length < 6 || password.length > 20) {
                    errorText.color = "#e74c3c"
                    errorText.text = "密码长度必须在6-20位之间"
                    return
                }

                if (isRegisterMode) {
                    var ok = backend.registerAdmin(userField.text, passField.text)
                    if (ok) {
                        errorText.color = "#2ecc71"
                        errorText.text = "注册成功，请登录"
                        isRegisterMode = false
                        // 清空输入框
                        userField.text = ""
                        passField.text = ""

                    } else {
                        errorText.color = "#e74c3c"
                        errorText.text = "注册失败（用户已存在）"
                    }
                } else {
                    if (backend.login(userField.text, passField.text)) {
                        loginRoot.loginSuccess(userField.text)
                    } else {
                        errorText.color = "#e74c3c"
                        errorText.text = "用户名或密码错误"
                    }
                }
            }
        }
        Button {
            text: isRegisterMode ? "返回登录" : "注册新账号"
            Layout.fillWidth: true

            onClicked: {
                isRegisterMode = !isRegisterMode
                errorText.text = ""
                userField.text = ""
                passField.text = ""
            }
        }
        // 错误提示
        Label { id: errorText; color: "#e74c3c"; Layout.alignment: Qt.AlignHCenter }
    }
}
