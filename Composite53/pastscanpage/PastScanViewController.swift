//
//  PastScanViewController.swift
//  Composite53
//
//  Created by user on 15/02/23.
//

import UIKit



class PastScanViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
   
    
    
    @IBOutlet weak var PastscanTbleView: UITableView!

    @IBOutlet weak var MonthLbl: UILabel!
    var index : Int = 0
    var count : Int = 0
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        PastscanTbleView.delegate = self
        PastscanTbleView.dataSource = self
        self.navigationItem.setHidesBackButton(true, animated: true)
        
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
       
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
            // process files
//            let resources1 = try fileURLs[0].resourceValues(forKeys: [.creationDateKey])
//             let creationDate1 = resources1.creationDate!
//            let dateFormatter1 = DateFormatter()
//            dateFormatter1.dateFormat = "yyyy-MM-dd"
//            let dateString1 = dateFormatter1.string(from: creationDate1)
//            MonthLbl.text = dateString1
            print("file urls", fileURLs)
            if !fileURLs.isEmpty{
                let items = try fileManager.contentsOfDirectory(at: fileURLs[0], includingPropertiesForKeys: nil)
                
                for item in items {
                    if !myscans.contains(item){
                        
                        myscans.append(item)
                    }
                    count += 1
                    let resources = try item.resourceValues(forKeys: [.creationDateKey])
                    let creationDate = resources.creationDate!
                    
                    print("Found \(item)", creationDate)
                    
                    
                    if !myscansname.contains("scans\(self.count)"){
                        myscansname.append("scans\(self.count)")
                    }
                    if !myscansdate.contains(creationDate){
                        myscansdate.append(creationDate)
                    }
                    
                    //                   print("Found \(item)", self.count)
                    
                }
                
                myscans = myscans.sorted { $0.absoluteString > $1.absoluteString }
    
                myscansname = myscansname.sorted()
                
                myscansdate = myscansdate.sorted()
                print("data::", myscans, myscansname, myscansdate)
            }else{
                print("file is not their")
            }
            
        } catch {
            print("Error while enumerating files \(documentsURL.path): \(error.localizedDescription)")
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return myscans.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell =  PastscanTbleView.dequeueReusableCell(withIdentifier: "cell1", for: indexPath) as! PastScansTableViewCell
        cell.imgView.image = UIImage(named: "Rectangle 15")
        cell.ScanName.text = myscansname[indexPath.row]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: myscansdate[indexPath.row])
        cell.DateLbl.text = dateString
        cell.openBtn.tag = indexPath.row
        self.index = indexPath.row
        print("index",  self.index )
//        cell.openBtn.addTarget(self, action: #selector(openScnView), for: .touchUpInside)
        cell.blockForFeedbackClick = { [weak self] indexx  in
            print("indexcount", indexx, indexPath.row)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self?.openScnView(indexPath.row)
            }
            
        }
        

        
        return cell
    }
    
    @IBAction func backBtn(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        showLoader()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.openScnView(indexPath.row)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    func openScnView(_ index: Int){
        
        let vc = ShowPastScanViewController.loadViewController(withStoryBoard: .mainSB)
        vc.url = myscans[index]
        
        self.navigationController?.pushViewController(vc, animated: true)
        hideLoader()
        
    }
    
}
