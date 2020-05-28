//
//  AlertErrorHandler.swift
//  ReaddleContacts
//
//  Created by Andrii Zinoviev on 28.05.2020.
//  Copyright © 2020 Andrii Zinoviev. All rights reserved.
//

import Foundation
import UIKit

class AlertErrorHandler: ErrorHandler {
    func error(_ e: Error) {
        displayError(text: e.localizedDescription)
    }

    private weak var parent: UIViewController?

    init(parent: UIViewController) {
        self.parent = parent
    }

    private func displayError(text: String?) {
        DispatchQueue.main.async {
            let ac = UIAlertController(title: "Error", message: text, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "Fine", style: .cancel, handler: nil))
            self.parent?.present(ac, animated: true, completion: nil)
        }
    }
}
