//
//  ViewController.swift
//  Example
//
//  Created by ldc on 2021/12/21.
//

import UIKit
import HTTPRequest
import Alamofire
import SwiftyJSON

public extension HTTPRequest {
    
    static let signature = HTTPRequest.init()
}

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        HTTPRequest.logEnabled = true
        let params = ["id": 17]
        HTTPRequest.default.request("http://47.106.80.210/api/section/add_section_log", method: .post, parameters: params, completeClosure: {
            switch $0 {
            case .success(let json):
                print(json)
            case .failure(let error):
                print(error)
            }
        })
    }


}

