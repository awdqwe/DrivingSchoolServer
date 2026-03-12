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

    // 宏 让 QML 直接调用 C++ 函数
    // 开启接收(搜寻)服务
    Q_INVOKABLE void startServer(int port);
    // 查询
    Q_INVOKABLE QVariantList getHistoryRecords();

signals:
    // 当 C++ 收到消息或者有状态更新时 发信号给 QML
    void messageReceived(QString msg);
    // 当数据库有新数据存入时 发射信号给 QML
    void databaseUpdated();

private slots:
    // C++ 内部处理新连接的槽
    void onNewConnection();
    // 处理收到树莓派数据的槽
    void onReadyRead();
    // 处理树莓派断开连接的槽
    void onDisconnected();

private:
    QTcpServer *m_server;
    DbManager m_db; // TCP 后端的数据库管理器
};

#endif // TCPBACKEND_H
