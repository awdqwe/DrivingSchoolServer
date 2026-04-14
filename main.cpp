// 入口函数
#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QIcon>
#include "tcpbackend.h"

int main(int argc, char *argv[]){
    qputenv("QT_IM_MODULE", QByteArray("qtvirtualkeyboard"));
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);

    QApplication app(argc, argv);

    app.setWindowIcon(QIcon(":/res/ico/icon.ico"));

    // 将 C++ 类注册到 QML 系统中
    /* 
     *模块名(Backend)
     *主版本号(1)
     *次版本号(0)
     *QML中的组件名(TcpBackend)
    */
    qmlRegisterType<TcpBackend>("Backend", 1, 0, "TcpBackend");

    QQmlApplicationEngine engine;
    
    const QUrl url(QStringLiteral("qrc:/main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}
