#include "tcpbackend.h"
#include <QJsonDocument>  // JSON 文档类
#include <QJsonObject>    // JSON 对象类
#include <QJsonParseError>// JSON 错误处理类
#include <QCryptographicHash>
#include <QDebug>
#include <QFile>

// 辅助函数 加盐哈希
#include <QCryptographicHash>
QString hashPassword(const QString &pass) {
    QString salt = "DrivingSchool_Admin_2024"; // 内部盐值
    QByteArray data = (pass + salt).toUtf8();
    return QCryptographicHash::hash(data, QCryptographicHash::Sha256).toHex();
}

TcpBackend::TcpBackend(QObject *parent) : QObject(parent){
    m_server = new QTcpServer(this);

    // 当有新的客户端（树莓派）连接时，触发 onNewConnection 函数
    connect(m_server, &QTcpServer::newConnection, this, &TcpBackend::onNewConnection);

    // 初始化DB
    if (m_db.initDb()) {
        qDebug() << "TCP后端引擎：数据库挂载成功！";
    }

    // 启动检查定时器
    m_checkTimer = new QTimer(this);

    connect(m_checkTimer, &QTimer::timeout, this, [this](){
        QDateTime now = QDateTime::currentDateTime();
        QMutableMapIterator<QString, SessionInfo> i(m_activeSessions);

        while (i.hasNext()) {
            i.next();
            // 如果超过 90 秒没收到心跳
            if (i.value().lastSeen.secsTo(now) > 90) {
                QString devId = i.key();
                QString cardId = i.value().cardId;
                int duration = i.value().startTime.secsTo(i.value().lastSeen);
                QString subject = i.value().subject;

                // 自动生成一条“下车签退”记录
                m_db.insertRecord(cardId, "系统异常签退", duration, devId, subject);

                emit messageReceived(QString("[超时处理] 设备 %1 失去连接，已自动结算学员 %2 的学时").arg(devId).arg(cardId));

                i.remove(); // 从活动名册中移除
                emit databaseUpdated();
            }
        }
    });
    m_checkTimer->start(10000); // 每 10 秒扫描一次名册
}
// 供 QML 调用的启动服务器函数
void TcpBackend::startServer(int port){
    if (m_server->isListening()) {
        emit messageReceived("服务端已在运行，端口:" + QString::number(m_server->serverPort()));
        return;
    }

    if(m_server->listen(QHostAddress::Any, port)) {
        // 启动成功，发信号给 QML 显示状态
        emit messageReceived("服务端已启动，正在监听端口: " + QString::number(port));
    } else {
        emit messageReceived("服务端启动失败！");
    }
}
// 处理新连接
void TcpBackend::onNewConnection(){
    // 获取和这个具体客户端通信的套接字
    QTcpSocket *socket = m_server->nextPendingConnection();
    // 为这个套接字创建一个缓冲区，用于存储未处理的消息
    m_buffers[socket] = QByteArray();

    QString deviceKey = QString("%1:%2")
            .arg(socket->peerAddress().toString())
            .arg(socket->peerPort()); // 以 IP:Port 作为设备唯一标识
    m_deviceMap[deviceKey] = socket;
    m_socketDeviceKey[socket] = deviceKey;
    emit devicesUpdated();

    // 1. 当套接字有数据发来时，触发 onReadyRead
    connect(socket, &QTcpSocket::readyRead, this, &TcpBackend::onReadyRead);
    // 2. 当套接字断开连接时，触发 onDisconnected
    connect(socket, &QTcpSocket::disconnected, this, &TcpBackend::onDisconnected);

    // 获取客户端的 IP 地址，发给前端显示
    QString clientIP = socket->peerAddress().toString();
    emit messageReceived("[上线通知]车辆终端已连接！IP: " + clientIP);
}

