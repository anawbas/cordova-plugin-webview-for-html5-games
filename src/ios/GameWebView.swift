import WebKit

//class GameWebViewViewController: UIViewController {
////class GameWebViewViewController: UIViewController, WKUIDelegate, WKNavigationDelegate {
//
//    // MARK: VARIABLES
//
//    var webView : WKWebView!
//
//    let keyAutoLogin = "autoLogin"
//    let keyGame = "game"
//
//    var urlAutoLogin : String!
//    var urlGame : String!
//
//    // MARK: METHODS
//
//    override func loadView() {
//        self.webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
////        self.webView.uiDelegate = self
////        self.webView.navigationDelegate = self
//
//        self.view = self.webView
//        self.view.backgroundColor = UIColor.black
//    }
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
////        (fancyVC.urlAutoLogin ?? "").isEmpty
//        self.webView.load(URLRequest(url: URL(string: self.urlAutoLogin ?? self.urlGame)!))
//    }
//}

class GameWebViewBrowser : UIView, UIWebViewDelegate {

    // MARK: VARIABLES

    var presentingViewController : UIViewController!
    var presentingViewControllerClose : (() -> Void)!

    var urlAutoLogin : String?
    var urlGame : String!

    var isAutoLogin : Bool!

    // MARK: OUTLETS

    @IBOutlet weak var webView: UIWebView!

    // MARK: ACTIONS

    @IBAction func close(_ sender: UIBarButtonItem) {
        self.presentingViewControllerClose()
    }

    // MARK: METHODS

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        self.webView.delegate = self
        self.webView.scrollView.bounces = false
        self.webView.scrollView.bouncesZoom = false

    }

    func loadUrl() {
        isAutoLogin = self.urlAutoLogin != nil
        self.webView.loadRequest(URLRequest(url: URL(string: self.urlAutoLogin ?? self.urlGame)!))
    }

    func webViewDidFinishLoad(_ webView: UIWebView) {
        // if UIApplication.shared.statusBarOrientation == UIInterfaceOrientation.portrait || UIApplication.shared.statusBarOrientation == UIInterfaceOrientation.portraitUpsideDown {
        //     self.navBarTopMargin.constant = UIApplication.shared.statusBarFrame.size.height

        // } else if UIApplication.shared.statusBarOrientation == UIInterfaceOrientation.landscapeLeft || UIApplication.shared.statusBarOrientation == UIInterfaceOrientation.landscapeRight {
        //     self.navBarTopMargin.constant = UIApplication.shared.statusBarFrame.size.width
        // }

        // self.needsUpdateConstraints()

        if isAutoLogin {
            isAutoLogin = false
            self.webView.loadRequest(URLRequest(url: URL(string: self.urlGame)!))

        } else {
            self.presentingViewController.view = self
        }
    }

    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        self.presentingViewControllerClose()
    }


}


@objc(GameWebView) class GameWebView : CDVPlugin {

    // MARK: VARIABLES

    var result : CDVPluginResult!
    var viewControllerInitialView : UIView!

    var url : [String: String]!
    var keyAutoLogin : String!
    var keyGame : String!

    var nibName : String!
    var browser: GameWebViewBrowser!

    // MARK: METHODS

    @objc(load:) func load(command: CDVInvokedUrlCommand) {
//        self.webViewEngine.load(URLRequest(url: URL(string: self.urlAutoLogin ?? self.urlGame)!)) // will load in same window and change 'window.location.href' value
//        self.webView == self.webViewEngine.engineWebView // true
//        self.viewController.view = self.webViewEngine.engineWebView // will extend webView under status bar

        self.result = CDVPluginResult(status: CDVCommandStatus_NO_RESULT)
        self.viewControllerInitialView = self.viewController.view

        self.keyAutoLogin = "autoLogin"
        self.keyGame = "game"

        self.nibName = "GameWebView"
        self.browser = Bundle.main.loadNibNamed(self.nibName, owner: self, options: nil)?[0] as! GameWebViewBrowser
        self.browser.presentingViewController = self.viewController
        self.browser.presentingViewControllerClose = self.close

        self.url = command.arguments[0] as? [String: String]
        self.browser.urlAutoLogin = url[self.keyAutoLogin] ?? nil
        self.browser.urlGame = url[self.keyGame]
        self.browser.loadUrl()

        self.commandDelegate.send(self.result, callbackId: command.callbackId)
    }

    func close() {
        self.viewController.view = self.viewControllerInitialView
        self.viewControllerInitialView = nil

        self.browser.presentingViewController = nil
        self.browser = nil

        self.result = nil
    }
}
