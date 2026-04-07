#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QIcon>
#include "tcpbackend.h"
//#include "dbmanager.h"  // DB服务

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
    // 预计论文中写：“本系统通过 qmlRegisterType 实现了底层 C++ 业务逻辑向 QML 前端安全暴露...”
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
