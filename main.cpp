#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <Qt3DQuickExtras/qt3dquickwindow.h>

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    Qt3DExtras::Quick::Qt3DQuickWindow view;
    view.setSource(QUrl("qrc:/main.qml"));
    view.show();

    return app.exec();
}
