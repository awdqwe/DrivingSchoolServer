#ifndef TCPBACKEND_H
#define TCPBACKEND_H

#include <QObject>
#include <QDateTime>
#include <QTimer>
#include <QTcpServer>
#include <QTcpSocket>
#include <QDebug>
#include <QJsonObject>
#include "dbmanager.h"

class TcpBackend : public QObject
{
    Q_OBJECT

public:
    explicit TcpBackend(QObject *parent = nullptr);

    // 供 QML 调用的启动服务器函数
    Q_INVOKABLE void startServer(int port);
    Q_INVOKABLE QVariantList getHistoryRecords();
    Q_INVOKABLE bool registerNewStudent(const QString &cardId, const QString &name);
    Q_INVOKABLE QVariantList getLeaderboard() { return m_db.getLeaderboard(); }
    Q_INVOKABLE QVariantList getTheoryScores() { return m_db.getTheoryScores(); }
    Q_INVOKABLE bool deleteTheoryResult(int id); // 删除指定的理论成绩记录
    Q_INVOKABLE QVariantList getStudents();
    Q_INVOKABLE bool updateStudentName(const QString &cardId, const QString &newName);
    Q_INVOKABLE double getStudentProgress(const QString &cardId, const QString &subject);
    Q_INVOKABLE bool deleteStudent(const QString cardId);
    Q_INVOKABLE QVariantList getActiveSessions();
    Q_INVOKABLE QVariantList getConnectedDevices();

    // 预约相关接口（供 QML 调用）
    Q_INVOKABLE QVariantList getAppointments();
    Q_INVOKABLE bool updateAppointStatus(int appointmentId, int newStatus);
    Q_INVOKABLE bool deleteAppoint(int appointmentId);

    Q_INVOKABLE bool login(QString username, QString password);
    Q_INVOKABLE bool registerAdmin(QString username, QString password);

    Q_INVOKABLE void exportToCSV();
    Q_INVOKABLE void exportToCSV(const QString &filePath);
    Q_INVOKABLE void sendControlCommand(QString cmd);
    Q_INVOKABLE void sendControlToDevice(QString deviceId, QString cmd);

    struct SessionInfo {
        QString cardId;
        QDateTime lastSeen;
        QDateTime startTime;
        QString subject;
    };
    QMap<QString, SessionInfo> m_activeSessions;
    QTimer *m_checkTimer;

signals:
    void messageReceived(QString msg);
    void databaseUpdated();
    void appointmentsUpdated();
    void studentsUpdated();
    void devicesUpdated();
    void newCardDetected(QString cardId, QString status, QString name);

private slots:
    void onNewConnection();
    void onReadyRead();
    void onDisconnected();

private:
    QTcpServer *m_server;
    DbManager m_db;
    QHash<QTcpSocket*, QByteArray> m_buffers; // 每个 socket 对应一个缓冲区
    QMap<QString, QTcpSocket*> m_deviceMap;
    QMap<QTcpSocket*, QString> m_socketDeviceKey;
    bool verifySignature(const QJsonObject &obj);
    QString secretKey = "HelloWorldDrivingSchool@2026_Pi4B";
};

#endif // TCPBACKEND_H
