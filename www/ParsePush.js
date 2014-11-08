
var exec = require('cordova/exec');

var ParsePush = {
    sendNotification: function (data, successCallback, failCallback) {
        exec(successCallback, failCallback, 'ParsePush', 'sendNotification', [data]);
    },
    getNotification: function (data, successCallback, failCallback) {
        exec(successCallback, failCallback, 'ParsePush', 'getNotification', [data]);
    },
    receiveNotification: function (data) {
        console.log(data);
    },

    getInstallationId: function (successcb, failcb) {
        if (!window.cordova) {
            if (failcb)
                failcb("no cordova");
            return;
        }
        exec(function (response) {
            successcb(response);
        }, function (err) {
            console.log("getAppVersion call failed with error: " + err);
            if (failcb)
                failcb(err);
        }, "ParsePush", "getInstallationId", []);
    },

    setKeyValue: function (key, value, successcb, failcb) {
        if (!window.cordova) {
            if (failcb)
                failcb("no cordova");
            return;
        }
        exec(function (response) {
            successcb();
        }, function (err) {
            console.log("setKeyValue call failed with error: " + err);
            if (failcb)
                failcb(err);
        }, "ParsePush", "setKeyValue", [key, value]);
    }
}

module.exports = ParsePush;