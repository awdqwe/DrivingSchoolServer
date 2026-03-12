#include "dbmanager.h"
#include <QDir>
#include <QCoreApplication>

DbManager::DbManager(QObject *parent) : QObject(parent){
}

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

    // 创建表: students
    QSqlQuery query;
    QString createTableSql = R"(
            CREATE TABLE IF NOT EXISTS students (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                card_id TEXT NOT NULL UNIQUE,
                name TEXT NOT NULL,
                total_seconds INTEGER DEFAULT 0
            )
    )";

    // 创建表: records
    QString createRecordsSql = R"(
            CREATE TABLE IF NOT EXISTS records(
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                card_id TEXT NOT NULL,
                action TEXT NOT NULL,
                duration INTEGER DEFAULT 0,
                timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
            )
    )";

    if(!query.exec(createRecordsSql) || !query.exec(createTableSql)){
        qDebug() << "[错误]创建数据表失败:" << query.lastError().text();
        return false;
    }

    // 当前直接硬编码写入一个学员  TODO:学员注册逻辑
    addStudent("B3D10F07", "张三 (VIP学员)");
    addStudent("69AB2A07", "李四 (普通学员)");


    qDebug() << "[成功]数据表初始化完成.";
    return true;

}

bool DbManager::addStudent(const QString &cardId, const QString &name){
    QSqlQuery query;
    query.prepare("INSERT OR IGNORE INTO students (card_id, name) VALUES (:card_id, :name)");
    query.bindValue(":card_id", cardId);
    query.bindValue(":name", name);
    return query.exec();
}

// 写数据
bool DbManager::insertRecord(const QString &cardId, const QString &action, int duration){
    if (!main_db.isOpen()) return false;

    // 数据库事务(Transaction)
    // 保证“插入记录”和“累加学时” 同时成功/同时失败
    main_db.transaction();

    QSqlQuery query;
    // 1 插入打卡记录

    // [防注入]使用 prepare 预处理语句，而不是直接拼接字符串
    query.prepare("INSERT INTO records (card_id, action, duration) VALUES (:card_id, :action, :duration)");
    query.bindValue(":card_id", cardId);
    query.bindValue(":action", action);
    query.bindValue(":duration", duration);

    if(!query.exec()) {
        qDebug() << "[错误]插入数据失败:" << query.lastError().text();
        main_db.rollback(); // 失败则回滚
        return false;
    }
    // 2 如果是签退(第二次刷卡)
    if(action == "下车签退" && duration > 0){
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

QVariantList DbManager::getAllRecords()
{
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
