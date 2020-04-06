//
//  ChatPeripherals.swift
//  DrawMySheepClient
//
//  Created by  on 10/03/2020.
//  Copyright © 2020 clementdumas. All rights reserved.
//

import Foundation
import CoreBluetooth

class ChatPeripherals {
    static let instance = ChatPeripherals()
    
    var isServer = false
    
    var availablePeripherals = [String: CBPeripheral]()
    var readyPeripherals = [CBPeripheral]()
    
    
    func connectToAll(serverName: String, callback: @escaping (Bool) -> ()) {
        if let periph = availablePeripherals[serverName] {
            BLEManager.instance.connectPeripheral(periph) { (connectedPeriph) in
                BLEManager.instance.discoverPeripheral(connectedPeriph) { (readyPeriph) in
                    self.readyPeripherals.append(readyPeriph)
                    callback(true)
                }
            }
        } else {
            callback(false)
        }
    }
}
