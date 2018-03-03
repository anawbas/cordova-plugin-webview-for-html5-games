@objc(GameWebView) class GameWebView : CDVPlugin {

    // MARK: TODO
    //
    // >> offload the UI thread

    // MARK: DOCS
    //
    // >> will load in main window and change 'window.location.href' value:
    // self.webViewEngine.load(URLRequest(url: URL(string: self.urlAutoLogin ?? self.urlGame)!))
    //
    // >> evaluates to true
    // self.webView == self.webViewEngine.engineWebView
    //
    // >> will extend main window under status bar
    // self.viewController.view = self.webViewEngine.engineWebView

    // MARK: VARIABLES

    var initialView : UIView?
    var command : CDVInvokedUrlCommand?
    var browser: GameWebViewBrowser?

    var url : [String: String]!
    var homeURL : String!
    var autoLoginURL : String!
    var gameURL : String!
    var isAutoLogin : Bool!

    var cookies : [HTTPCookie]?
    var IGNORE_COOKIE_METHODS : Bool = true

    // MARK: METHODS

    override func pluginInitialize() {
        super.pluginInitialize()
    }

    @objc(openURL:) func openURL(command: CDVInvokedUrlCommand) {
        self.initialView = self.viewController.view
        self.command = command

        self.shouldStoreCookies()

        self.url = command.arguments[0] as? [String: String]
        self.homeURL = self.url["home"] ?? ""
        self.autoLoginURL = self.url["autoLogin"] ?? ""
        self.gameURL = self.url["game"] ?? ""

        if (self.autoLoginURL.count > 0) {
            self.isAutoLogin = true
        } else {
            self.isAutoLogin = false
        }

        self.browser = (Bundle.main.loadNibNamed("GameWebView", owner: self, options: nil)?[0] as! GameWebViewBrowser)
        self.browser?.gameWebView = self

        self.browser?.loadUrl()
    }

    func shouldStoreCookies() {
        if (self.IGNORE_COOKIE_METHODS) { return }
        if let cookies = HTTPCookieStorage.shared.cookies {
            self.cookies = cookies
        }
    }

    func shouldDeleteNewCookies() {
        if (self.IGNORE_COOKIE_METHODS) { return }
        let cookieStorage = HTTPCookieStorage.shared
        if let oldCookies = self.cookies, let newCookies = cookieStorage.cookies {
            for newCookie in newCookies {
                var deleteCookie = true
                for oldCookie in oldCookies {
                    if (newCookie == oldCookie) { deleteCookie = false }
                }
                if (deleteCookie) { cookieStorage.deleteCookie(newCookie) }
            }
        }
    }

    func close(hasError: Bool) {
        self.viewController.view = self.initialView
        self.commandDelegate.send(CDVPluginResult(status: hasError ? CDVCommandStatus_ERROR : CDVCommandStatus_OK), callbackId: self.command?.callbackId)

        self.initialView = nil
        self.command = nil
        self.browser = nil

        self.url.removeAll()
        self.homeURL.removeAll(keepingCapacity: true)
        self.autoLoginURL.removeAll(keepingCapacity: true)
        self.gameURL.removeAll(keepingCapacity: true)
        self.isAutoLogin = false

        self.shouldDeleteNewCookies()
    }

}

class GameWebViewBrowser : UIView, UIWebViewDelegate, UIGestureRecognizerDelegate {

    // MARK: VARIABLES

    var gameWebView : GameWebView?

    var webViewDidLoad : Int!
    var userDidTapOnce : Bool!
    var gameIsVisible : Bool!

    // MARK: OUTLETS

    @IBOutlet weak var singleTapGestureRecognizer: UITapGestureRecognizer!

    @IBOutlet weak var webView: UIWebView!
    @IBOutlet weak var navigationBar: UINavigationBar!

    @IBOutlet weak var constraintWebViewTopToNavigationBar: NSLayoutConstraint!
    @IBOutlet weak var constraintWebViewTopToSafeArea: NSLayoutConstraint!


    // MARK: ACTIONS

    @IBAction func close(_ sender: UIBarButtonItem) {
        self.gameWebView?.close(hasError: false)
    }

    @IBAction func singleTap(_ sender: UITapGestureRecognizer) {
        self.singleTapGestureRecognizer.isEnabled = false
        self.userDidTapOnce = true
    }

    @IBAction func doubleTap(_ sender: UITapGestureRecognizer) {
        self.toggleFullScreen()
    }

