//
//  ViewController.swift
//  WliLinkedInDemo
//
//  Created by wli on 21/07/23.
//

import UIKit



class ViewController: UIViewController {
    
    
    @IBOutlet weak var profile: UIImageView!
    @IBOutlet weak var lblLinkedID: UILabel!
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var lblEmail: UILabel!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Social Authentications"
        self.lblLinkedID.isHidden = true
        self.setUpHiddenLabels(hidden: true)
    }
    
    func setUpHiddenLabels(hidden:Bool) {
       
        self.lblName.isHidden = hidden
        self.lblEmail.isHidden = hidden
    }
    
    @IBAction func btnLinkedinLogin(_ sender: UIButton) {
        let vc = LinkedInManagerViewController()
        vc.delegate = self
        vc.linkedInAuthVC(parent: self)
    }
    
    @IBAction func btnSlackLogin(_ sender: UIButton) {
        let vc = SlackManagerViewController()
        vc.delegate = self
        vc.slackAuthVC(parent: self)
    }
}

extension ViewController : ViewControllerLinkedInLoginDataDelegate {
    func setData(id: String, fname: String, lname: String, email: String) {
        self.setUpHiddenLabels(hidden: false)
        
        if fname.count > 0 && lname.count > 0 {
            self.lblName.text = "Full Name: " + fname + " " + lname
        }
        if id.count > 0 {
            self.lblLinkedID.text = "ID: " + id
        }
        if email.count > 0 {
            self.lblEmail.text = "Email: " + email
        }
    }
    
    
}



extension ViewController : ViewControllerSlackLoginDataDelegate {
    func setData(id: String, name: String, profile: String, email: String) {
        self.setUpHiddenLabels(hidden: false)
        
        if name.count > 0 {
            self.lblName.text = "Name: " + name
        }
        if id.count > 0 {
            self.lblLinkedID.text = "ID: " + id
        }
        if email.count > 0 {
            self.lblEmail.text = "Email: " + email
        }
        if profile.count > 0 {
            DispatchQueue.global().async { [weak self] in
                if let data = try? Data(contentsOf: URL.init(string: profile)!) {
                    if let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            self?.profile.image = image
                        }
                    }
                }
            }
        }
    }
    
    
}


