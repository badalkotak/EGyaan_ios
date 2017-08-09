//
//  DashboardViewController.swift
//  EGyaan
//
//  Created by Badal Kotak on 29/12/16.
//  Copyright © 2016 EGyaan. All rights reserved.
//

import UIKit

class DasboardViewController: UIViewController{
    @IBOutlet weak var navigationBar: UINavigationBar!
    
    @IBOutlet var statusLabel: UILabel!
    var databasePath = String()
    var img = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(TimetableDetailedViewController.networkStatusChanged(_:)), name: NSNotification.Name(rawValue: ReachabilityStatusChangedNotification), object: nil)
        Reach().monitorReachabilityChanges()
        
        let status = Reach().connectionStatus()
        switch status {
        case .unknown, .offline:
            statusLabel.text = "Offline"
        case .online(.wwan),.online(.wiFi):
            statusLabel.text = "Online"
    }
}
    

    @IBAction func openTT(_ sender: UIButton) {
        performSegue(withIdentifier: "openTTSegue", sender: self)
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let filemgr = FileManager.default
        let dirPaths = filemgr.urls(for: .documentDirectory,
                                    in: .userDomainMask)
        
        databasePath = dirPaths[0].appendingPathComponent("egyaan.db").path
        var egyaanDB = FMDatabase(path: databasePath as String)
        
        if (egyaanDB.open())
        {
            let get="SELECT student_profile_photo FROM egn_student"
            
            let arr=NSArray()
            let results = egyaanDB.executeQuery(get, withArgumentsIn: arr as! [Any])
            
            while results?.next() == true
            {
                img = results!.string(forColumn: "student_profile_photo")!
            }
            egyaanDB.close()
        }
        
        //check if file exists
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let url = NSURL(fileURLWithPath: path)
        let filePath = url.appendingPathComponent(img)?.path
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: filePath!) {
//            print("FILE AVAILABLE")
        } else {
            save(fileName: img)
        }
        
    }
    
    private func save(fileName: String)
    {
        // Create destination URL
        let documentsUrl:URL =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first as URL!
        let destinationFileUrl = documentsUrl.appendingPathComponent(fileName)
        
        //Create URL to the source file you want to download
        let fileURL = URL(string: "http://192.168.1.13/Projects/EGyaan_OpenSource/modules/manage_student/images/student/\(fileName)")
        
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig)
        
        let request = URLRequest(url:fileURL!)
        
        let task = session.downloadTask(with: request) { (tempLocalUrl, response, error) in
            if let tempLocalUrl = tempLocalUrl, error == nil {
                // Success
                if let statusCode = (response as? HTTPURLResponse)?.statusCode {
                    print("Successfully downloaded. Status code: \(statusCode)")
                }
                
                do {
                    try FileManager.default.copyItem(at: tempLocalUrl, to: destinationFileUrl)
                } catch (let writeError) {
                    print("Error creating a file \(destinationFileUrl) : \(writeError)")
                }
                
            } else {
                print("Error took place while downloading a file. Error description: %@", error?.localizedDescription as Any);
            }
        }
        task.resume()
    }
    
}

