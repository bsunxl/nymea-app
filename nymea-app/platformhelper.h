#ifndef PLATFORMHELPER_H
#define PLATFORMHELPER_H

#include <QObject>

class PlatformHelper : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool hasPermissions READ hasPermissions NOTIFY permissionsRequestFinished)
    Q_PROPERTY(QString deviceSerial READ deviceSerial CONSTANT)
    Q_PROPERTY(QString deviceModel READ deviceModel CONSTANT)
    Q_PROPERTY(QString deviceManufacturer READ deviceManufacturer CONSTANT)

public:
    explicit PlatformHelper(QObject *parent = nullptr);
    virtual ~PlatformHelper() = default;

    Q_INVOKABLE virtual void requestPermissions() = 0;

    virtual bool hasPermissions() const = 0;
    virtual QString deviceSerial() const = 0;
    virtual QString deviceModel() const = 0;
    virtual QString deviceManufacturer() const = 0;

signals:
    void permissionsRequestFinished();
};

#endif // PLATFORMHELPER_H
