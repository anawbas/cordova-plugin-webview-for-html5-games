package it.plugin.gamewebview;


import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.DialogInterface;
import android.net.http.SslError;
import android.os.Build;
import android.support.v4.view.MotionEventCompat;
import android.view.GestureDetector;
import android.view.LayoutInflater;
import android.view.MotionEvent;
import android.view.View;
import android.view.Window;
import android.view.WindowManager;
import android.webkit.CookieManager;
import android.webkit.CookieSyncManager;
import android.webkit.SslErrorHandler;
import android.webkit.WebResourceError;
import android.webkit.WebResourceRequest;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.Button;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.LOG;
import org.apache.cordova.PluginResult;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.UnsupportedEncodingException;
import java.net.URLDecoder;
import java.util.regex.Pattern;


@SuppressLint({ "ClickableViewAccessibility", "SetJavaScriptEnabled" })
public class GameWebView extends CordovaPlugin {

    protected static final String LOG_TAG = "---- GameWebView";

    private Activity activity;
    public CallbackContext callbackContext;
    public boolean userDidTapOnce = false;
    public boolean gameIsVisible = false;

    private JSONObject argsObj;
    private String homeURL;
    private String autoLoginURL;
    private String gameURL;
    private boolean isAutoLogin;

    private GameWebViewDialog dialog;
    private View dialogView;
    private WebView webView;
    private WebViewClient webViewClient;
    private WebSettings webSettings;
    private Button buttonClose;
    private WindowManager.LayoutParams lp;
    public PluginResult pluginResult;

    private int LAYOUT_gamewebview;
    private int ID_gamewebview_webview;
    private int ID_gamewebview_button_close;
    private int DIMEN_gamewebview_swipeup_delta_x;
    private int DIMEN_gamewebview_swipeup_delta_y;

    private float gamewebview_swipeup_delta_x;
    private float gamewebview_swipeup_delta_y;
    private float swipeup_X_start;
    private float swipeup_X_end;
    private float swipeup_Y_start;
    private float swipeup_Y_end;

    private GameWebView getGameWebViewInstance() {
        return this;
    }

    @Override
    public void onReset() {
        dialog.close(false);
    }

    public void onDestroy() {
        dialog.close(false);
    }

