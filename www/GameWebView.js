var exec = require('cordova/exec');


var GameWebView = {
  openURL: (urlObj, successCB, errorCB) => {
    return exec(successCB, errorCB, "GameWebView", "openURL", [urlObj]);
  }
};


module.exports = GameWebView;


if (typeof angular !== 'undefined') {

  angular.module('GameWebView', []).factory('GameWebView', (
    $q,
    $timeout
  ) => {

    function makePromise(fn, args, async) {
      var deferred = $q.defer();

      var success = (response) => (async ? $timeout(() => deferred.resolve(response)) : deferred.resolve(response));
      var fail    = (response) => (async ? $timeout(() => deferred.reject(response))  : deferred.reject(response));

      args.push(success);
      args.push(fail);

      fn.apply(GameWebView, args);

      return deferred.promise;
    };

    return {
      openURL: (urlObj) => {
        return makePromise(GameWebView.openURL, [urlObj], true);
      }
    };

  });

} else {
  window.GameWebView = GameWebView;
}
