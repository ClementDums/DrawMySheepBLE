//
//  AcceleroShapesManager.swift
//  DrawMySheepClient
//
//  Created by  on 10/03/2020.
//  Copyright © 2020 clementdumas. All rights reserved.
//

import Foundation
class AcceleroShapesManager{
    static let instance = AcceleroShapesManager()
    
    enum Shape:CaseIterable {
        case Square
        case Triangle
        case Circle

    }
    var dico:[Shape:[[Double]]] = [:]
    
    init() {
        clearDico()
    }
    func clearDico(){
        for f in Shape.allCases{
            dico[f] = []
        }
    }
    
    func addAcceleroValues(shape:Shape, values: [Double]){
        dico[shape]?.append(values)
        print(dico)
    }
    
    
    func checkStoredShape(){
        
    }
}
