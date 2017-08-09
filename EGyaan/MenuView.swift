//
//  Menu.swift
//  EGyaan
//
//  Created by Badal Kotak on 27/06/17.
//  Copyright © 2017 EGyaan. All rights reserved.
//

import UIKit

class MenuView: UIViewController {

    @IBOutlet var email: UILabel!
    @IBOutlet var profilePhoto: UIImageView!
    @IBOutlet var nameLabel: UILabel!
    var databasePath = String()
    var img = String()
    var fname = String()
    var lname = String()
    var email_id = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let filemgr = FileManager.default
        let dirPaths = filemgr.urls(for: .documentDirectory,
                                    in: .userDomainMask)
        
        databasePath = dirPaths[0].appendingPathComponent("egyaan.db").path
        var egyaanDB = FMDatabase(path: databasePath as String)
        
        if (egyaanDB.open())
        {
            let get="SELECT student_profile_photo, firstname , lastname, email FROM egn_student"
            
            let arr=NSArray()
            let results = egyaanDB.executeQuery(get, withArgumentsIn: arr as! [Any])
            
            while results?.next() == true
            {
                img = results!.string(forColumn: "student_profile_photo")!
                fname = results!.string(forColumn: "firstname")!
                lname = results!.string(forColumn: "lastname")!
                email_id = results!.string(forColumn: "email")!
            }
            egyaanDB.close()
        }
        nameLabel.text = "\(fname) \(lname)"
        email.text = email_id
        profilePhoto.image = load(fileName: img)
    }
    
    private func load(fileName: String) -> UIImage? {
        let documentsUrl:URL =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first as URL!
        let fileURL = documentsUrl.appendingPathComponent(fileName)
        do {
            let imageData = try Data(contentsOf: fileURL)
            return UIImage(data: imageData)
        } catch {
            print("Error loading image : \(error)")
        }
        return nil
    }
    

    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
