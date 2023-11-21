//
//  LinkedInManager.swift
//  WliLinkedInDemo
//
//  Created by wli on 21/07/23.
//

import Foundation
import UIKit
import WebKit

struct LinkedInConstants {
    
    static let CLIENT_ID = "<your_linkedin_client_id>"
    static let CLIENT_SECRET = "<your_linkedin_client_secret>"
    static let REDIRECT_URI = "<your_redirect_uri>" /// eg:  "https://com.example.linkedin.oauth/oauth"
    static let SCOPE = "r_liteprofile%20r_emailaddress" //Get lite profile info and e-mail address
    
    static let AUTHURL = "https://www.linkedin.com/oauth/v2/authorization"
    static let TOKENURL = "https://www.linkedin.com/oauth/v2/accessToken"
}

protocol ViewControllerLinkedInLoginDataDelegate {
    func setData(id:String, fname:String, lname:String,email:String)
}

class LinkedInManagerViewController : UIViewController {
    var parentVC: UIViewController?
    var delegate: ViewControllerLinkedInLoginDataDelegate?
    
    var lkdID = ""
    var fname = ""
    var lname = ""
    var email = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}


extension LinkedInManagerViewController {
    
    func linkedInAuthVC(parent: UIViewController) {
        self.parentVC = parent
        let linkedInVC = self // UIViewController()
        // Create WebView
        let webView = WKWebView()
        webView.navigationDelegate = self
        linkedInVC.view.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: linkedInVC.view.topAnchor),
            webView.leadingAnchor.constraint(equalTo: linkedInVC.view.leadingAnchor),
            webView.bottomAnchor.constraint(equalTo: linkedInVC.view.bottomAnchor),
            webView.trailingAnchor.constraint(equalTo: linkedInVC.view.trailingAnchor)
        ])
        
        let state = "linkedin\(Int(NSDate().timeIntervalSince1970))"
        
        let authURLFull = LinkedInConstants.AUTHURL + "?response_type=code&client_id=" + LinkedInConstants.CLIENT_ID + "&scope=" + LinkedInConstants.SCOPE + "&state=" + state + "&redirect_uri=" + LinkedInConstants.REDIRECT_URI
        
        
        let urlRequest = URLRequest.init(url: URL.init(string: authURLFull)!)
        webView.load(urlRequest)
        
        // Create Navigation Controller
        let navController = UINavigationController(rootViewController: linkedInVC)
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(self.cancelAction))
        linkedInVC.navigationItem.leftBarButtonItem = cancelButton
        let textAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
        navController.navigationBar.titleTextAttributes = textAttributes
        linkedInVC.navigationItem.title = "linkedin.com"
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



extension LinkedInManagerViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        RequestForCallbackURL(request: navigationAction.request)
        
        //Close the View Controller after getting the authorization code
        if let urlStr = navigationAction.request.url?.absoluteString {
            if urlStr.contains("?code=") {
                parentVC?.dismiss(animated: true, completion: nil)
            }
        }
        decisionHandler(.allow)
    }
    
    func RequestForCallbackURL(request: URLRequest) {
        // Get the authorization code string after the '?code=' and before '&state='
        let requestURLString = (request.url?.absoluteString)! as String
        if requestURLString.hasPrefix(LinkedInConstants.REDIRECT_URI) {
            if requestURLString.contains("?code=") {
                if let range = requestURLString.range(of: "=") {
                    let linkedinCode = requestURLString[range.upperBound...]
                    if let range = linkedinCode.range(of: "&state=") {
                        let linkedinCodeFinal = linkedinCode[..<range.lowerBound]
                        handleAuth(linkedInAuthorizationCode: String(linkedinCodeFinal))
                    }
                }
            }
        }
    }
    
    func handleAuth(linkedInAuthorizationCode: String) {
        linkedinRequestForAccessToken(authCode: linkedInAuthorizationCode)
    }
    
    
}

extension LinkedInManagerViewController {
    
