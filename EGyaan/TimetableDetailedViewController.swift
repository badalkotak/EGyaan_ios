//
//  TimetableDetailedViewController.swift
//  EGyaan
//
//  Created by Badal Kotak on 29/12/16.
//  Copyright © 2016 EGyaan. All rights reserved.
//

import UIKit

class TimetableDetailedViewController: UIViewController,UITableViewDataSource, UITableViewDelegate {
    
    var databasePath = String()
    
    @IBOutlet var daySegment: UISegmentedControl!
    @IBOutlet var NavBar: UINavigationItem!
    
    
    @IBOutlet var tableView: UITableView!
    
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
    var valueOfRow = -1
    var day_id = 1
    var batch_id = 0
    var time: [String]=[]
    var course: [String]=[]
    var teacher: [String]=[]
    var comment: [String]=[]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        activityIndicator.startAnimating()
        
        let filemgr = FileManager.default
        let dirPaths = filemgr.urls(for: .documentDirectory,
                                    in: .userDomainMask)
        
        databasePath = dirPaths[0].appendingPathComponent("egyaan.db").path
        var egyaanDB = FMDatabase(path: databasePath as String)
        
        // Do any additional setup after loading the view.
        
        NotificationCenter.default.addObserver(self, selector: #selector(TimetableDetailedViewController.networkStatusChanged(_:)), name: NSNotification.Name(rawValue: ReachabilityStatusChangedNotification), object: nil)
        Reach().monitorReachabilityChanges()
        
        let status = Reach().connectionStatus()
        switch status
        {
        case .unknown, .offline:
            print("Not connected")
            self.getLect(day: day_id)
            break
            
        case .online(.wiFi), .online(.wwan):
            
            if (egyaanDB.open())
            {
                let sql_stmt = "CREATE TABLE egn_timetable (day_id int(2), time varchar(100), course varchar(200), teacher varchar(200), comment varchar(200))"
                
                if !(egyaanDB.executeStatements(sql_stmt)) {
                    print("Error here 1: \(egyaanDB.lastErrorMessage())")
                }
                else{
                    print("Table created egn_timetable")
                }
                
                let getBatch="SELECT batch_id FROM egn_student"
                
                let arr=NSArray()
                let results = egyaanDB.executeQuery(getBatch, withArgumentsIn: arr as! [Any])
                
                if results?.next() == true
                {
                    batch_id=Int(results!.int(forColumn: "batch_id"))
                }
                egyaanDB.close()
            }

            self.validate("http://192.168.1.13/Projects/EGyaan_OpenSource/modules/mobile/functions/timetable.php?batch_id="+String(batch_id)+"&day_id=1")
        } //End switch
        
        
        tableView.delegate = self
        tableView.dataSource = self
        
    }
    
    func getLect(day: Int)
    {
        let filemgr = FileManager.default
        let dirPaths = filemgr.urls(for: .documentDirectory,
                                    in: .userDomainMask)
        
        databasePath = dirPaths[0].appendingPathComponent("egyaan.db").path
        var egyaanDB = FMDatabase(path: databasePath as String)
        
        if (egyaanDB.open())
        {
            let get="SELECT * FROM egn_timetable WHERE day_id='\(day_id)' ORDER BY(time)"
            
            let arr=NSArray()
            let results = egyaanDB.executeQuery(get, withArgumentsIn: arr as! [Any])
            
            while results?.next() == true
            {
                let time_db=results!.string(forColumn: "time")
                time.append(time_db!)
                
                let course_db=results!.string(forColumn: "course")
                course.append(course_db!)
                
                let teacher_db=results!.string(forColumn: "teacher")
                teacher.append(teacher_db!)
                
                let comment_db=results!.string(forColumn: "comment")
                comment.append(comment_db!)
                
            }
            egyaanDB.close()
            DispatchQueue.main.async{
                self.tableView.reloadData()
                self.activityIndicator.stopAnimating()
            }
        }

    }
    
