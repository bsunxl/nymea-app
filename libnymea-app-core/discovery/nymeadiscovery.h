#ifndef NYMEADISCOVERY_H
#define NYMEADISCOVERY_H

#include <QObject>
#include <QTimer>

#include "connection/awsclient.h"

class DiscoveryModel;
class UpnpDiscovery;
class ZeroconfDiscovery;
class BluetoothServiceDiscovery;


class NymeaDiscovery : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool discovering READ discovering WRITE setDiscovering NOTIFY discoveringChanged)
    Q_PROPERTY(DiscoveryModel *discoveryModel READ discoveryModel CONSTANT)

    Q_PROPERTY(AWSClient* awsClient READ awsClient WRITE setAwsClient NOTIFY awsClientChanged)

public:
    explicit NymeaDiscovery(QObject *parent = nullptr);

    bool discovering() const;
    void setDiscovering(bool discovering);

    DiscoveryModel *discoveryModel() const;

    AWSClient* awsClient() const;
    void setAwsClient(AWSClient *awsClient);

signals:
    void discoveringChanged();
    void awsClientChanged();

private slots:
    void syncCloudDevices();

private:
    bool m_discovering = false;
    DiscoveryModel *m_discoveryModel = nullptr;

    UpnpDiscovery *m_upnp = nullptr;
    ZeroconfDiscovery *m_zeroConf = nullptr;
    BluetoothServiceDiscovery *m_bluetooth = nullptr;
    AWSClient *m_awsClient = nullptr;

    QTimer m_cloudPollTimer;

};

#endif // NYMEADISCOVERY_H
