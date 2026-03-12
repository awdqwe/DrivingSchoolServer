// 核心数据持久化 SQLite
// “本地化数据存储”、“数据持久层设计”、“SQL参数化查询防注入”
#ifndef DBMANAGER_H
#define DBMANAGER_H


#include <QObject>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>
#include <QDebug>

#include <QVariantList> // 打包数据成列表
#include <QVariantMap> // 把一行数据打包成字典
//#include <QVariant>


class DbManager : public QObject
{
    Q_OBJECT
public:
    explicit DbManager(QObject *parent = nullptr);

    // 初始化 DB(建库、建表)
    bool initDb();

    /* 插入一条刷卡记录
     * @cardId 卡号
     * @action 动作
     * @duration 时长
    */
    bool insertRecord(const QString &cardId, const QString &action, int duration);

    /* 注册账户(加入新学员)
     * @cardId 卡号
     * @name 用户名
    */
    bool addStudent(const QString &cardId, const QString &name);

    // 获取/查询所有历史记录
    QVariantList getAllRecords();

private:
//    bool ensureSchema();
//    bool ensureColumnExists(const QString &table, const QString &column, const QString &ddlType);

    QSqlDatabase main_db; // DB 连接对象

};

#endif // DBMANAGER_H
