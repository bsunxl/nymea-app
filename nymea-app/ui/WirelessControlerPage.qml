import QtQuick 2.4
import QtQuick.Controls 2.1
import QtQuick.Layouts 1.2
import QtQuick.Controls.Material 2.1
import Nymea 1.0
import "components"

Page {
    id: root

    property string name
    property string address
    property QtObject networkManger

    header: GuhHeader {
        text: qsTr("%1 box network setup").arg(app.systemName)
        onBackPressed: {
            pageStack.pop()
            pageStack.pop()
        }

        HeaderButton {
            imageSource: Qt.resolvedUrl("images/refresh.svg")
            onClicked:  networkManger.manager.loadNetworks()
        }

        HeaderButton {
            imageSource: Qt.resolvedUrl("images/settings.svg")
            onClicked: pageStack.push(settingsPage)
        }
    }

    Connections {
        target: networkManger.manager
        onErrorOccured: {
            print("Error occurred", errorMessage)
            var errorDialog = Qt.createComponent(Qt.resolvedUrl("components/ErrorDialog.qml"));
            var popup = errorDialog.createObject(app, {text: errorMessage})
            popup.open()
        }

        onWirelessStatusChanged: {
            switch(networkManger.manager.wirelessStatus) {
            case WirelessSetupManager.WirelessStatusDisconnected:
                //networkManger.manager.loadCurrentConnection()
                networkManger.manager.accessPoints.clearSelectedNetwork()
                break;
            case WirelessSetupManager.WirelessStatusActivated:
                networkManger.manager.loadCurrentConnection()
                break;
            default:
                break;
            }
        }
    }

    function getWirelessStatusString() {
        switch (networkManger.manager.wirelessStatus) {
        case WirelessSetupManager.WirelessStatusUnknown:
            return qsTr("Unknown status.");
        case WirelessSetupManager.WirelessStatusUnmanaged:
            return qsTr("Network unmanaged.");
        case WirelessSetupManager.WirelessStatusUnavailable:
            return qsTr("Network unavailable.");
        case WirelessSetupManager.WirelessStatusDisconnected:
            return qsTr("Disconnected.");
        case WirelessSetupManager.WirelessStatusPrepare:
            return qsTr("Prepare connection...");
        case WirelessSetupManager.WirelessStatusConfig:
            return qsTr("Configure network...");
        case WirelessSetupManager.WirelessStatusNeedAuth:
            return qsTr("Authentication needed");
        case WirelessSetupManager.WirelessStatusIpConfig:
            return qsTr("Configuration IP...");
        case WirelessSetupManager.WirelessStatusIpCheck:
            return qsTr("Check IP...");
        case WirelessSetupManager.WirelessStatusSecondaries:
            return qsTr("Secondaries...");
        case WirelessSetupManager.WirelessStatusActivated:
            return qsTr("Network connected.");
        case WirelessSetupManager.WirelessStatusDeactivating:
            return qsTr("Network disconnecting...");
        case WirelessSetupManager.WirelessStatusFailed:
            return qsTr("Network connection failed.");
        default:
            return "???";
        }

    }

    function getNetworkStatusString() {
        switch (networkManger.manager.networkStatus) {
        case WirelessSetupManager.NetworkStatusUnknown:
            return qsTr("Unknown status.");
        case WirelessSetupManager.NetworkStatusAsleep:
            return qsTr("Asleep.");
        case WirelessSetupManager.NetworkStatusDisconnected:
            return qsTr("Disconnected.");
        case WirelessSetupManager.NetworkStatusDisconnecting:
            return qsTr("Disconnecting...");
        case WirelessSetupManager.NetworkStatusConnecting:
            return qsTr("Connecting...");
        case WirelessSetupManager.NetworkStatusLocal:
            return qsTr("Connected local.");
        case WirelessSetupManager.NetworkStatusConnectedSite:
            return qsTr("Connected site.");
        case WirelessSetupManager.NetworkStatusGlobal:
            return qsTr("Online.");
        default:
            return "???"
        }
    }

    ColumnLayout {
        anchors.fill: parent
        visible: networkManger.manager.initialized

        MeaListItemDelegate {
            Layout.fillWidth: true
            progressive: false
            text: qsTr("Networking status")
            subText: getNetworkStatusString()
        }

        ThinDivider {
            visible: networkManger.manager.wirelessEnabled
        }

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true

            model: networkManger.manager.accessPointsProxy
            clip: true

            BusyIndicator {
                anchors.centerIn: parent
                running: networkManger.manager.working
            }

            delegate: MeaListItemDelegate {
                width: parent.width
                text: model.ssid
                enabled: !networkManger.manager.working
                subText: {
                    if (!model.selectedNetwork) {
                        return "";
                    }
                    return getWirelessStatusString()
                }

                iconColor: model.selectedNetwork ? app.accentColor : "#808080"
                iconName:  {
                    if (model.protected) {
                        if (model.signalStrength <= 25)
                            return  Qt.resolvedUrl("images/nm-signal-25-secure.svg")

                        if (model.signalStrength <= 50)
                            return  Qt.resolvedUrl("images/nm-signal-50-secure.svg")

                        if (model.signalStrength <= 75)
                            return  Qt.resolvedUrl("images/nm-signal-75-secure.svg")

                        if (model.signalStrength <= 100)
                            return  Qt.resolvedUrl("images/nm-signal-100-secure.svg")

                    } else {

                        if (model.signalStrength <= 25)
                            return  Qt.resolvedUrl("images/nm-signal-25.svg")

                        if (model.signalStrength <= 50)
                            return  Qt.resolvedUrl("images/nm-signal-50.svg")

                        if (model.signalStrength <= 75)
                            return  Qt.resolvedUrl("images/nm-signal-75.svg")

                        if (model.signalStrength <= 100)
                            return  Qt.resolvedUrl("images/nm-signal-100.svg")

                    }
                }

                onClicked: {
                    print("Connect to ", model.ssid, " --> ", model.macAddress)
                    if (model.selectedNetwork) {
                        pageStack.push(networkInformationPage, { ssid: model.ssid, macAddress: model.macAddress })
                    } else {
                        pageStack.push(authenticationPage, { ssid: model.ssid, macAddress: model.macAddress })
                    }

                }
            }
        }
    }

    Component {
        id: networkInformationPage

        Page {
            id: root

            property string ssid
            property string macAddress
            property var accessPoint : networkManger.manager.accessPoints.getAccessPoint(ssid)

            header: GuhHeader {
                text: qsTr("Network information")
                onBackPressed: pageStack.pop()
            }

            ColumnLayout {
                anchors { left: parent.left; top: parent.top; right: parent.right }

                MeaListItemDelegate {
                    Layout.fillWidth: true
                    progressive: false
                    text: qsTr("SSID:")
                    subText: root.ssid
                }

                MeaListItemDelegate {
                    Layout.fillWidth: true
                    progressive: false
                    text: qsTr("Mac Address:")
                    subText: root.macAddress
                }

                MeaListItemDelegate {
                    Layout.fillWidth: true
                    progressive: false
                    text: qsTr("Host Address:")
                    subText: accessPoint.hostAddress
                }

                MeaListItemDelegate {
                    Layout.fillWidth: true
                    progressive: false
                    text: qsTr("Signal strength:")
                    subText: accessPoint.signalStrength
                }

                MeaListItemDelegate {
                    Layout.fillWidth: true
                    progressive: false
                    text: qsTr("Protected:")
                    subText: accessPoint.isProtected ? "Protected" : "Open"
                }

                MeaListItemDelegate {
                    Layout.fillWidth: true
                    progressive: false
                    text: qsTr("Connection status:")
                    subText: getWirelessStatusString()
                }

                Button {
                    Layout.fillWidth: true
                    Layout.leftMargin: app.margins
                    Layout.rightMargin: app.margins
                    text: qsTr("Disconnect")
                    onPressed: {
                        networkManger.manager.disconnectWirelessNetwork()
                        pageStack.pop()
                    }
                }
            }
        }
    }

    Component {
        id: authenticationPage

        Page {
            id: root

            property string ssid
            property string macAddress

            header: GuhHeader {
                text: qsTr("Wireless authentication")
                onBackPressed: pageStack.pop()
            }

            ColumnLayout {
                anchors { left: parent.left; top: parent.top; right: parent.right }

                Label {
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    Layout.leftMargin: app.margins
                    Layout.rightMargin: app.margins
                    Layout.topMargin: app.margins
                    text: qsTr("Please enter the password for the Wifi network.")
                }

                MeaListItemDelegate {
                    Layout.fillWidth: true
                    text: ssid
                    subText: macAddress
                    progressive: false
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: app.margins
                    Layout.rightMargin: app.margins
                    spacing: app.margins

                    TextField {
                        id: passwordTextField
                        Layout.fillWidth: true
                        echoMode: TextInput.Password
                    }
                    ColorIcon {
                        Layout.preferredHeight: app.iconSize
                        Layout.preferredWidth: app.iconSize
                        name: "../images/eye.svg"
                        color: passwordTextField.echoMode === TextInput.Normal ? app.accentColor : keyColor
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -app.margins / 2
                            onClicked: {
                                if (passwordTextField.echoMode === TextInput.Normal) {
                                    passwordTextField.echoMode = TextInput.Password
                                } else {
                                    passwordTextField.echoMode = TextInput.Normal
                                }
                            }
                        }
                    }
                }

                Button {
                    Layout.fillWidth: true
                    Layout.leftMargin: app.margins
                    Layout.rightMargin: app.margins
                    text: qsTr("Connect")
                    onPressed: {
                        networkManger.manager.connectWirelessNetwork(ssid, passwordTextField.text)
                        var accessPoint = networkManger.manager.accessPoints.getAccessPoint(ssid)
                        networkManger.manager.accessPoints.clearSelectedNetwork()
                        accessPoint.selectedNetwork = true
                        pageStack.pop()
                    }
                }
            }
        }
    }

    Component {
        id: settingsPage

        Page {
            id: root
            header: GuhHeader {
                text: qsTr("Network manager settings")
                onBackPressed: pageStack.pop()
            }

            ColumnLayout {
                anchors { left: parent.left; top: parent.top; right: parent.right }

                MeaListItemDelegate {
                    Layout.fillWidth: true
                    iconName: "../images/info.svg"
                    text: qsTr("About this %1 box").arg(app.systemName)
                    onClicked: pageStack.push(infoPage)
                }

                SwitchDelegate {
                    Layout.fillWidth: true
                    text: qsTr("Networking")
                    checked: networkManger.manager.networkingEnabled
                    onClicked: networkManger.manager.enableNetworking(checked)
                }

                SwitchDelegate {
                    Layout.fillWidth: true
                    enabled: networkManger.manager.networkingEnabled
                    text: qsTr("Wireless network")
                    checked: networkManger.manager.wirelessEnabled
                    onClicked: {
                        networkManger.manager.enableWireless(checked)
                    }
                }

                Button {
                    Layout.fillWidth: true
                    Layout.leftMargin: app.margins
                    Layout.rightMargin: app.margins
                    text: qsTr("Trigger a wireless scan on the device.")
                    onClicked: networkManger.manager.performWifiScan()
                }
            }
        }
    }

    Component {
        id: infoPage

        Page {
            id: root
            header: GuhHeader {
                text: qsTr("Box information")
                onBackPressed: pageStack.pop()
            }

            ColumnLayout {
                anchors { left: parent.left; top: parent.top; right: parent.right }

                MeaListItemDelegate {
                    Layout.fillWidth: true
                    progressive: false
                    text: qsTr("System UUID")
                    subText: networkManger.manager.modelNumber
                }
                MeaListItemDelegate {
                    Layout.fillWidth: true
                    progressive: false
                    text: qsTr("Manufacturer")
                    subText: networkManger.manager.manufacturer
                }
                MeaListItemDelegate {
                    Layout.fillWidth: true
                    progressive: false
                    text: qsTr("Software revision")
                    subText: networkManger.manager.softwareRevision
                }
                MeaListItemDelegate {
                    Layout.fillWidth: true
                    progressive: false
                    text: qsTr("Firmware revision")
                    subText: networkManger.manager.firmwareRevision
                }
                MeaListItemDelegate {
                    Layout.fillWidth: true
                    progressive: false
                    text: qsTr("Hardware revision")
                    subText: networkManger.manager.hardwareRevision
                }
            }
        }
    }
}
