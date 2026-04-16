#include "dbmanager.h"
#include <QDir>
#include <QCoreApplication>

DbManager::DbManager(QObject *parent) : QObject(parent){}

//数据表初始化
bool DbManager::initDb(){
    // 检查是否已经包含了默认的数据库连接
    if(QSqlDatabase::contains("qt_sql_default_connection")) {
        main_db = QSqlDatabase::database("qt_sql_default_connection");
    }else{
        // 指定使用 SQLite 驱动
        main_db = QSqlDatabase::addDatabase("QSQLITE");
    }

    // 设置数据库文件的存放路径 (存放在程序运行的同级目录下)
    QString dbPath = QCoreApplication::applicationDirPath() + "/DrivingData.db";
    main_db.setDatabaseName(dbPath);

    // 尝试打开数据库（如果文件不存在，SQLite会自动创建）
    if (!main_db.open()) {
        qDebug() << "[错误]数据库打开失败:" << main_db.lastError().text();
        return false;
    }
    qDebug() << "[成功]数据库已连接，文件路径:" << dbPath << endl;

    // 创建表: students (学员)
    QSqlQuery query;
    QString createTableSql = R"(
            CREATE TABLE IF NOT EXISTS students (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                card_id TEXT NOT NULL UNIQUE,
                name TEXT NOT NULL,
                total_seconds INTEGER DEFAULT 0
            )
    )";

    // 创建表: records (记录)
    QString createRecordsSql = R"(
            CREATE TABLE IF NOT EXISTS records(
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                card_id TEXT NOT NULL,
                action TEXT NOT NULL,
                subject TEXT NOT NULL,
                duration INTEGER DEFAULT 0,
                device_id TEXT NOT NULL,
                timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
            )
    )";

    // 创建表：theory_results (理论结果)
    QString createTheorySql = R"(
        CREATE TABLE IF NOT EXISTS theory_results(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            card_id TEXT NOT NULL,
            score INTEGER,
            total INTEGER,
            subject TEXT,
            device_id TEXT NOT NULL,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    )";

    // 创建表： usr (用户)
    QString createUsersSql = R"(
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT NOT NULL UNIQUE CHECK(LENGTH(username) BETWEEN 1 AND 20), -- 用户名长度限制  1-20 字符
            password_hash TEXT NOT NULL, -- password_hash 实际长度为 64 字符（SHA-256 的十六进制表示）
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    )";

    // 创建表 appointments (预约)
    QString createAppointmentsSql = R"(
        CREATE TABLE IF NOT EXISTS appointments (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            card_id TEXT,
            subject TEXT,
            appointment_date TEXT,
            device_id TEXT,
            status INTEGER DEFAULT 0, -- 0:未读, 1:已读
            create_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    )";

    if(!query.exec(createRecordsSql) ||
            !query.exec(createTableSql) ||
            !query.exec(createTheorySql) ||
            !query.exec(createUsersSql) ||
            !query.exec(createAppointmentsSql)){
        qDebug() << "[错误]创建数据表失败:" << query.lastError().text();
        return false;
    }
    qDebug() << "[成功]数据表初始化完成.";
    return true;

}

// 查学时进度
bool DbManager::addStudent(const QString &cardId, const QString &name){
    QSqlQuery query;
    query.prepare("INSERT OR IGNORE INTO students (card_id, name) VALUES (:card_id, :name)");
    query.bindValue(":card_id", cardId);
    query.bindValue(":name", name);
    return query.exec();
}
// 更新学员姓名
bool DbManager::updateStudentName(const QString &cardId, const QString &newName){
    if (!main_db.isOpen()) return false;
    QSqlQuery query;
    query.prepare("UPDATE students SET name = :name WHERE card_id = :card_id");
    query.bindValue(":name", newName);
    query.bindValue(":card_id", cardId);
    return query.exec();
}

// 写数据 刷卡后的记录
bool DbManager::insertRecord(const QString &cardId, const QString &action, int duration, const QString &deviceId, const QString &subject){
    if (!main_db.isOpen()) return false;

    // 事务(Transaction) 保证“插入记录”和“累加学时” 同时成功/同时失败
    main_db.transaction();

    QSqlQuery query;
    // 1 插入打卡记录(是第一次刷卡)

    // [防注入]使用 prepare 预处理语句，而不是直接拼接字符串
    query.prepare("INSERT INTO records (card_id, action, duration, device_id, subject) VALUES (:card_id, :action, :duration, :device_id, :subject)");
    query.bindValue(":card_id", cardId);
    query.bindValue(":action", action);
    query.bindValue(":duration", duration);
    query.bindValue(":device_id", deviceId);
    query.bindValue(":subject", subject);
    
    if(!query.exec()) {
        qDebug() << "[错误]插入数据失败:" << query.lastError().text();
        main_db.rollback(); // 失败则回滚
        return false;
    }
    // 2 如果是签退(第二次刷卡)
    if((action == "下车签退" || action == "系统异常签退") && duration > 0){
        QSqlQuery updateQuery;
        updateQuery.prepare("UPDATE students SET total_seconds = total_seconds + :duration WHERE card_id = :card_id");
        updateQuery.bindValue(":duration", duration);
        updateQuery.bindValue(":card_id", cardId);

        if(!updateQuery.exec()){
            main_db.rollback(); // 失败回滚
            return false;
        }
    }

    main_db.commit(); // 提交事务
    return true;
}

