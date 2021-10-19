//
//  CloseCircuitsMessage.swift
//  iCepa
//
//  Created by Benjamin Erhart on 20.05.20.
//  Copyright © 2020 Guardian Project. All rights reserved.
//

import Foundation
import Tor

class CloseCircuitsMessage: NSObject, Message {

	static var supportsSecureCoding = true

	let circuits: [TorCircuit]

	init(_ circuits: [TorCircuit]) {
		self.circuits = circuits

		super.init()
	}

	required init?(coder: NSCoder) {
		circuits = coder.decodeObject(of: [NSArray.self, TorCircuit.self],
									  forKey: "circuits") as? [TorCircuit] ?? []

		super.init()
	}

	func encode(with coder: NSCoder) {
		coder.encode(circuits, forKey: "circuits")
	}
}