    @IBAction func swipeUp(_ sender: UISwipeGestureRecognizer) {
        self.shouldToggleFullScreen()
    }

    // MARK: METHODS

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        self.webViewDidLoad = 0
        self.userDidTapOnce = false
        self.gameIsVisible = false

        self.webView.scrollView.bounces = false
        self.webView.scrollView.bouncesZoom = false
        self.webView.scrollView.isScrollEnabled = false

        NotificationCenter.default.addObserver(self, selector: #selector(self.orientationDidChange), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        self.gameWebView = nil
    }

    func shouldToggleFullScreen() {
        if (!self.navigationBar.isHidden) {
            self.toggleFullScreen()
        }
    }

    func toggleFullScreen() {
        self.navigationBar.isHidden = !self.navigationBar.isHidden
        self.forceUpdateConstraints()
    }

    func forceUpdateConstraints() {
        self.constraintWebViewTopToNavigationBar.isActive = self.navigationBar.isHidden ? false : true
        self.constraintWebViewTopToSafeArea.isActive = self.navigationBar.isHidden ? true : false
        self.updateConstraintsIfNeeded()
    }

    func orientationDidChange() {
        self.forceUpdateConstraints()
        self.scaleWebView()
    }

    func generateURLRequest(url: URL) -> URLRequest {
        return URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 60)
    }

    func loadUrl() {
        self.webView.loadRequest(self.generateURLRequest(url: URL(string: ((self.gameWebView?.isAutoLogin)! ? self.gameWebView?.autoLoginURL : self.gameWebView?.gameURL)!)!))
    }

    func isHomeURL(_ url: String) -> Bool {
        do {
            let regex = try NSRegularExpression(pattern: (self.gameWebView?.homeURL)!, options: .caseInsensitive)
            let matches = regex.matches(in: url, options: [], range: NSMakeRange(0, url.utf16.count))
            return (matches.count > 0)
        } catch {
            return false
        }
    }

    func scaleWebView() {
        var scale : CGFloat = 1
        if (UIApplication.shared.statusBarOrientation.isPortrait) {
            scale = self.webView.scrollView.contentSize.width / (self.gameWebView?.viewController.view.bounds.width)!
        } else {
            scale = self.webView.scrollView.contentSize.height / (self.gameWebView?.viewController.view.bounds.height)!
        }
        if (scale != self.webView.scrollView.zoomScale) {
          self.webView.scrollView.setZoomScale(scale, animated: true)
        }
    }

    // MARK: DELEGATE METHODS

    func webView( _ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if (!(self.gameWebView?.isAutoLogin)! && self.gameIsVisible && self.userDidTapOnce) {
            if let absURL = request.url?.absoluteString {
                if (self.isHomeURL(absURL)) {
                    self.gameWebView?.close(hasError: false)
                    return false
                }
                if let decodedURL = absURL.removingPercentEncoding {
                    if (self.isHomeURL(decodedURL)) {
                        self.gameWebView?.close(hasError: false)
                        return false
                    }
                }
            }
        }
        return true
    }

    func webViewDidStartLoad(_ webView: UIWebView) {
        // >> needed because method refers to frame and can fire multiple times
        self.webViewDidLoad = self.webViewDidLoad + 1
    }

    func webViewDidFinishLoad(_ webView: UIWebView) {
        // >> needed because method refers to frame and can fire multiple times
        self.webViewDidLoad = self.webViewDidLoad - 1

        // >> this will evaluate to true from the beginning, do not use it
        // if (!(self.gameWebView?.viewController.isViewLoaded)!) {
        //
        if (self.gameWebView?.viewController.presentedViewController != self && self.webViewDidLoad == 0) {

            if (self.gameWebView?.isAutoLogin)! {
                self.gameWebView?.isAutoLogin = false
                self.webView.loadRequest(self.generateURLRequest(url: URL(string: (self.gameWebView?.gameURL)!)!))

            } else {
                self.gameWebView?.viewController.view = self
                self.gameWebView?.viewController.loadViewIfNeeded()
                self.scaleWebView()
                self.gameIsVisible = true
            }

        }
    }

    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        // >> needed because method refers to frame and can fire multiple times
        self.webViewDidLoad = self.webViewDidLoad - 1

        // self.gameWebView?.close(hasError: true)
        self.gameWebView?.close(hasError: false)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

}
