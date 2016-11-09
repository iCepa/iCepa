//
//  PermissionViewController.swift
//  iCepa
//
//  Created by Conrad Kramer on 8/26/16.
//  Copyright © 2016 Conrad Kramer. All rights reserved.
//

import UIKit

class PermissionViewController: UIViewController {
    override func loadView() {
        super.loadView()
        
        view.backgroundColor = .white
        
        let askButton = FloatingButton()
        askButton.translatesAutoresizingMaskIntoConstraints = false
        askButton.setTitle("Help Me", for: .normal)
        askButton.gradient = (UIColor(rgbaValue: 0x00CD86FF), UIColor(rgbaValue: 0x3AB52AFF))
        
        view.addSubview(askButton)
        
        NSLayoutConstraint.activate([
            askButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            askButton.centerYAnchor.constraint(equalTo: view.centerYAnchor)
            ])
    }
}
