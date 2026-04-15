import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14

Rectangle {
    id: loginRoot
    color: "#2c3e50"
    signal loginSuccess(string username) // 登录成功信号，传递用户名

    property bool isRegisterMode: false

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


        Label { id: errorText; color: "#e74c3c"; Layout.alignment: Qt.AlignHCenter }
    }
}
