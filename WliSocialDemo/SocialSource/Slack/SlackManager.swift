import Foundation
import UIKit
import WebKit

struct SlackConstants {
    
    static let CLIENT_ID = "<your_slack_client_id>"
    static let CLIENT_SECRET = "<your_slack_client_secret>"
    static let REDIRECT_URI = ""
    static let SCOPE =   "identity.basic,identity.email,identity.avatar"
    
    static let AUTHURL = "https://slack.com/oauth/v2/authorize"
    static let TOKENURL = "https://slack.com/api/oauth.v2.access"
    static let USERINFO = "https://slack.com/api/users.identity"
}

protocol ViewControllerSlackLoginDataDelegate {
    func setData(id:String, name:String, profile:String,email:String)
}

class SlackManagerViewController : UIViewController {
    var parentVC: UIViewController?
    var delegate: ViewControllerSlackLoginDataDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}


extension SlackManagerViewController {
    
    func slackAuthVC(parent: UIViewController) {
        self.parentVC = parent
        let vc = self // UIViewController()
        // Create WebView
        let webView = WKWebView()
        webView.navigationDelegate = self
        vc.view.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: vc.view.topAnchor),
            webView.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor),
            webView.bottomAnchor.constraint(equalTo: vc.view.bottomAnchor),
            webView.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor)
        ])
        
        
        let authURLFull = "\(SlackConstants.AUTHURL)?client_id=\(SlackConstants.CLIENT_ID)&user_scope=\(SlackConstants.SCOPE)&redirect_uri=\(SlackConstants.REDIRECT_URI)"
        
        let urlRequest = URLRequest.init(url: URL.init(string: authURLFull)!)
        webView.load(urlRequest)
        
        // Create Navigation Controller
        let navController = UINavigationController(rootViewController: vc)
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(self.cancelAction))
        vc.navigationItem.leftBarButtonItem = cancelButton
        let textAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
        navController.navigationBar.titleTextAttributes = textAttributes
        vc.navigationItem.title = "slack.com"
        navController.navigationBar.isTranslucent = true
        navController.navigationBar.tintColor = UIColor.black
        navController.navigationBar.barTintColor =  UIColor.black
        navController.modalPresentationStyle = UIModalPresentationStyle.overFullScreen
        navController.modalTransitionStyle = .coverVertical
        
        parentVC?.present(navController, animated: true, completion: nil)
    }
    
    
    @objc func cancelAction() {
        parentVC?.dismiss(animated: true, completion: nil)
    }
    
    
}



extension SlackManagerViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url, let urlString = url.absoluteString.removingPercentEncoding {
            // Check if the URL contains the redirect URI and the access token
            if urlString.starts(with: SlackConstants.REDIRECT_URI) && urlString.contains("code=") {
                // Extract the access token from the URL
                self.dismiss(animated: true, completion: nil)
                
                let components = URLComponents(string: urlString)
                let authCode = components?.queryItems?.first(where: { $0.name == "code" })?.value
                // Here, you have the access token, so you can use it to authenticate the user with Slack
                print("Access Code: \(authCode ?? "N/A")")
                self.exchangeAuthorizationCodeForAccessToken(code: authCode ?? "")
            }
        }
        decisionHandler(.allow)
    }
    
}


extension SlackManagerViewController {
    
    func exchangeAuthorizationCodeForAccessToken(code: String) {
        
        let urlstr = "\(SlackConstants.TOKENURL)?client_id=\(SlackConstants.CLIENT_ID)&client_secret=\(SlackConstants.CLIENT_SECRET)&code=\(code)"
        
        let request = NSMutableURLRequest(url: URL(string: urlstr)!)
        request.httpMethod = "GET"
        // request.httpBody = postData
        request.addValue("application/x-www-form-urlencoded;", forHTTPHeaderField: "Content-Type")
        
        let session = URLSession(configuration: URLSessionConfiguration.default)
        
        let task = session.dataTask(with: request as URLRequest) { (data, response, error) -> Void in
            
            let statusCode = (response as! HTTPURLResponse).statusCode
            if statusCode == 200 {
                
                if let jsonData = data {
                    do {
                        // Parse the JSON data
                        if let jsonResult = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
                            // Access the "authed_user" dictionary
                            if let authedUser = jsonResult["authed_user"] as? [String: Any] {
                                // Access the "access_token" value
                                if let accessToken = authedUser["access_token"] as? String {
                                    // Now you have the "access_token"
                                    print("Access Token: \(accessToken)")
                                    /// get the user detail
                                    self.fetchUserInfo(accessToken: accessToken)
                                } else {
                                    print("Access token not found in JSON")
                                }
                            } else {
                                print("Authed user data not found in JSON")
                            }
                        } else {
                            print("Failed to parse JSON")
                        }
                    } catch {
                        print("Error while parsing JSON: \(error)")
                    }
                }
                
            }
        }
        task.resume()
    }
    
    func fetchUserInfo(accessToken: String) {
        let userInfoURL = URL(string: SlackConstants.USERINFO)!
        
        var request = URLRequest(url: userInfoURL)
        request.httpMethod = "POST"
        
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let session = URLSession.shared
        let task = session.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print("Error fetching user info: \(error)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200,
               let data = data {
                do {
                    // Parse the JSON response
                    if let jsonResult = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        if let user = jsonResult["user"] as? [String: Any] {
                            let name = user["name"] as? String ?? ""
                            let email = user["email"] as? String ?? ""
                            let id = user["id"] as? String ?? ""
                            let profile = user["image_192"] as? String ?? ""
                            print("User Name: \(name)")
                            print("User Email: \(email)")
                            print("User id: \(id)")
                            // Here, send data to server
                            DispatchQueue.main.async {
                                if self.delegate != nil {
                                    self.delegate?.setData(id: id, name: name, profile: profile, email: email)
                                }
                            }
                        } else {
                            print("User data not found in JSON response.")
                        }
                    } else {
                        print("Failed to parse JSON response.")
                    }
                } catch {
                    print("Error while parsing JSON response: \(error)")
                }
            } else {
                print("Invalid HTTP response or data.")
            }
        }
        task.resume()
    }
    
    
}
