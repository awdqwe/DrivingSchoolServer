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
     * @deviceId 设备号
     * @subject 科目
    */
    bool insertRecord(const QString &cardId, const QString &action, int duration, const QString &deviceId, const QString &subject);

    /* 插入一条理论成绩记录
     * @cardId 卡号
     * @score 得分
     * @total 总分
     * @deviceId 设备号
     * @subject 科目
    */
    bool insertTheoryResult(const QString cardId, int score, int total, const QString deviceId, const QString &subject);

    /* 注册账户(加入新学员)
     * @cardId 卡号
     * @name 用户名
     * @Q_INVOKABLE 让 QML 直接调用注册
    */
    Q_INVOKABLE bool addStudent(const QString &cardId, const QString &name);

    /* 插入预约记录
     * @cardId 卡号
     * @subject 科目
     * @date 预约日期
     * @deviceId 设备号
    */
    bool insertAppointment(const QString &cardId, const QString &subject, const QString &date, const QString &deviceId);
    /**
     * @brief 获取学员学习进度
     * @param cardId 卡号
     * @param subject 科目
     * @return 进度值
     */
    int getStudentProgress(const QString &cardId, const QString &subject);
    // 获取预约列表
    QVariantList getAppointments();

    // 修改预约状态
    bool updateAppointmentStatus(int appointmentId, int newStatus);
    // 删除预约记录
    bool deleteAppointment(int appointmentId);
    // 获取理论成绩列表
    QVariantList getTheoryScores();

    // 获取/查询所有历史记录
    QVariantList getAllRecords();

    // 获取排行榜数据
    QVariantList getLeaderboard();

private:
//    bool ensureSchema();
//    bool ensureColumnExists(const QString &table, const QString &column, const QString &ddlType);

    QSqlDatabase main_db; // DB 连接对象

};

#endif // DBMANAGER_H
