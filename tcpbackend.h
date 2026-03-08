#ifndef TCPBACKEND_H
#define TCPBACKEND_H

#include <QObject>
#include <QTcpServer>
#include <QTcpSocket>
#include <QDebug>
#include "dbmanager.h"

class TcpBackend : public QObject
{
    Q_OBJECT

public:
    explicit TcpBackend(QObject *parent = nullptr);

    /*
     * 宏 让 QML 直接调用这个 C++ 函数
     * @port TCP 端口号
    */
    Q_INVOKABLE void startServer(int port);

signals:
    /*
     * 定义信号：当 C++ 收到消息或者有状态更新时，发信号给 QML
     * @msg 信息
    */
    void messageReceived(QString msg);

private slots:
    // C++ 内部处理新连接的槽
    void onNewConnection();
    // 处理收到树莓派设备数据的槽
    void onReadyRead();
    // 处理树莓派设备断开连接的槽
    void onDisconnected();

private:
    QTcpServer *m_server;
    DbManager m_db; // 给 TCP 后端配备数据库管理器
};

#endif // TCPBACKEND_H