    @Override
    public boolean execute(final String action, JSONArray args, final CallbackContext callbackContext) throws JSONException {
        super.execute(action, args, callbackContext);

        this.activity = cordova.getActivity();
        this.callbackContext = callbackContext;

        if (action.equals("openURL")) {
            final String packageName = activity.getPackageName();

            LAYOUT_gamewebview = activity.getResources().getIdentifier("gamewebview", "layout", packageName);
            ID_gamewebview_webview = activity.getResources().getIdentifier("gamewebview_webview", "id", packageName);
            ID_gamewebview_button_close = activity.getResources().getIdentifier("gamewebview_button_close", "id", packageName);
            DIMEN_gamewebview_swipeup_delta_x = activity.getResources().getIdentifier("gamewebview_swipeup_delta_x", "dimen", packageName);
            DIMEN_gamewebview_swipeup_delta_y = activity.getResources().getIdentifier("gamewebview_swipeup_delta_y", "dimen", packageName);

            gamewebview_swipeup_delta_x = activity.getResources().getDimension(DIMEN_gamewebview_swipeup_delta_x);
            gamewebview_swipeup_delta_y = activity.getResources().getDimension(DIMEN_gamewebview_swipeup_delta_x);

            userDidTapOnce = false;
            gameIsVisible = false;

            argsObj = args.getJSONObject(0);
            homeURL = argsObj.optString("home");
            autoLoginURL = argsObj.optString("autoLogin");
            gameURL = argsObj.optString("game");

            if (autoLoginURL.length() > 0) {
                isAutoLogin = true;
            } else {
                isAutoLogin = false;
            }

            Runnable runnable = new Runnable() {
                @Override
                public void run() {
                    dialog = new GameWebViewDialog(activity, android.R.style.Theme_NoTitleBar, getGameWebViewInstance());
                    dialog.getWindow().getAttributes().windowAnimations = android.R.style.Animation_Dialog;
                    dialog.requestWindowFeature(Window.FEATURE_NO_TITLE);
                    dialog.setCancelable(true);
                    dialog.setOnShowListener(new DialogInterface.OnShowListener() {
                        @Override
                        public void onShow(DialogInterface dialog) {
                            gameIsVisible = true;
                        }
                    });

//                    dialogView = View.inflate(activity, LAYOUT_gamewebview, null);
                    dialogView = activity.getLayoutInflater().inflate(LAYOUT_gamewebview, null);
                    webView = dialogView.findViewById(ID_gamewebview_webview);
                    buttonClose = dialogView.findViewById(ID_gamewebview_button_close);

                    webViewClient = new CustomWebViewClient();
                    webView.setWebViewClient(webViewClient);

                    webSettings = webView.getSettings();
                    webSettings.setJavaScriptEnabled(true);
                    webSettings.setJavaScriptCanOpenWindowsAutomatically(true);
                    webSettings.setBuiltInZoomControls(false);
                    webSettings.setSupportZoom(false);
//                    webSettings.setLayoutAlgorithm(WebSettings.LayoutAlgorithm.NORMAL);
                    webSettings.setLayoutAlgorithm(WebSettings.LayoutAlgorithm.SINGLE_COLUMN);
                    webSettings.setLoadWithOverviewMode(true);
                    webSettings.setUseWideViewPort(true);
                    webSettings.setDomStorageEnabled(true);

                    if (android.os.Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1) {
                        webSettings.setMediaPlaybackRequiresUserGesture(false);
                    }
                    if (android.os.Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        webSettings.setSafeBrowsingEnabled(false);
                    }

//                    CookieManager.getInstance().removeAllCookie();

                    CookieManager.getInstance().setAcceptCookie(true);

                    if (android.os.Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                        CookieManager.getInstance().setAcceptThirdPartyCookies(webView,true);
                    }

                    final String overrideUserAgent = preferences.getString("OverrideUserAgent", null);
                    final String appendUserAgent = preferences.getString("AppendUserAgent", null);
                    if (overrideUserAgent != null) {
                        webSettings.setUserAgentString(overrideUserAgent);
                    }
                    if (appendUserAgent != null) {
                        webSettings.setUserAgentString(webSettings.getUserAgentString() + appendUserAgent);
                    }


                    buttonClose.setOnClickListener(new View.OnClickListener() {
                        @Override
                        public void onClick(View v) {
                            dialog.close(false);
                        }
                    });

                    webView.setOnTouchListener(new View.OnTouchListener() {
                        private GestureDetector gestureDetector = new GestureDetector(activity, new GestureDetector.SimpleOnGestureListener() {
                            @Override
                            public boolean onDoubleTap(MotionEvent e) {
                                toggleVisibilityForButton(buttonClose);
                                return super.onDoubleTap(e);
                            }
                        });
                        @Override
                        public boolean onTouch(View v, MotionEvent event) {
                            gestureDetector.onTouchEvent(event);

                            if (buttonClose.getVisibility() == View.VISIBLE) {
                                int action = MotionEventCompat.getActionMasked(event);
                                switch (action) {
                                    case (MotionEvent.ACTION_DOWN):
                                        userDidTapOnce = true;
                                        swipeup_X_start = event.getRawX();
                                        swipeup_Y_start = event.getRawY();
                                        break;
                                    case (MotionEvent.ACTION_MOVE):
                                    case (MotionEvent.ACTION_UP):
                                        swipeup_X_end = event.getRawX();
                                        swipeup_Y_end = event.getRawY();
                                        if ((Math.abs(swipeup_X_end - swipeup_X_start) <= gamewebview_swipeup_delta_x)
                                        && ((swipeup_Y_start - swipeup_Y_end) >= gamewebview_swipeup_delta_y)) {
                                            toggleVisibilityForButton(buttonClose);
                                        }
                                        break;
                                    default:
                                        break;
                                }
                            }

                            return false;
                        }
                    });

                    webView.loadUrl(isAutoLogin ? autoLoginURL : gameURL);

                    webView.setScrollBarStyle(WebView.SCROLLBARS_OUTSIDE_OVERLAY);
                    webView.setVerticalScrollBarEnabled(false);
                    webView.setHorizontalScrollBarEnabled(false);
                    webView.setScrollContainer(false);
                }
            };
            activity.runOnUiThread(runnable);

        } else {
            pluginResult = new PluginResult(PluginResult.Status.ERROR);
            pluginResult.setKeepCallback(true);

            callbackContext.sendPluginResult(pluginResult);

            return false;
        }

        return true;
    }

