//
//  UITextView+Helpers.swift
//  iCepa
//
//  Created by Benjamin Erhart on 22.05.20.
//  Copyright © 2020 Guardian Project. All rights reserved.
//

import UIKit

extension UITextView {

    func scrollToBottom() {
        scrollRangeToVisible(NSRange(location: text.count - 1, length: 1))
    }
}