// 写数据 刷卡后的练习
bool DbManager::insertTheoryResult(const QString cardId, int score, int total, const QString deviceId, const QString &subject){
    if (!main_db.isOpen()) return false;
    main_db.transaction();

    QSqlQuery query;
    query.prepare("INSERT INTO theory_results (card_id, score, total, subject, device_id) VALUES (?, ?, ?, ?, ?)");
    query.addBindValue(cardId);
    query.addBindValue(score);
    query.addBindValue(total);
    query.addBindValue(subject);
    query.addBindValue(deviceId);
    if(!query.exec()) {
        qDebug() << "[错误]插入数据失败:" << query.lastError().text();
        main_db.rollback();
        return false;
    }

    main_db.commit();
    return true;
}

QVariantList DbManager::getAllRecords(){
    QVariantList list;
    if (!main_db.isOpen()) return list;

    // 执行 SQL JOIN 联合查询
    // 用 card_id 将 records 表和 students 表联系,可以查询学员填写的用户名
    QString joinSql = R"(
        SELECT r.id, COALESCE(s.name, '未知访客') as student_name, r.card_id, r.action, r.duration, r.timestamp
        FROM records r
        LEFT JOIN students s ON r.card_id = s.card_id
        ORDER BY r.id DESC
    )";

    QSqlQuery query(joinSql);
    while(query.next()){
        QVariantMap map;

        map["id"] = query.value(0).toInt();
        map["student_name"] = query.value(1).toString();
        map["card_id"] = query.value(2).toString();
        map["action"] = query.value(3).toString();
        map["duration"] = query.value(4).toInt();
        map["timestamp"] = query.value(5).toString();
        list.append(map);
    }
    return list;
}

QVariantList DbManager::getLeaderboard(){
    QVariantList list;
    if (!main_db.isOpen()) return list;

    // 查询总学时大于 0 的学员，按学时降序排列，取前 5 名
    QSqlQuery query("SELECT name, total_seconds FROM students WHERE total_seconds > 0 ORDER BY total_seconds DESC LIMIT 5");
    
    while(query.next()){
        QVariantMap map;
        map["name"] = query.value(0).toString();
        map["total_seconds"] = query.value(1).toInt();
        list.append(map);
    }
    return list;
}

bool DbManager::insertAppointment(const QString &cardId, const QString &subject, const QString &date, const QString &deviceId){
    QSqlQuery query;
    query.prepare("INSERT INTO appointments (card_id, subject, appointment_date, device_id) VALUES (?, ?, ?, ?)");
    query.addBindValue(cardId);
    query.addBindValue(subject);
    query.addBindValue(date);
    query.addBindValue(deviceId);
    return query.exec();
}

// 获取预约列表
QVariantList DbManager::getAppointments(){
    QVariantList list;
    QString sql = "SELECT a.id, COALESCE(s.name, '未知学员'), a.card_id, a.subject, "
                  "a.appointment_date, a.status, a.create_time "
                  "FROM appointments a LEFT JOIN students s ON a.card_id = s.card_id "
                  "ORDER BY a.create_time DESC";
    QSqlQuery query(sql);
    while(query.next()){
        QVariantMap map;
        map["id"] = query.value(0).toInt();
        map["name"] = query.value(1).toString();
        map["card_id"] = query.value(2).toString();
        map["subject"] = query.value(3).toString();
        map["date"] = query.value(4).toString();
        map["status"] = query.value(5).toInt();
        map["received_time"] = query.value(6).toString();
        list.append(map);
    }
    return list;
}

// 修改预约状态
bool DbManager::updateAppointmentStatus(int appointmentId, int newStatus) {
    if (!main_db.isOpen()) return false;

    QSqlQuery query;
    query.prepare("UPDATE appointments SET status = :status WHERE id = :id");
    query.bindValue(":status", newStatus);
    query.bindValue(":id", appointmentId);
    return query.exec();
}

// 删除预约记录
bool DbManager::deleteAppointment(int appointmentId) {
    if (!main_db.isOpen()) return false;

    QSqlQuery query;
    query.prepare("DELETE FROM appointments WHERE id = :id");
    query.bindValue(":id", appointmentId);
    return query.exec();
}

QVariantList DbManager::getTheoryScores(){
    QVariantList list;
    // LEFT JOIN 关联学生姓名
    QString sql = R"(
        SELECT s.name, t.score, t.total, t.subject, t.timestamp
        FROM theory_results t
        LEFT JOIN students s ON t.card_id = s.card_id
        ORDER BY t.timestamp DESC
    )";
    QSqlQuery query(sql);
    while(query.next()){
        QVariantMap map;
        map["name"] = query.value(0).toString();
        map["score"] = query.value(1).toInt();
        map["total"] = query.value(2).toInt();
        map["subject"] = query.value(3).toString();
        map["time"] = query.value(4).toString();
        list.append(map);
    }
    return list;
}

int DbManager::getStudentProgress(const QString &cardId, const QString &subject){
    QSqlQuery query;
    query.prepare("SELECT SUM(duration) FROM records WHERE card_id = ? AND subject = ? AND action LIKE '%签退%'");
    query.addBindValue(cardId);
    query.addBindValue(subject);
    if(query.exec() && query.next()) {
        return query.value(0).toInt();
    }
    return 0;
}