    func linkedinRequestForAccessToken(authCode: String) {
        let grantType = "authorization_code"
        
        // Set the POST parameters.
        let postParams = "grant_type=" + grantType + "&code=" + authCode + "&redirect_uri=" + LinkedInConstants.REDIRECT_URI + "&client_id=" + LinkedInConstants.CLIENT_ID + "&client_secret=" + LinkedInConstants.CLIENT_SECRET
        let postData = postParams.data(using: String.Encoding.utf8)
        
        let request = NSMutableURLRequest(url: URL(string: LinkedInConstants.TOKENURL)!)
        request.httpMethod = "POST"
        request.httpBody = postData
        request.addValue("application/x-www-form-urlencoded;", forHTTPHeaderField: "Content-Type")
        
        let session = URLSession(configuration: URLSessionConfiguration.default)
        
        let task = session.dataTask(with: request as URLRequest) { (data, response, error) -> Void in
            
            let statusCode = (response as! HTTPURLResponse).statusCode
            if statusCode == 200 {
                let results = try! JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [AnyHashable: Any]
                
                let accessToken = results?["access_token"] as! String
                print("accessToken is: \(accessToken)")
                
                let expiresIn = results?["expires_in"] as! Int
                print("expires in: \(expiresIn)")
                
                // Get user's id, first name, last name, profile pic url
                self.fetchLinkedInUserProfile(accessToken: accessToken)
            }
        }
        task.resume()
    }
    
    func fetchLinkedInUserProfile(accessToken: String) {
        let tokenURLFull = "https://api.linkedin.com/v2/me?projection=(id,firstName,lastName,profilePicture(displayImage~:playableStreams))&oauth2_access_token=\(accessToken)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        let verify: NSURL = NSURL(string: tokenURLFull!)!
        let request: NSMutableURLRequest = NSMutableURLRequest(url: verify as URL)
        let task = URLSession.shared.dataTask(with: request as URLRequest) { data, response, error in
            if error == nil {
                
                if let jsonData = data {
                    do {
                        // Decode the JSON Data into UserResponse object
                        let decoder = JSONDecoder()
                        let userResponse = try decoder.decode(UserResponse.self, from: jsonData)
                        
                        // Access the properties of the UserResponse
                        print("First Name: \(userResponse.firstName.localized.en_US)")
                        print("Last Name: \(userResponse.lastName.localized.en_US)")
                        print("ID: \(userResponse.id)")
                        
                        self.lkdID = userResponse.id
                        self.fname = userResponse.firstName.localized.en_US
                        self.lname = userResponse.lastName.localized.en_US
                        
                        /*
                         if let pictureUrls = userResponse?.profilePicture.displayImage.elements[2].identifiers[0].identifier {
                         print("LinkedIn Profile Avatar URL: \(linkedinProfilePic ?? "")")
                         } */
                        
                        // Get user's email address
                        self.fetchLinkedInEmailAddress(accessToken: accessToken)
                        
                    } catch {
                        print("Error decoding JSON: \(error)")
                    }
                    
                }
            }
        }
        task.resume()
    }
    
    func fetchLinkedInEmailAddress(accessToken: String) {
        let tokenURLFull = "https://api.linkedin.com/v2/emailAddress?q=members&projection=(elements*(handle~))&oauth2_access_token=\(accessToken)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        let verify: NSURL = NSURL(string: tokenURLFull!)!
        let request: NSMutableURLRequest = NSMutableURLRequest(url: verify as URL)
        let task = URLSession.shared.dataTask(with: request as URLRequest) { data, response, error in
            if error == nil {
                let linkedInEmailModel = try? JSONDecoder().decode(LinkedInEmailModel.self, from: data!)
                
                // LinkedIn Email
                let linkedinEmail: String! = linkedInEmailModel?.elements[0].elementHandle.emailAddress
                print("LinkedIn Email: \(linkedinEmail ?? "")")
                
                DispatchQueue.main.async {
                    if let delegat = self.delegate {
                        delegat.setData(id: self.lkdID, fname: self.fname, lname: self.lname, email: linkedinEmail ?? "")
                    }
                    
                    self.dismiss(animated: true, completion: nil)
                }
            }
        }
        task.resume()
    }
    
}
