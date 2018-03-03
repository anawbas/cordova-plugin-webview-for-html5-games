package it.plugin.gamewebview;

import android.app.Dialog;
import android.content.Context;
import android.support.annotation.NonNull;

import org.apache.cordova.LOG;
import org.apache.cordova.PluginResult;


public class GameWebViewDialog extends Dialog {

    protected static final String LOG_TAG = "---- GameWebView";

    private GameWebView gameWebView;

    public GameWebViewDialog(@NonNull Context context, int themeResId, GameWebView gameWebView) {
        super(context, themeResId);

        this.gameWebView = gameWebView;
    }

    @Override
    public void onBackPressed() {
        close(false);
    }

    public void close(boolean hasError) {
        if (!isShowing()) return;

        gameWebView.pluginResult = new PluginResult(hasError ? PluginResult.Status.ERROR : PluginResult.Status.OK);
        gameWebView.pluginResult.setKeepCallback(true);

        gameWebView.callbackContext.sendPluginResult(gameWebView.pluginResult);

        dismiss();
    }
}
