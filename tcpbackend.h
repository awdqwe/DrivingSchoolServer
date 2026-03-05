#ifndef TCPBACKEND_H
#define TCPBACKEND_H

#include <QObject>
#include <QTcpServer>
#include <QTcpSocket>
#include <QDebug>

class TcpBackend : public QObject
{
    Q_OBJECT

public:
    explicit TcpBackend(QObject *parent = nullptr);

    // 这个宏极其重要！它能让 QML 直接调用这个 C++ 函数
    Q_INVOKABLE void startServer(int port);

signals:
    // 定义一个信号：当 C++ 收到消息或者有状态更新时，发信号给 QML
    void messageReceived(QString msg);

private slots:
    // C++ 内部处理新连接的槽函数
    void onNewConnection();

private:
    QTcpServer *m_server;
};

#endif // TCPBACKEND_H
