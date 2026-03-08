import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.12
import QtQuick.VirtualKeyboard 2.4
import Backend 1.0 // 在 main.cpp 里注册的 TCP相关 模块

Window {
    id: window
    visible: true
    width: 640
    height: 480
    title: qsTr("驾校学车系统 - 服务端控制台")
    color: "#f5f6fa" // 背景色 灰

    // 实例化 C++ 的类
    TcpBackend {
        id: backend
        // 接收 C++ 发过来的信号 tcpbackend.h: line 21
        onMessageReceived: {
            logArea.append("> " + msg) // 加入到日志
        }
    }

    // 界面布局 垂直排列
    Column {
        anchors.centerIn: parent
        spacing: 20
        // 启动按钮
        Button {
            text: "启动 TCP 服务端"
            width: 200
            height: 50
            anchors.horizontalCenter: parent.horizontalCenter
            // 按钮点击事件
            onClicked: {
                // 直接调用 C++ 里的 startServer 函数，并传入端口号 8888
                backend.startServer(8888)
                enabled = false // 点击一次即禁用按钮，防止重复启动
                text = "运行中 (端口: 8888)..."
            }
        }

        // 日志显示区域 (带滚动条)
        ScrollView {
            width: 480
            height: 250

            TextArea {
                id: logArea
                readOnly: true
                text: "系统初始化完毕，等待操作...\n"
                font.pixelSize: 14
                background: Rectangle {
                    color: "white"
                    radius: 8
                    border.color: "#dcdde1"
                }
            }
        }
    }
}
