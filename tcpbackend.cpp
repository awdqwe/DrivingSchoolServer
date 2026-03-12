#include "tcpbackend.h"
#include <QJsonDocument>  // JSON 文档类
#include <QJsonObject>    // JSON 对象类
#include <QJsonParseError>// JSON 错误处理类

TcpBackend::TcpBackend(QObject *parent) : QObject(parent)
{
    m_server = new QTcpServer(this);

    // 当有新的客户端（树莓派）连接时，触发 onNewConnection 函数
    connect(m_server, &QTcpServer::newConnection, this, &TcpBackend::onNewConnection);

    // 初始化DB
    if (m_db.initDb()) {
        qDebug() << "TCP后端引擎：数据库挂载成功！";
    }
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
    // 获取和这个具体客户端通信的套接字
    QTcpSocket *socket = m_server->nextPendingConnection();

    // 【核心新增】给这个套接字接上两根“神经”
    // 1. 当套接字有数据发来时，触发 onReadyRead
    connect(socket, &QTcpSocket::readyRead, this, &TcpBackend::onReadyRead);
    // 2. 当套接字断开连接时，触发 onDisconnected
    connect(socket, &QTcpSocket::disconnected, this, &TcpBackend::onDisconnected);

    // 获取客户端的 IP 地址，发给前端显示
    QString clientIP = socket->peerAddress().toString();
    emit messageReceived("【上线通知】车辆终端已连接！IP: " + clientIP);
}
// 处理收到数据的逻辑
void TcpBackend::onReadyRead(){
    // 找出是哪个客户端发来的数据 (通过 sender() 转换)
    QTcpSocket *socket = qobject_cast<QTcpSocket*>(sender());
    if(!socket) return;

    // 读取所有发来的数据，并转换为字符串
    QByteArray data = socket->readAll();
    QString rawMsg = QString::fromUtf8(data);

    // 1 把收到的原始数据发给 QML 界面显示
    emit messageReceived("[收到车辆数据]: " + rawMsg);

    // 2 将收到的数据作为 JSON 进行解析
    QJsonParseError jsonError;
    QJsonDocument doc = QJsonDocument::fromJson(data, &jsonError);
    // 判断是否是合法的 JSON 对象格式 (期望格式{"CardID":"123", "Action":"上车"})
    if(jsonError.error == QJsonParseError::NoError && doc.isObject()){
        QJsonObject jsonObj = doc.object();

        // 提取 JSON 里的具体字段
        QString cardId = jsonObj.value("CardID").toString();
        QString action = jsonObj.value("Action").toString();
        int duration = jsonObj.value("Duration").toInt(); // 时长

        // 校验数据合法性：仅 卡号和动作都不为空 才存入数据库
        if(!cardId.isEmpty() && !action.isEmpty()){
            // 3 调用数据库管理器 执行存盘
            bool storageEnabled = m_db.insertRecord(cardId, action, duration);
            if (storageEnabled) {
                emit messageReceived(QString("[系统提示] [%1]数据解析成功，已存入数据库,时长:%2秒").arg(action).arg(duration));
                emit databaseUpdated(); // 通知QML
            }else{
                emit messageReceived("  -> [系统警告] 数据库存储失败！");
            }
        }else{
            emit messageReceived("  -> [警告] JSON 格式缺少必需的 CardID 或 Action 字段!");
        }
    }else{
        emit messageReceived("  -> [提示] 收到的非 JSON 标准格式数据，仅做展示，不存入数据库。");
    }
}

// 处理断开连接的逻辑
void TcpBackend::onDisconnected()
{
    QTcpSocket *socket = qobject_cast<QTcpSocket*>(sender());
    if(!socket) return;

    QString clientIP = socket->peerAddress().toString();
    emit messageReceived("【下线通知】车辆终端已断开！IP: " + clientIP);

    // 释放资源，防止内存泄漏 (非常好的编程习惯)
    socket->deleteLater();
}

// 获取数据
QVariantList TcpBackend::getHistoryRecords()
{
    return m_db.getAllRecords();
}
