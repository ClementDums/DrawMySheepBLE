//
//  UiViewControllerExtension.swift
//  DrawMySheepClient
//
//  Created by  on 10/03/2020.
//  Copyright © 2020 clementdumas. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {
    func displayAlertWithText(_ str: String) {
        let a = UIAlertController(title: "Message reçu", message: str, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
        self.present(a, animated: true, completion: nil)
    }
}
