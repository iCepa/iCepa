//
//  ProgressMessage.swift
//  iCepa
//
//  Created by Benjamin Erhart on 20.05.20.
//  Copyright © 2020 Guardian Project. All rights reserved.
//

import Foundation

class ProgressMessage: NSObject, Message {

	static var supportsSecureCoding = true

	let progress: Float

	init(_ progress: Float) {
		self.progress = progress

		super.init()
	}

	required init?(coder: NSCoder) {
		progress = coder.decodeFloat(forKey: "progress")

		super.init()
	}

	func encode(with coder: NSCoder) {
		coder.encode(progress, forKey: "progress")
	}
}