// 处理收到的数据
void TcpBackend::onReadyRead(){
    // 找出来源 (通过 sender() 转换)
    QTcpSocket *socket = qobject_cast<QTcpSocket*>(sender());
    if(!socket) return;

    // 1 将新收到的数据追加到缓冲区
    m_buffers[socket].append(socket->readAll());

    // 2 将收到的数据作为 JSON 进行解析
    while(m_buffers[socket].contains('\n')){
        int pos = m_buffers[socket].indexOf('\n');

        // 取出一条完整消息
        QByteArray oneMsg = m_buffers[socket].left(pos).trimmed();

        // 从缓冲区移除
        m_buffers[socket].remove(0, pos + 1);

        QString rawMsg = QString::fromUtf8(oneMsg);

        emit messageReceived("[收到车辆数据]" + rawMsg);
        qDebug()<<rawMsg<<endl;

        QJsonParseError jsonError;
        QJsonDocument doc = QJsonDocument::fromJson(oneMsg, &jsonError);

        if(jsonError.error == QJsonParseError::NoError && doc.isObject()){
            QJsonObject jsonObj = doc.object();
            QString type = jsonObj.value("type").toString();
            QString devId = jsonObj.value("device_id").toString();

            if (!devId.isEmpty()) {
                QString oldKey = m_socketDeviceKey.value(socket);
                if (!oldKey.isEmpty() && oldKey != devId && m_deviceMap.value(oldKey) == socket) {
                    m_deviceMap.remove(oldKey);
                }
                m_deviceMap[devId] = socket;
                m_socketDeviceKey[socket] = devId;
                emit devicesUpdated();
            }

            // 安全校验
            if (!verifySignature(jsonObj) && type != "issue_card"  ) {
                emit messageReceived("[安全警告] 收到非法签名数据，已拦截！类型: " + type);
                socket->disconnectFromHost(); // 强制断开 socket
                return;
            }

            if(type == "card"){
                QString cardId = jsonObj.value("CardID").toString();
                QString action = jsonObj.value("Action").toString();
                int duration = jsonObj.value("Duration").toInt();
                QString subject = jsonObj.value("Subject").toString();

                // 身份校验
                QSqlQuery queryCheck;
                queryCheck.prepare("SELECT name FROM students WHERE card_id = :id");
                queryCheck.bindValue(":id", cardId);

                if(!queryCheck.exec() || !queryCheck.next()){
                    QJsonObject reply;
                    reply["type"] = "ack";
                    reply["status"] = "invalid"; // 告知设备端
                    reply["CardID"] = cardId;
                    
                    socket->write(QJsonDocument(reply).toJson(QJsonDocument::Compact) + "\n");
                    emit messageReceived("[拦截] 未知卡片尝试刷卡: " + cardId);
                    return; // 跳过 insertRecord 逻辑
                }
                // 身份校验完成 获取姓名并插入记录
                QString stuName = queryCheck.value(0).toString();

                // 格式校验
                if(m_db.insertRecord(cardId, action, duration, devId, subject)){
                    // Session 的起点
                    if(action == "上车签到"){
                        m_activeSessions[devId] = {cardId, QDateTime::currentDateTime(), QDateTime::currentDateTime(), subject};
                    }else if(action == "下车签退"){
                        m_activeSessions.remove(devId);
                    }
                    
                    QJsonObject reply;
                    reply["type"] = "ack";
                    reply["status"] = "success";
                    reply["CardID"] = cardId;
                    reply["name"] = stuName;
                    reply["action"] = action;
                    reply["duration"] = duration;

                    socket->write(QJsonDocument(reply).toJson(QJsonDocument::Compact) + "\n");
                    emit databaseUpdated();
                } else {
                    emit messageReceived("  -> [警告] 数据库存储失败！");
                }
                
            } else if (type == "theory") {
                QString cardId = jsonObj.value("cardId").toString();
                int score = jsonObj.value("score").toInt();
                int total = jsonObj.value("total").toInt();
                QString deviceId = jsonObj.value("device_id").toString();
                QString subject = jsonObj.value("subject").toString();

                if (cardId.isEmpty()) {
                    emit messageReceived("[警告] 答题数据异常!");
                    continue;
                }

                if (m_db.insertTheoryResult(cardId, score, total, deviceId, subject)) {
                    emit messageReceived(QString("[系统提示] 成绩入库成功：%1/%2").arg(score).arg(total));

                    QJsonObject replyTheory;
                    replyTheory["type"] = "ack";
                    replyTheory["status"] = "theory_ok"; // (theory success)
                    replyTheory["CardID"] = cardId;

                    QJsonDocument replyDoc(replyTheory);
                    socket->write(QJsonDocument(replyTheory).toJson(QJsonDocument::Compact) + "\n");

                    emit databaseUpdated();
                } else {
                    emit messageReceived("[警告] 理论成绩入库失败");
                }

            } else if (type == "heartbeat") {
                QString devId = jsonObj["device_id"].toString(); // 在线的设备
                QString cardId = jsonObj["CardID"].toString(); // 设备内的用户

                if(m_activeSessions.contains(devId)) {
                    // 只有已经在练习的设备，才更新它的最后在线时间
                    m_activeSessions[devId].lastSeen = QDateTime::currentDateTime();
                    // 如果心跳里的卡号和会话里的不一致（异常情况），以心跳为准更新一下
                    if(!cardId.isEmpty()) m_activeSessions[devId].cardId = cardId;
                }
                qDebug() << "收到一次心跳" << devId << endl;
                return; // 不回复 节省 TCP 带宽

            } else if (type == "issue_card") {
                QString devId = jsonObj.value("device_id").toString();
                if(m_activeSessions.contains(devId)) {
                    m_activeSessions.remove(devId);
                    emit databaseUpdated(); // 通知 UI 刷新监控页
                }

                QString cardId = jsonObj.value("CardID").toString();

                QSqlQuery query;
                query.prepare("SELECT name FROM students WHERE card_id = :id");
                query.bindValue(":id", cardId);

                QJsonObject reply;

                if (query.exec() && query.next()) {
                    reply["type"] = "issue_reply";
                    reply["status"] = "exists";
                    reply["CardID"] = cardId;
                    reply["name"] = query.value(0).toString();
                } else {
                    reply["type"] = "issue_reply";
                    reply["status"] = "new";
                    reply["CardID"] = cardId;

                    emit newCardDetected(cardId); // 通知UI
                }

                socket->write(QJsonDocument(reply).toJson(QJsonDocument::Compact) + "\n");
            }
        }else{
            emit messageReceived("  -> [提示] 收到的非 JSON 标准格式数据，仅做展示，不存入数据库。");
        }
    }
}
// 处理断开连接的逻辑
void TcpBackend::onDisconnected(){
    QTcpSocket *socket = qobject_cast<QTcpSocket*>(sender());
    if(!socket) return;

    QStringList staleKeys;
    QMapIterator<QString, QTcpSocket*> it(m_deviceMap);
    while (it.hasNext()) {
        it.next();
        if (it.value() == socket) {
            staleKeys.append(it.key());
        }
    }
    for (const QString &key : staleKeys) {
        m_deviceMap.remove(key);
    }
    m_socketDeviceKey.remove(socket);
    m_buffers.remove(socket);
    emit devicesUpdated();

    QString clientIP = socket->peerAddress().toString();
    emit messageReceived("[下线通知]车辆终端已断开,IP: " + clientIP);

    // 释放资源，防止内存泄漏
    socket->deleteLater();
}
// 获取数据
QVariantList TcpBackend::getHistoryRecords(){
    return m_db.getAllRecords();
}
// 注册学员信息
bool TcpBackend::registerNewStudent(const QString &cardId, const QString &name){
    bool ok = m_db.addStudent(cardId, name);
    if (ok) emit studentsUpdated(); // 注册成功发射信号
    return ok;
}
// 校验
bool TcpBackend::verifySignature(const QJsonObject &obj) {
    QString clientSign = obj.value("sign").toString();
    QString type = obj.value("type").toString();
    QString timestamp = obj.value("timestamp").toString();

    // 构造签名原文(构造方法必须与树莓派端一致)
    // CardID + type + timestamp + subject + secretKey
    QString cardId = obj.value("CardID").toString();
    QString subject = obj.value("Subject").toString();

    QString origin = cardId + type + timestamp + subject + secretKey;

    QString serverSign = QCryptographicHash::hash(origin.toUtf8(), QCryptographicHash::Md5).toHex();
    qDebug() << "[签名校验] serverSign:" << serverSign << " clientSign:" << clientSign;

    return (serverSign == clientSign);
}
// 搜寻学员
QVariantList TcpBackend::getStudents() {
    QVariantList list;
    QSqlQuery query("SELECT card_id, name FROM students ORDER BY id DESC");
    while(query.next()){
        QVariantMap map;
        map["card_id"] = query.value(0).toString();
        map["name"] = query.value(1).toString();
        list.append(map);
    }
    return list;
}
// 删除学员
bool TcpBackend::deleteStudent(const QString cardId) {
    QSqlQuery query;
    query.prepare("DELETE FROM students WHERE card_id = ?");
    query.addBindValue(cardId);
    if(query.exec()) {
        emit studentsUpdated();
        emit databaseUpdated();
        return true;
    }
    return false;
}

