import QtQuick 2.5
import QtQuick.Controls 2.1
import QtQuick.Layouts 1.1
import Nymea 1.0
import "../components"
import "../customviews"

GenericDevicePage {
    id: root


    GenericTypeLogView {
        anchors.fill: parent
        text: qsTr("This button has been pressed %1 times in the last %2 days.")

        logsModel: LogsModel {
            engine: _engine
            deviceId: root.device.id
            live: true
            typeIds: {
                var ret = [];
                ret.push(root.deviceClass.eventTypes.findByName("pressed").id)
                if (root.deviceClass.eventTypes.findByName("longPressed")) {
                    ret.push(root.deviceClass.eventTypes.findByName("longPressed").id)
                }
                return ret;
            }
            Component.onCompleted: update()
        }

        onAddRuleClicked: {
            var rule = engine.ruleManager.createNewRule();
            var eventDescriptor = rule.eventDescriptors.createNewEventDescriptor();
            eventDescriptor.deviceId = device.id;
            var eventType = root.deviceClass.eventTypes.findByName("pressed");
            eventDescriptor.eventTypeId = eventType.id;
            rule.name = root.device.name + " - " + eventType.displayName;
            if (eventType.paramTypes.count === 1) {
                var paramType = eventType.paramTypes.get(0);
                eventDescriptor.paramDescriptors.setParamDescriptor(paramType.id, value, ParamDescriptor.ValueOperatorEquals);
                rule.eventDescriptors.addEventDescriptor(eventDescriptor);
                rule.name = rule.name + " - " + value
            }
            var rulePage = pageStack.push(Qt.resolvedUrl("../magic/DeviceRulesPage.qml"), {device: root.device});
            rulePage.addRule(rule);
        }
    }
}
