pragma Singleton

import QtQuick

QtObject {
    function cancelRadio(radio) {
        if (radio === "wifi") {
            wifiBusy = false;
            wifiCommandQueue = [];
            wifiCommandResults = [];
            wifiCommandIndex = 0;
            wifiPendingOperation = "";
            wifiRefreshWhenIdle = false;
            wifiScanActive = false;
        } else {
            bluetoothBusy = false;
            bluetoothCommandQueue = [];
            bluetoothCommandResults = [];
            bluetoothCommandIndex = 0;
            bluetoothPendingOperation = "";
            bluetoothRefreshWhenIdle = false;
            bluetoothScanActive = false;
        }
    }

    property var wifiNetworks: []
    property var wifiProfiles: []
    property var pairedDevices: []
    property var nearbyDevices: []
    property var connectedDevices: []
    property var bluetoothBatteries: ({})
    property var bluetoothBatteryAddresses: []
    property string wifiDevice: ""

    property bool wifiBusy: false
    property bool bluetoothBusy: false
    property var wifiCommandQueue: []
    property var wifiCommandResults: []
    property int wifiCommandIndex: 0
    property string wifiPendingOperation: ""
    property string wifiPendingTarget: ""
    property bool wifiPreviousRadioEnabled: true
    property bool wifiRefreshWhenIdle: false
    property var bluetoothCommandQueue: []
    property var bluetoothCommandResults: []
    property int bluetoothCommandIndex: 0
    property string bluetoothPendingOperation: ""
    property string bluetoothPendingTarget: ""
    property bool bluetoothPreviousRadioEnabled: true
    property bool bluetoothRefreshWhenIdle: false

    property bool wifiEnabled: true
    property bool bluetoothEnabled: true
    property bool wifiLoaded: false
    property bool bluetoothLoaded: false
    property bool wifiScanActive: false
    property bool bluetoothScanActive: false
    property string wifiError: ""
    property string bluetoothError: ""
    property string wifiScanError: ""
    property string bluetoothScanError: ""
    property string globalNotice: ""
}
