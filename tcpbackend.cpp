#include "tcpbackend.h"
#include <QJsonDocument>  // JSON 文档类
#include <QJsonObject>    // JSON 对象类
#include <QJsonParseError>// JSON 错误处理类

TcpBackend::TcpBackend(QObject *parent) : QObject(parent)
{
    m_server = new QTcpServer(this);

    // 当有新的客户端（树莓派）连接时，触发 onNewConnection 函数
    connect(m_server, &QTcpServer::newConnection, this, &TcpBackend::onNewConnection);

    // 初始化数据库
    if(m_db.initDb()) qDebug() << "[TCP后端引擎]数据库挂载成功！";
        else qDebug() << "[TCP后端引擎]数据库挂载失败！";

}

// 启动服务器函数（供 QML 调用）
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

    // 为套接字接入触发逻辑
    // 1. 当套接字有数据发来时，触发 onReadyRead
    connect(socket, &QTcpSocket::readyRead, this, &TcpBackend::onReadyRead);
    // 2. 当套接字断开连接时，触发 onDisconnected
    connect(socket, &QTcpSocket::disconnected, this, &TcpBackend::onDisconnected);

    // 获取客户端IP
    QString clientIP = socket->peerAddress().toString();

    emit messageReceived("[上线通知]车辆终端已连接。IP: " + clientIP);

    // TODO 这里以后会写接收数据的逻辑
}

// 处理收到数据的逻辑
void TcpBackend::onReadyRead()
{
    // 找出收到的数据来源 (通过 sender() 转换)
    QTcpSocket *socket = qobject_cast<QTcpSocket*>(sender());
    if(!socket) return;

    // 读取所有发来的数据，并转换为字符串
    QByteArray data = socket->readAll();
    QString rawMsg = QString::fromUtf8(data);

    // 1 发送原始消息到 QML 界面
    emit messageReceived("[收到车辆数据]: " + rawMsg);

    // 2 解析数据
    QJsonParseError jsonError;
    QJsonDocument doc = QJsonDocument::fromJson(data, &jsonError);

    // 3 判断 json 数据合法性（格式）
    // 期望格式 {"CardID":"123", "Action":"上车"}
    if(jsonError.error == QJsonParseError::NoError && doc.isObject()){
        QJsonObject jsonObj = doc.object();

        QString cardId = jsonObj.value("CardID").toString();
        QString action = jsonObj.value("Action").toString();

        if(!cardId.isEmpty() && !action.isEmpty()){
            // 调用数据库管理器 执行存储
            bool alow_save = m_db.insertRecord(cardId,action);
            if(alow_save) emit messageReceived("  -> [系统提示] 数据解析成功，已存入 SQLite 数据库。");
                else emit messageReceived("  -> [系统提示] 数据解析失败！");
        } else {
            emit messageReceived("  -> [警告] JSON 缺少必需字段！");
        }

    } else {
        emit messageReceived("  -> [提示] 检测到非 JSON 标准格式数据。");
    }
}

// 处理断开连接的逻辑
void TcpBackend::onDisconnected()
{
    QTcpSocket *socket = qobject_cast<QTcpSocket*>(sender());
    if(!socket) return;

    QString clientIP = socket->peerAddress().toString();
    emit messageReceived("[下线通知]车辆终端已断开。IP: " + clientIP);

    // 释放资源，防止内存泄漏
    socket->deleteLater();
}
