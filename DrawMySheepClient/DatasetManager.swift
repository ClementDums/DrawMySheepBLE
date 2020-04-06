//
//  AcceleroDataManager.swift
//  DrawMySheep
//
//  Created by AL on 10/03/2020.
//  Copyright © 2020 AL. All rights reserved.
//

import Foundation

class DatasetManager {
    
    static let instance = DatasetManager()
    
    enum Figure:String,CaseIterable {
        case square,circle,triangle
        
        func res() -> [Float] {
            switch self {
            case .square: return [1.0,0.0,0.0]
            case .circle: return [0.0,1.0,0.0]
            case .triangle: return [0.0,0.0,1.0]
            }
        }
    }
    
    var dico:[Figure:[[Float]]] = [:]
    
    init() {
        clearDico()
    }
    
    func clearDico() {
        for f in Figure.allCases {
            dico[f] = []
        }
        
    }
    
    static func convertoFloat(array:[Double])->[Float]{
        return array.map{Float($0)}
    }
    
    func appendData(figure:Figure,acceleroData:[Double]) {
        dico[figure]?.append(acceleroData.map{ Float($0) })
        print(dico)
    }
    
    func buildDataset() -> (input:[[Float]],expected:[[Float]]) {
    
        var input = [[Float]]()
        var expected = [[Float]]()
        //si forme : tableau de tableu : je les ajoute a mon tableau input
        //res : resultats expected : le reseau de neurone repond avec les double
        //Expected : si carre carre triangle : 1,0,0;1,00,0;0,0,1
        //Feed forward: tableau entrée :-> machine ->reponse
        //Perceptron
        //Tengeante relu
        //Backpropagation: ajuster les poids -> stockastique gradient descente
        for k in dico.keys {
            if let val = dico[k] {
                expected.append(contentsOf: Array(repeating: k.res(), count: val.count))
                input.append(contentsOf: val)
            }
        }
        
        return (input,expected)
    }
}
