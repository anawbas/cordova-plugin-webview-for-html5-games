# Cordova plugin: webview for html5 gams

Embedding a custom webview into the app to enhance the gaming experience of HTML5 games and the overall stability of the app.

```sh
cd path/to/myApp
# cordova plugin rm  cordova-plugin-webview-for-html5-games
cordova plugin add  path/to/cordova-plugin-webview-for-html5-games
```

```js
/*
 * 'GameWebView' will load 'auto login URL' in the background (if present),
 * then silently redirect to 'game ULR',
 * finally showing the custom webview.
*/
window.GameWebView.show({ game: 'game URL' [,autoLogin: 'auto login URL'] }, msg => console.log(msg), msg => console.log(msg))
```