QVariantList TcpBackend::getActiveSessions() {
    QVariantList list;
    QMapIterator<QString, SessionInfo> i(m_activeSessions);
    while (i.hasNext()) {
        i.next();
        QVariantMap map;
        map["device_id"] = i.key();
        map["card_id"] = i.value().cardId;
        map["start_time"] = i.value().startTime.toString("hh:mm:ss");
        // 计算已练时长
        int mins = i.value().startTime.secsTo(QDateTime::currentDateTime()) / 60;
        map["duration_mins"] = mins;
        list.append(map);
    }
    return list;
}

// 获取在线设备列表
QVariantList TcpBackend::getConnectedDevices() {
    QVariantList list;
    QMapIterator<QString, QTcpSocket*> i(m_deviceMap);
    while (i.hasNext()) {
        i.next();
        QTcpSocket *sock = i.value();
        if (!sock || sock->state() != QAbstractSocket::ConnectedState) {
            continue;
        }

        QVariantMap map;
        map["device_id"] = i.key();
        list.append(map);
    }
    return list;
}

// 学时进度计算
double TcpBackend::getStudentProgress(const QString &cardId, const QString &subject) {
    // DbManager::getStudentProgress 返回总秒数
    int totalSeconds = m_db.getStudentProgress(cardId, subject);
    // 将学时归一化为 0..1（假设每科需 1 小时 = 3600 秒）
    double frac = 0.0;
    if (totalSeconds > 0) {
        frac = double(totalSeconds) / 3600.0;
        if (frac > 1.0) frac = 1.0;
    }
    return frac;
}

