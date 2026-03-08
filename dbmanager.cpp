#include "dbmanager.h"
#include <QDir>
#include <QCoreApplication>

DbManager::DbManager(QObject *parent) : QObject(parent)
{

}

//数据表初始化
bool DbManager::initDb()
{
    // 检查是否已经包含了默认的数据库连接
    if (QSqlDatabase::contains("qt_sql_default_connection")) {
        main_db = QSqlDatabase::database("qt_sql_default_connection");
    } else {
        // 指定使用 SQLite 驱动
        main_db = QSqlDatabase::addDatabase("QSQLITE");
    }

    // 设置数据库文件的存放路径 (存放在程序运行的同级目录下)
    QString dbPath = QCoreApplication::applicationDirPath() + "/DrivingData.db";
    main_db.setDatabaseName(dbPath);

    // 尝试打开数据库（如果文件不存在，SQLite会自动创建一个）
    if (!main_db.open()) {
        qDebug() << "[错误]数据库打开失败:" << main_db.lastError().text();
        return false;
    }
    qDebug() << "[成功]数据库已连接，文件路径:" << dbPath;

    // [建表逻辑]写一段 SQL 语句 创建一个叫 records 的表
    /*
     * id (主键自增)
     * card_id (卡号)
     * action (动作: 上车/下车)
     * timestamp (打卡时间)
    */
    QSqlQuery query;
    QString createTableSql = R"(
        CREATE TABLE IF NOT EXISTS records (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            card_id TEXT NOT NULL,
            action TEXT NOT NULL,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    )";

    if (!query.exec(createTableSql)) {
        qDebug() << "[错误]创建数据表失败:" << query.lastError().text();
        return false;
    }

    qDebug() << "[成功]数据表初始化完毕.";
    return true;
}

// 写数据
bool DbManager::insertRecord(const QString &cardId, const QString &action)
{
    // 检查数据库是否打开
    if (!main_db.isOpen()) {
        return false;
    }

    QSqlQuery query;
    // [防注入]使用 prepare 预处理语句，而不是直接拼接字符串，这在毕设里是极好的安全规范展示
    query.prepare("INSERT INTO records (card_id, action) VALUES (:card_id, :action)");
    query.bindValue(":card_id", cardId);
    query.bindValue(":action", action);

    if (!query.exec()) {
        qDebug() << "[错误]插入数据失败:" << query.lastError().text();
        return false;
    }

    qDebug() << "[成功]已将数据存入数据库，卡号:" << cardId << " 动作:" << action;
    return true;
}
