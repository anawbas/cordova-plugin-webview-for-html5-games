# cordova-plugin-webview-for-html5-games
A native WebView for html5 games, to provide a richer gaming experience.

----------
## INSTALL
```sh
cd /path/to/my-app
# cordova plugin rm cordova-plugin-webview-for-html5-games
cordova plugin add path/to/cordova-plugin-webview-for-html5-games
```

----------
## METHODS
- [openURL](#openURL)

----------
## openURL
```js
window.GameWebView.openURL({
  autoLogin : `string representing a valid url here`,
  game      : `string representing a valid url here`,
  home      : `string representing a valid url here`
}, (success) => {
  console.log(`---- GameWebView -> SUCCESS`);
}, (error) => {
  console.log(`---- GameWebView -> ERROR`);
});
```
or, if you are using **AngularJS** with [**gulp-ng-annotate**](https://github.com/Kagami/gulp-ng-annotate):
```js
angular
.module(`YOUR_ANGULAR_MODULE_HERE`, [
  `your other dependencies`,
  `GameWebView`
]);
/* @ngInject */
function GameController(GameWebView) {
  GameWebView.openURL({
    autoLogin : `string representing a valid url here`,
    game      : `string representing a valid url here`,
    home      : `string representing a valid url here`
  })
  .then(success => {
    console.log(`---- GameWebView -> SUCCESS`);
  }, error => {
    console.log(`---- GameWebView -> ERROR`);
  });
}
```
