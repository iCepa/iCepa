//
//  GetCircuitsMessage.swift
//  iCepa
//
//  Created by Benjamin Erhart on 20.05.20.
//  Copyright © 2020 Guardian Project. All rights reserved.
//

import Foundation

class GetCircuitsMessage: NSObject, Message {

	static var supportsSecureCoding = true

	override init() {
		super.init()
	}

	required init?(coder: NSCoder) {
		super.init()
	}

	func encode(with coder: NSCoder) {
	}
}