    private void toggleVisibilityForButton(Button button) {
        switch (button.getVisibility()) {
            case View.VISIBLE:
                button.setVisibility(View.GONE);
                break;
            case View.GONE:
                button.setVisibility(View.VISIBLE);
            default:
                break;
        }
    }

    private boolean isHomeURL(String url) {
        // >> does NOT work
//        return Pattern.compile(homeURL, Pattern.CASE_INSENSITIVE | Pattern.UNICODE_CASE).matcher(url).lookingAt();

        return url.contains(homeURL);
    }

    private boolean shouldPreventLoadingHomeURL(String url) {
        final String encodedURL = url;
        String decodedURL = "";
        try {
            decodedURL = URLDecoder.decode(encodedURL, "UTF-8");
        } catch (UnsupportedEncodingException e) {
            // >> do nothing
        }
        boolean matches = false;

        if (isHomeURL(encodedURL)) matches = true;
        if (isHomeURL(decodedURL)) matches = true;

        if (matches) {
            dialog.close(false);
            return true;

        } else {
            return false;
        }
    }

    class CustomWebViewClient extends WebViewClient {

        @Override
        public void onPageFinished(WebView view, String url) {
            super.onPageFinished(view, url);

            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.LOLLIPOP) {
                CookieManager.getInstance().flush();
            } else {
                CookieSyncManager.getInstance().sync();
            }

            if (!dialog.isShowing()) {
                if (isAutoLogin) {
                    isAutoLogin = false;
                    webView.loadUrl(gameURL);
                } else {
                    Runnable runnable = new Runnable() {
                        @Override
                        public void run() {
                            lp = new WindowManager.LayoutParams();
                            lp.copyFrom(dialog.getWindow().getAttributes());
                            lp.width = WindowManager.LayoutParams.MATCH_PARENT;
                            lp.height = WindowManager.LayoutParams.MATCH_PARENT;

                            dialog.setContentView(dialogView);
                            dialog.show();
                            dialog.getWindow().setAttributes(lp);
                        }
                    };
                    activity.runOnUiThread(runnable);
                }
            }
        }

        @Override
        public void onReceivedError(WebView view, WebResourceRequest request, WebResourceError error) {
            super.onReceivedError(view, request, error);
            dialog.close(true);
        }

        @Override
        public boolean shouldOverrideUrlLoading(WebView view, String url) {
            if (!isAutoLogin && gameIsVisible && userDidTapOnce) {
                return shouldPreventLoadingHomeURL(url);
            } else {
                return false;
            }
        }

        @Override
        public boolean shouldOverrideUrlLoading(WebView view, WebResourceRequest request) {
            if (!isAutoLogin && gameIsVisible && userDidTapOnce) {
                return shouldPreventLoadingHomeURL(request.getUrl().toString());
            } else {
                return false;
            }
        }

        @Override
        public void onReceivedSslError(WebView view, SslErrorHandler handler, SslError error) {
          handler.proceed();
        }
    }

}
