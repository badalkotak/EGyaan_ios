//
//  ViewController.swift
//  EGyaan
//
//  Created by Badal Kotak on 28/12/16.
//  Copyright © 2016 EGyaan. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITextFieldDelegate {

    struct defaultsKeys {
        static let remember_me = "remember_me"
    }
    
    var databasePath = String()
    
    override func viewDidLoad() {
        
        NotificationCenter.default.addObserver(self, selector: #selector(TimetableDetailedViewController.networkStatusChanged(_:)), name: NSNotification.Name(rawValue: ReachabilityStatusChangedNotification), object: nil)
        Reach().monitorReachabilityChanges()
        
        let status = Reach().connectionStatus()
        switch status {
        case .unknown, .offline:
            print("Not connected")
        case .online(.wwan):
            print("Connected via WWAN")
        case .online(.wiFi):
            print("Connected via WiFi")
        }

        // Check if database already exists, if not create it
        
        let filemgr = FileManager.default
        let dirPaths = filemgr.urls(for: .documentDirectory,
                                    in: .userDomainMask)
        
        databasePath = dirPaths[0].appendingPathComponent("egyaan.db").path
        
        if !filemgr.fileExists(atPath: databasePath as String)
        {
            
            let egyaanDB = FMDatabase(path: databasePath as String)
            
//            if egyaanDB == nil {
//                print("Error: \(egyaanDB.lastErrorMessage())")
//            }
            
            if (egyaanDB.open())
            {
                let sql_stmt = "CREATE TABLE egn_student (id int(11) PRIMARY KEY,firstname varchar(30) NOT NULL,lastname varchar(30) DEFAULT NULL,email varchar(50) NOT NULL UNIQUE,student_passwd varchar(15) NOT NULL,mobile bigint(15) DEFAULT NULL UNIQUE,gender varchar(1) DEFAULT NULL,parent_name varchar(30) DEFAULT NULL,parent_email varchar(30) DEFAULT NULL UNIQUE,parent_passwd varchar(15) NOT NULL,parent_mobile bigint(12) NOT NULL UNIQUE,student_profile_photo varchar(100) DEFAULT NULL,parent_profile_photo varchar(100) DEFAULT NULL,batch_id int(11) NOT NULL,branch_id int(11) NOT NULL)"
                
                    if !(egyaanDB.executeStatements(sql_stmt)) {
                        print("Error here 1: \(egyaanDB.lastErrorMessage())")
                    }
                    else{
                        print("Table created")
                }
                
                egyaanDB.close()
            } else {
                print("Error here 2: \(egyaanDB.lastErrorMessage())")
            }
            

        }
        
        
        
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //Increase size of Activity Indicator
        let transform = CGAffineTransform(scaleX: 3.5, y: 3.5); activityIndicator.transform = transform
        
        //Function call to hide keyboard when we touch on a black space
        self.hideKeyboardWhenTappedAround()
        Password_textField.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // Getting
        let defaults = UserDefaults.standard
        if let checkLogin = defaults.string(forKey: defaultsKeys.remember_me) {
            
            if(checkLogin=="true")
            {
                DispatchQueue.main.async(execute: {self.performSegue(withIdentifier: "LoginSegue", sender: self)})
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    //Auto scroll textare when keyboard pops up
    func textFieldDidBeginEditing(_ textField: UITextField) { // became first responder
        
        //move textfields up
        let myScreenRect: CGRect = UIScreen.main.bounds
        let keyboardHeight : CGFloat = 316
        
        UIView.beginAnimations( "animateView", context: nil)
        //var movementDuration:TimeInterval = 0.35
        var needToMove: CGFloat = 0
        
        var frame : CGRect = self.view.frame
        if (textField.frame.origin.y + textField.frame.size.height + /*self.navigationController.navigationBar.frame.size.height + */UIApplication.shared.statusBarFrame.size.height > (myScreenRect.size.height - keyboardHeight)) {
            needToMove = (textField.frame.origin.y + textField.frame.size.height + /*self.navigationController.navigationBar.frame.size.height +*/ UIApplication.shared.statusBarFrame.size.height) - (myScreenRect.size.height - keyboardHeight);
        }
        
        frame.origin.y = -needToMove
        self.view.frame = frame
        UIView.commitAnimations()
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        //move textfields back down
        UIView.beginAnimations( "animateView", context: nil)
        //var movementDuration:TimeInterval = 0.35
        var frame : CGRect = self.view.frame
        frame.origin.y = 0
        self.view.frame = frame
        UIView.commitAnimations()
    }
    
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var Username_textField: UITextField!
    
    
    @IBOutlet weak var Password_textField: UITextField!
    
    
    //Func that will execute when Login button is clicked
    @IBAction func LoginChecker(_ sender: UIButton, forEvent event: UIEvent) {
        
        //start activity indicator
        activityIndicator.startAnimating()
        
        
        let username = self.Username_textField.text
        let password = self.Password_textField.text
        
        if(username!.isEmpty || password!.isEmpty)
        {
            self.activityIndicator.stopAnimating()
            let alert = UIAlertController(title: "Error", message: "Please input all the fields!", preferredStyle: UIAlertControllerStyle.alert)
            
            // add an action (button)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            
            // show the alert
            self.present(alert, animated: true, completion: nil)
            
        }
            
        else
        {
            //Add proper working of validation on PHP pages
            self.validate("http://192.168.1.13/Projects/EGyaan_OpenSource/modules/mobile/functions/login.php?username="+username!+"&password="+password!);
        }
    }
    
    
    func validate(_ url: String)
    {
        let url:URL = URL(string: url)!
        let session = URLSession.shared
        
        let request = NSMutableURLRequest(url: url)
        request.httpMethod = "POST"
        request.cachePolicy = NSURLRequest.CachePolicy.reloadIgnoringLocalAndRemoteCacheData
        
        let task = session.dataTask(with: request as URLRequest, completionHandler: {(data, response, error) in
            guard let _:Data = data, let _:URLResponse = response  , error == nil else {
                
                let alert = UIAlertController(title: "Error", message: "Something when wrong!", preferredStyle: UIAlertControllerStyle.alert)
                
                // add an action (button)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                
                self.activityIndicator.stopAnimating();
                // show the alert
                self.present(alert, animated: true, completion: nil)
                
                return
            }
            self.extractJson(data!)
        })
        
        task.resume();
    }
    
    func extractJson(_ data: Data)
    {
        let json: Any?
        
        do{
            json = try JSONSerialization.jsonObject(with: data, options: [])
        }
            
        catch
        {
            return
        }
        
//        guard let data_list = json as? NSArray else
//        {
//            return
//        }
        
        if let outcome_list = json as? NSArray
        {
            print(outcome_list.count)
            for i in 0 ..< outcome_list.count
            {
                if let outcome_obj = outcome_list[i] as? NSDictionary
                {
                    if let result = outcome_obj["status"] as? String
                    {
                        DispatchQueue.main.async(execute: {self.activityIndicator.stopAnimating()})
                        if(result=="success")
                        {
                            let defaults = UserDefaults.standard
                            defaults.set("true", forKey: defaultsKeys.remember_me)
                            
                            let details_obj = outcome_obj["details"] as! NSDictionary
                            
//                            let role_id=details_obj["role_id"] as! Integer
                            let user_id=details_obj["user_id"] as! String
                            let user_id_int=Int(user_id)
                            let batch_id=details_obj["batch_id"] as! String
                            let batch_id_int = Int(batch_id)
                            let firstname=details_obj["firstname"] as! String
                            let lastname=details_obj["lastname"] as! String
                            let email=details_obj["email"] as! String
                            let student_passwd=details_obj["student_passwd"] as! String
                            let gender=details_obj["gender"] as! String
                            let mobile=details_obj["mobile"] as! String
                            let mobile_int=Int(mobile)!
                            let student_profile_photo=details_obj["student_profile_photo"] as! String
                            let parent_profile_photo=details_obj["parent_profile_photo"] as! String
                            let branch_id=details_obj["branch_id"] as! String
                            let branch_id_int=Int(branch_id)
                            let parent_name=details_obj["parent_name"] as! String
                            let parent_email=details_obj["parent_email"] as! String
                            let parent_passwd=details_obj["parent_passwd"] as! String
                            let parent_mobile=details_obj["parent_mobile"] as! String
                            
                            
                            //For insertion
                            let egyaanDB = FMDatabase(path: databasePath as String)
                            
                            if (egyaanDB.open()) {
                                
                                let insertSQL = "INSERT INTO egn_student(id, firstname, lastname, email, student_passwd, mobile, gender, parent_name, parent_email, parent_passwd, parent_mobile, student_profile_photo, parent_profile_photo, batch_id, branch_id) VALUES ('\(user_id_int!)','\(firstname)','\(lastname)','\(email)','\(student_passwd)','\(mobile_int)','\(gender)','\(parent_name)','\(parent_email)','\(parent_passwd)','\(parent_mobile)','\(student_profile_photo)','\(parent_profile_photo)','\(batch_id_int!)','\(branch_id_int!)')"
                                
                                if !egyaanDB.executeStatements(insertSQL) {
                                    print("Error: \(egyaanDB.lastErrorMessage())")
                                }
                            } else {
                                print("Error: \(egyaanDB.lastErrorMessage())")
                            }
                            
                            DispatchQueue.main.async(execute: {self.performSegue(withIdentifier: "LoginSegue", sender: self)})
                        }
                            
                        else
                        {
                            DispatchQueue.main.async(execute: {self.showAlert()})
                        }
                    }
                }
            }
        }
    }
    
    func showAlert()
    {
        let alert = UIAlertController(title: "Error", message: "Invalid username/password!", preferredStyle: UIAlertControllerStyle.alert)
        
        // add an action (button)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        
        // show the alert
        self.present(alert, animated: true, completion: nil)
    }
}

//hiding keyboard function
extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func networkStatusChanged(_ notification: Notification) {
        let userInfo = (notification as NSNotification).userInfo
//        print(userInfo!)
        
    }

}