// 预约相关实现
QVariantList TcpBackend::getAppointments(){ return m_db.getAppointments();}

bool TcpBackend::updateAppointStatus(int appointmentId, int newStatus){
    bool ok = m_db.updateAppointmentStatus(appointmentId, newStatus);
    if(ok){
        emit appointmentsUpdated();
        emit databaseUpdated();
    }
    return ok;
}

// 删除预约
bool TcpBackend::deleteAppoint(int appointmentId){
    bool ok = m_db.deleteAppointment(appointmentId);
    if(ok){
        emit appointmentsUpdated();
        emit databaseUpdated();
    }
    return ok;
}

bool TcpBackend::login(QString username, QString password) {
    QSqlQuery query;
    query.prepare("SELECT password_hash FROM users WHERE username = :user");
    query.bindValue(":user", username);
    
    if (query.exec() && query.next()) {
        QString storedHash = query.value(0).toString();
        return (storedHash == hashPassword(password));
    }
    return false;
}

bool TcpBackend::registerAdmin(QString username, QString password) {
    QSqlQuery query;
    query.prepare("INSERT INTO users (username, password_hash) VALUES (:user, :pass)");
    query.bindValue(":user", username);
    query.bindValue(":pass", hashPassword(password));
    return query.exec();
}

// 导出
void TcpBackend::exportToCSV() {
    QFile file("Training_Report.csv");
    if (file.open(QIODevice::WriteOnly | QIODevice::Text)) {
        QTextStream out(&file);
        out << "ID,Name,CardID,Action,Duration,Time\n"; // 表头
        QVariantList data = m_db.getAllRecords();
        for (auto item : data) {
            QVariantMap map = item.toMap();
            out << map["id"].toString() << "," << map["student_name"].toString() << ","
                << map["card_id"].toString() << "," << map["action"].toString() << ","
                << map["duration"].toString() << "," << map["timestamp"].toString() << "\n";
        }
        file.close();
        emit messageReceived("[系统] 报表导出成功：Training_Report.csv");
    }
}

void TcpBackend::sendControlCommand(QString cmd) {
    QJsonObject obj;
    obj["type"] = "control";
    obj["cmd"] = cmd;

    QByteArray data = QJsonDocument(obj).toJson(QJsonDocument::Compact) + "\n";

    // 广播给所有连接设备
    for (QTcpSocket* sock : m_buffers.keys()) {
        sock->write(data);
    }

    emit messageReceived("[控制指令] 已发送: " + cmd);
}

void TcpBackend::sendControlToDevice(QString deviceId, QString cmd) {
    QTcpSocket* targetSock = m_deviceMap.value(deviceId, nullptr);
    if (!targetSock) {
        emit messageReceived(QString("[定向指令失败] 找不到在线设备: %1").arg(deviceId));
        return;
    }

    if (targetSock->state() == QAbstractSocket::ConnectedState) {
        QJsonObject obj;
        obj["type"] = "control";
        obj["cmd"] = cmd;

        QByteArray data = QJsonDocument(obj).toJson(QJsonDocument::Compact) + "\n";
        targetSock->write(data);
        targetSock->flush();
        emit messageReceived(QString("[定向指令] 已发送至设备 %1: %2").arg(deviceId).arg(cmd));
        return;
    }

    emit messageReceived(QString("[定向指令失败] 设备已断开: %1").arg(deviceId));
}
