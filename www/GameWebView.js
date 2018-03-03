var exec = require('cordova/exec');

module.exports = {
  show: function(url, successCB, errorCB) {
    // url = { autoLogin, game }
    return exec(successCB, errorCB, "GameWebView", "load", [url]);
  }
}
