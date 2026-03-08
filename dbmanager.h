// 核心数据持久化 SQLite
// “本地化数据存储”、“数据持久层设计”、“SQL参数化查询防注入”
#ifndef DBMANAGER_H
#define DBMANAGER_H


#include <QObject>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>
#include <QDebug>
//#include <QVariantList>


class DbManager : public QObject
{
    Q_OBJECT
public:
    explicit DbManager(QObject *parent = nullptr);

    // 初始化 DB
    bool initDb();
    /* 插入一条刷卡记录
     * @cardId 卡号
     * @action 动作
    */
    bool insertRecord(const QString &cardId, const QString &action);

private:
    QSqlDatabase main_db; // DB 连接对象

};

#endif // DBMANAGER_H
