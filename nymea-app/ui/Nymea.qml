import QtQuick 2.8
import QtQuick.Controls 2.1
import QtQuick.Controls.Material 2.1
import QtQuick.Layouts 1.2
import Qt.labs.settings 1.0
import QtQuick.Window 2.3
import Nymea 1.0

ApplicationWindow {
    id: app
    visible: true
    width: 360
    height: 580
    visibility: ApplicationWindow.AutomaticVisibility
    font: Qt.application.font
    title: appName

    property int margins: 14
    property int bigMargins: 20
    property int extraSmallFont: 10
    property int smallFont: 13
    property int mediumFont: 16
    property int largeFont: 20
    property int iconSize: 30
    property int delegateHeight: 60

    property bool landscape: app.width > app.height

    property var settings: Settings {
        property string lastConnectedHost: ""
        property alias viewMode: app.visibility
        property bool returnToHome: false
        property bool darkTheme: false
        property string graphStyle: "bars"
        property string style: "light"
        property int currentMainViewIndex: 0
    }

    Component.onCompleted: {
        pageStack.push(Qt.resolvedUrl("ConnectPage.qml"))
    }

    Connections {
        target: Engine.jsonRpcClient
        onConnectedChanged: {
            print("json client connected changed", Engine.jsonRpcClient.connected)
            if (Engine.jsonRpcClient.connected) {
                settings.lastConnectedHost = Engine.connection.url
            }
            init();
        }

        onAuthenticationRequiredChanged: {
            print("auth required changed")
            init();
        }
        onInitialSetupRequiredChanged: {
            print("setup required changed")
            init();
        }

        onInvalidProtocolVersion: {
            var popup = invalidVersionComponent.createObject(app.contentItem);
            popup.actualVersion = actualVersion;
            popup.minimumVersion = minimumVersion
            popup.open()
            settings.lastConnectedHost = ""
        }
    }

    function init() {
        print("calling init. Auth required:", Engine.jsonRpcClient.authenticationRequired, "initial setup required:", Engine.jsonRpcClient.initialSetupRequired, "jsonrpc connected:", Engine.jsonRpcClient.connected)
        pageStack.clear()
        if (!Engine.connection.connected) {
            pageStack.push(Qt.resolvedUrl("ConnectPage.qml"))
            return;
        }

        if (Engine.jsonRpcClient.authenticationRequired || Engine.jsonRpcClient.initialSetupRequired) {
            if (Engine.jsonRpcClient.pushButtonAuthAvailable) {
                print("opening push button auth")
                var page = pageStack.push(Qt.resolvedUrl("PushButtonAuthPage.qml"))
                page.backPressed.connect(function() {
                    settings.lastConnectedHost = "";
                    Engine.connection.disconnect();
                    init();
                })
            } else {
                var page = pageStack.push(Qt.resolvedUrl("LoginPage.qml"));
                page.backPressed.connect(function() {
                    settings.lastConnectedHost = "";
                    Engine.connection.disconnect()
                    init();
                })
            }
        } else if (Engine.jsonRpcClient.connected) {
            pageStack.push(Qt.resolvedUrl("MainPage.qml"))
        } else {
            pageStack.push(Qt.resolvedUrl("ConnectPage.qml"))
        }
    }

    // Workaround flickering on pageStack animations when the white background shines through
    Rectangle {
        anchors.fill: parent
        color: Material.background
    }

    StackView {
        id: pageStack
        objectName: "pageStack"
        anchors.fill: parent
        initialItem: Page {}
        onDepthChanged: {
            print("stackview depth changed", pageStack.depth)
        }
    }

    onClosing: {
        if (Qt.platform.os == "android") {
            // If we're connected, allow going back up to MainPage
            if ((Engine.jsonRpcClient.connected && pageStack.depth > 1)
                    // if we're not connected, only allow using the back button in wizards
                    || (!Engine.jsonRpcClient.connected && pageStack.depth > 3)) {
                close.accepted = false;
                pageStack.pop();
            }
        }
    }

    Connections {
        target: Qt.application
        enabled: Engine.jsonRpcClient.connected && settings.returnToHome
        onStateChanged: {
            print("App active state changed:", state)
            if (state !== Qt.ApplicationActive) {
                init();
            }
        }
    }

    property var supportedInterfaces: ["light", "weather", "sensor", "media", "garagegate", "extendedawning", "extendedshutter", "extendedblind", "button", "notifications", "inputtrigger", "outputtrigger", "gateway"]
    function interfaceToString(name) {
        switch(name) {
        case "light":
            return qsTr("Lighting")
        case "weather":
            return qsTr("Weather")
        case "sensor":
            return qsTr("Sensors")
        case "media":
            return qsTr("Media")
        case "button":
            return qsTr("Switches")
        case "gateway":
            return qsTr("Gateways")
        case "notifications":
            return qsTr("Notifications")
        case "temperaturesensor":
            return qsTr("Temperature");
        case "humiditysensor":
            return qsTr("Humidity");
        case "pressuresensor":
            return qsTr("Pressure");
        case "inputtrigger":
            return qsTr("Incoming Events");
        case "outputtrigger":
            return qsTr("Events");
        case "shutter":
        case "extendedshutter":
            return qsTr("Shutters");
        case "blind":
        case "extendedblind":
            return qsTr("Blinds");
        case "awning":
        case "extendedawning":
            return qsTr("Awnings");
        case "garagegate":
            return qsTr("Garage gates");
        case "uncategorized":
            return qsTr("Uncategorized")
        }
    }

    function interfacesToIcon(interfaces) {
        if (interfaces.indexOf("garagegate") >= 0) {
            return Qt.resolvedUrl("images/shutter/shutter-100.svg")
        } else if (interfaces.indexOf("light") >= 0
                   || interfaces.indexOf("colorlight") >= 0
                   || interfaces.indexOf("dimmablelight") >= 0) {
            return Qt.resolvedUrl("images/light-on.svg")
        } else if (interfaces.indexOf("sensor") >= 0) {
            return Qt.resolvedUrl("images/sensors.svg")
        } else if (interfaces.indexOf("temperaturesensor") >= 0) {
            return Qt.resolvedUrl("images/sensors/temperature.svg")
        } else if (interfaces.indexOf("humiditysensor") >= 0) {
            return Qt.resolvedUrl("images/sensors/humidity.svg")
        } else if (interfaces.indexOf("moisturesensor") >= 0) {
            return Qt.resolvedUrl("images/sensors/moisture.svg")
        } else if (interfaces.indexOf("lightsensor") >= 0) {
            return Qt.resolvedUrl("images/sensors/light.svg")
        } else if (interfaces.indexOf("conductivitysensor") >= 0) {
            return Qt.resolvedUrl("images/sensors/conductivity.svg")
        } else if (interfaces.indexOf("pressuresensor") >= 0) {
            return Qt.resolvedUrl("images/sensors/pressure.svg")
        } else if (interfaces.indexOf("media") >= 0
                   || interfaces.indexOf("mediacontroller") >= 0) {
            return Qt.resolvedUrl("images/mediaplayer-app-symbolic.svg")
        } else if (interfaces.indexOf("button") >= 0
                   || interfaces.indexOf("longpressbutton") >= 0
                   || interfaces.indexOf("simplemultibutton") >= 0
                   || interfaces.indexOf("longpressmultibutton") >= 0) {
            return Qt.resolvedUrl("images/system-shutdown.svg")
        } else if (interfaces.indexOf("weather") >= 0) {
            return Qt.resolvedUrl("images/weather-app-symbolic.svg")
        } else if (interfaces.indexOf("temperaturesensor") >= 0) {
            return Qt.resolvedUrl("images/sensors/temperature.svg")
        } else if (interfaces.indexOf("humiditysensor") >= 0) {
            return Qt.resolvedUrl("images/sensors/humidity.svg")
        } else if (interfaces.indexOf("gateway") >= 0) {
            return Qt.resolvedUrl("images/network-wired-symbolic.svg")
        } else if (interfaces.indexOf("notifications") >= 0) {
            return Qt.resolvedUrl("images/notification.svg")
        } else if (interfaces.indexOf("connectable") >= 0) {
            return Qt.resolvedUrl("images/stock_link.svg")
        } else if (interfaces.indexOf("inputtrigger") >= 0) {
            return Qt.resolvedUrl("images/attention.svg")
        } else if (interfaces.indexOf("outputtrigger") >= 0) {
            return Qt.resolvedUrl("images/send.svg")
        } else if (interfaces.indexOf("shutter") >= 0
                   || interfaces.indexOf("extendedshutter") >= 0) {
            return Qt.resolvedUrl("images/DeviceIconRollerShutter.svg")
        } else if (interfaces.indexOf("blind") >= 0
                   || interfaces.indexOf("extendedblind") >= 0) {
            return Qt.resolvedUrl("images/DeviceIconBlind.svg")
        } else if (interfaces.indexOf("awning") >= 0
                   || interfaces.indexOf("extendedawning") >= 0) {
            return Qt.resolvedUrl("images/awning/awning-100.svg")
        } else if (interfaces.indexOf("battery") >= 0) {
            return Qt.resolvedUrl("images/battery/battery-050.svg")
        } else if (interfaces.indexOf("uncategorized") >= 0) {
            return Qt.resolvedUrl("images/select-none.svg")
        } else if (interfaces.indexOf("simpleclosable") >= 0) {
            return Qt.resolvedUrl("images/sort-listitem.svg")
        }
        console.warn("InterfaceToIcon: Unhandled interface", name)
        return "";
    }

    function interfaceToColor(name) {
        switch (name) {
        case "temperaturesensor":
            return "red";
        case "humiditysensor":
            return "deepskyblue";
        case "moisturesensor":
            return "blue";
        case "lightsensor":
            return "orange";
        case "conductivitysensor":
            return "green";
        case "pressuresensor":
            return "grey";
        }
        return "grey";
    }

    function interfaceToDisplayName(name) {
        switch (name) {
        case "light":
            return qsTr("light")
        case "button":
            return "button";
        case "sensor":
            return qsTr("sensor")
        }
    }

    function interfaceListToDevicePage(interfaceList) {
        var page;
        if (interfaceList.indexOf("media") >= 0) {
            page = "MediaDevicePage.qml";
        } else if (interfaceList.indexOf("button") >= 0) {
            page = "ButtonDevicePage.qml";
        } else if (interfaceList.indexOf("weather") >= 0) {
            page = "WeatherDevicePage.qml";
        } else if (interfaceList.indexOf("sensor") >= 0) {
            page = "SensorDevicePage.qml";
        } else if (interfaceList.indexOf("inputtrigger") >= 0) {
            page = "InputTriggerDevicePage.qml";
        } else if (interfaceList.indexOf("garagegate") >= 0 ) {
            page = "GarageGateDevicePage.qml";
        } else if (interfaceList.indexOf("light") >= 0) {
            page = "ColorLightDevicePage.qml";
        } else if (interfaceList.indexOf("extendedshutter") >= 0 ) {
            page = "ShutterDevicePage.qml";
        } else if (interfaceList.indexOf("extendedawning") >= 0) {
            page = "AwningDevicePage.qml";
        } else {
            page = "GenericDevicePage.qml";
        }
        print("Selecting page", page, "for interface list:", interfaceList)
        return page;
    }

    function pad(num, size) {
        var s = "000000000" + num;
        return s.substr(s.length-size);
    }

    Component {
        id: invalidVersionComponent
        Popup {
            id: popup

            property string actualVersion: "0.0"
            property string minimumVersion: "1.0"

            width: app.width * .8
            height: col.childrenRect.height + app.margins * 2
            x: (app.width - width) / 2
            y: (app.height - height) / 2
            visible: false
            ColumnLayout {
                id: col
                anchors { left: parent.left; right: parent.right }
                spacing: app.margins
                Label {
                    text: qsTr("Connection error")
                    Layout.fillWidth: true
                    font.pixelSize: app.largeFont
                }
                Label {
                    text: qsTr("Sorry, the version of the %1 box you are trying to connect to is too old. This app requires at least version %2 but the %1 box only supports %3").arg(app.systemName).arg(popup.minimumVersion).arg(popup.actualVersion)
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
                Button {
                    Layout.fillWidth: true
                    text: qsTr("OK")
                    onClicked: {
                        Engine.connection.disconnect();
                        popup.close()
                    }
                }
            }
        }
    }
}
