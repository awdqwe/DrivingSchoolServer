#ifndef TCPBACKEND_H
#define TCPBACKEND_H

#include <QObject>
#include <QDateTime>
#include <QTimer>
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
    // 新增
    Q_INVOKABLE bool registerNewStudent(const QString &cardId, const QString &name);
    // 获取排行榜数据
    Q_INVOKABLE QVariantList getLeaderboard(){ return m_db.getLeaderboard(); }
    // 获取理论成绩
    Q_INVOKABLE QVariantList getTheoryScores() { return m_db.getTheoryScores(); }
    // 查询/删除学员
    Q_INVOKABLE QVariantList getStudents();
    Q_INVOKABLE bool deleteStudent(const QString cardId);
    Q_INVOKABLE QVariantList getActiveSessions();
    // 登录
    Q_INVOKABLE bool login(QString username, QString password);
    Q_INVOKABLE bool registerAdmin(QString username, QString password);

    Q_INVOKABLE void exportToCSV();
    Q_INVOKABLE void sendControlCommand(QString cmd);

    struct SessionInfo {
      QString cardId;
      QDateTime lastSeen;
      QDateTime startTime;
    };
    QMap<QString, SessionInfo> m_activeSessions; // 记录每个设备的会话信息
    QTimer *m_checkTimer; // 检查超时的定时器

signals:
    // 当 C++ 收到消息或者有状态更新时 发信号给 QML
    void messageReceived(QString msg);
    // 当数据库有新数据存入时 发射信号给 QML
    void databaseUpdated();
    void studentsUpdated();
    // 新卡
    void newCardDetected(QString cardId);

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
    QHash<QTcpSocket*, QByteArray> m_buffers; // 接收缓冲区(防止粘包)
    bool verifySignature(const QJsonObject &obj); //安全校验
    // salt 盐值
    QString secretKey = "HelloWorldDrivingSchool@2026_Pi4B";
};

#endif // TCPBACKEND_H
