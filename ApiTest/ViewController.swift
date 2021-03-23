//
//  ViewController.swift
//  ApiTest
//
//  Created by Ad on 2021/3/23.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        requestViewModel.start { (_ dataArray) in
            print(dataArray)
        } fail: { (errorMsg) in
            print(errorMsg)
        }
    }


}

