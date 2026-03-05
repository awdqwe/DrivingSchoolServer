#include "tcpbackend.h"

TcpBackend::TcpBackend(QObject *parent) : QObject(parent)
{
    m_server = new QTcpServer(this);

    // 当有新的客户端（树莓派）连接时，触发 onNewConnection 函数
    connect(m_server, &QTcpServer::newConnection, this, &TcpBackend::onNewConnection);
}

// 供 QML 调用的启动服务器函数
void TcpBackend::startServer(int port)
{
    if(m_server->listen(QHostAddress::Any, port)) {
        // 启动成功，发信号给 QML 显示状态
        emit messageReceived("服务端已启动，正在监听端口: " + QString::number(port));
    } else {
        emit messageReceived("服务端启动失败！");
    }
}

// 处理新连接
void TcpBackend::onNewConnection()
{
    // 获取和客户端通信的套接字
    QTcpSocket *socket = m_server->nextPendingConnection();
    emit messageReceived("太棒了！有一个新客户端连接了！");

    // 这里以后会写接收数据的逻辑，今天先放着
}