    func validate(_ url: String)
    {
        let url:URL = URL(string: url)!
        let session = URLSession.shared
        var flag = 0
        
        let request = NSMutableURLRequest(url: url)
        request.httpMethod = "POST"
        request.cachePolicy = NSURLRequest.CachePolicy.reloadIgnoringLocalAndRemoteCacheData
        
        let task = session.dataTask(with: request as URLRequest, completionHandler: {(data, response, error) in
            guard let _:Data = data, let _:URLResponse = response  , error == nil else {
                
//                let alert = UIAlertController(title: "Error", message: "Something when wrong!", preferredStyle: UIAlertControllerStyle.alert)
//                
//                // add an action (button)
//                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
//                
//                self.activityIndicator.stopAnimating();
//                // show the alert
//                self.present(alert, animated: true, completion: nil)
                flag = 1
                self.getLect(day: self.day_id)
                return
            }
            
            if(flag==0)
            {
                self.extractJson(data!)   
            }
        })
        
        task.resume();
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func extractJson(_ data: Data)
    {
        
        print("In extracts json")
//        var course: [String]=[]
//        var teacher: [String]=[]
//        var comment: [String]=[]
        
//        if data==nil
//        {
//            print("Empty Data")
//        }
        
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
            for i in 0 ..< outcome_list.count
            {
                if let outcome_obj = outcome_list[i] as? NSDictionary
                {
                    if let result = outcome_obj["status"] as? String
                    {
                        DispatchQueue.main.async(execute: {self.activityIndicator.stopAnimating()})
                        if(result=="success")
                        {
                            if let timetable_list = outcome_obj["timetable"] as? NSArray
                            {
                                let egyaanDB = FMDatabase(path: databasePath as String)
                                egyaanDB.open()
                                let deleteSQL = "DELETE FROM egn_timetable WHERE day_id='\(day_id)'"
                                 if egyaanDB.executeStatements(deleteSQL)
                                 {
                                    print("Deleted!!!!")
                                }
                                for j in 0 ..< timetable_list.count
                                {
                                    if let timetable_obj = timetable_list[j] as? NSDictionary
                                    {
                                        let time_json=timetable_obj["time"]
//
                                        let course_json=timetable_obj["course"]
//                                        course.append(course_json as! String)
                                        let teacher_json=timetable_obj["teacher"]
//                                        teacher.append(teacher_json as! String)
                                        let comment_json=timetable_obj["comment"]
//                                        comment.append(comment_json as! String)
                                        
                                        //For insertion
                                        let insertSQL = "INSERT INTO `egn_timetable`(`day_id`, `time`, `course`, `teacher`, `comment`) VALUES ('\(day_id)','\(time_json as! String)','\(course_json as! String)','\(teacher_json as! String)','\(comment_json as! String)')"
                                        
                                            if !egyaanDB.executeStatements(insertSQL) {
                                                print("Error: \(egyaanDB.lastErrorMessage())")
                                            }
                                    }

                                    }
                                }
                            getLect(day: day_id)
                            print("BACK IN Extract json")
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
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return time.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! TimetableDetailedCellViewController
        
        cell.cellView.layer.masksToBounds = false
        cell.cellView.layer.shadowColor=UIColor.black.cgColor
        cell.cellView.layer.shadowOpacity=0.5
        cell.cellView.layer.shadowOffset = CGSize(width: 1, height: 1)
        cell.cellView.layer.shadowRadius = 6

        cell.timeLabel!.text = "Time: \(time[indexPath.row])"
        cell.courseLabel!.text = course[indexPath.row]
        cell.teacherLabel!.text = "Lecturer: \(teacher[indexPath.row])"
        return cell
    }
    
//    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
//        return 8; // space b/w cells
//    }


    
    func showAlert()
    {
        let alert = UIAlertController(title: "Error", message: "Error in retriving timetable!", preferredStyle: UIAlertControllerStyle.alert)
        
        // add an action (button)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        
        // show the alert
        self.present(alert, animated: true, completion: nil)
    }
//    
//    func getRandomColor() -> UIColor{
//        
//        var randomRed:CGFloat = CGFloat(drand48())
//        var randomGreen:CGFloat = CGFloat(drand48())
//        var randomBlue:CGFloat = CGFloat(drand48())
//        return UIColor(red: randomRed, green: randomGreen, blue: randomBlue, alpha:1.0)
//    }

    @IBAction func selectDay(_ sender: Any) {
        time=[]
        course=[]
        teacher=[]
        comment=[]

        DispatchQueue.main.async{
            self.tableView.reloadData()
            self.activityIndicator.startAnimating()
        }
        
        if(daySegment.selectedSegmentIndex == 0)
        {
            day_id = 1
        }
        else if(daySegment.selectedSegmentIndex == 1)
        {
            day_id = 2
        }
        else if(daySegment.selectedSegmentIndex == 2)
        {
            day_id = 3
        }
        else if(daySegment.selectedSegmentIndex == 3)
        {
            day_id = 4
        }
        else if(daySegment.selectedSegmentIndex == 4)
        {
            day_id = 5
        }
        else if(daySegment.selectedSegmentIndex == 5)
        {
            day_id = 6
        }
        else if(daySegment.selectedSegmentIndex == 6)
        {
            day_id = 7
        }
    
        NotificationCenter.default.addObserver(self, selector: #selector(TimetableDetailedViewController.networkStatusChanged(_:)), name: NSNotification.Name(rawValue: ReachabilityStatusChangedNotification), object: nil)
        Reach().monitorReachabilityChanges()
        
        let status = Reach().connectionStatus()
        switch status
        {
        case .unknown, .offline:
//            print("Not connected")
            self.getLect(day: day_id)
            break
            
        case .online(.wiFi), .online(.wwan):
        self.validate("http://192.168.1.13/Projects/EGyaan_OpenSource/modules/mobile/functions/timetable.php?batch_id="+String(batch_id)+"&day_id="+String(day_id))
        }
        
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
