//
//  BLEChunker.swift
//  PeerToPeerBLE
//
//  Created by  on 09/03/2020.
//  Copyright © 2020 AL. All rights reserved.
//

import Foundation
import UIKit
class BLEChunker{
    //add bornage
    //choix bornage intelligent
    var isReceivingMedia = false
    var currentBytesArray: [UInt8]?
    var currentSetup:ChunkSetup? = nil
    static let instance = BLEChunker()
    
    struct ChunkSetup {
        var headerValue:HeaderValue
        var chunkSize:Int
        var nbBytes:Int
        var startBytes:UInt8
        var endBytes:UInt8
        
        static func customSetup(value:HeaderValue)->ChunkSetup{
            return ChunkSetup(headerValue: value,chunkSize: 512, nbBytes: 3, startBytes: value.rawValue, endBytes: value.rawValue)
        }
        
        enum  HeaderValue:UInt8,CaseIterable {
            case headerImage = 255
            case headerString = 222
            
            func getBytesArray()->[UInt8]{
                switch self {
                case .headerImage:
                    return [HeaderValue.headerImage.rawValue,
                            HeaderValue.headerImage.rawValue,
                            HeaderValue.headerImage.rawValue]
                case .headerString:
                    return [HeaderValue.headerString.rawValue,
                            HeaderValue.headerString.rawValue,
                            HeaderValue.headerString.rawValue]
                }
            }
        }
        
        static func imageSetup()->ChunkSetup{
            return ChunkSetup(headerValue :.headerImage,chunkSize: 512, nbBytes: 3, startBytes: HeaderValue.headerImage.rawValue, endBytes: HeaderValue.headerImage.rawValue)
        }
        
        static func stringSetup()->ChunkSetup{
            return ChunkSetup(headerValue: .headerString,chunkSize: 512, nbBytes: 3, startBytes: HeaderValue.headerString.rawValue, endBytes: HeaderValue.headerString.rawValue)
        }
        
        static func buildSetupForBytes(_ headerBytesArray:[UInt8])->ChunkSetup?{
            
            for value in HeaderValue.allCases{
                if headerBytesArray == value.getBytesArray(){
                    return ChunkSetup.customSetup(value: value)
                }
            }
            
            return nil
        }
    }
    
    func removeBoundsOn(bytesArray:inout [UInt8]){
        if let setup = self.currentSetup{
            for i in 0..<setup.nbBytes{
                bytesArray.removeFirst()
                bytesArray.removeLast()
            }
        }
    }
    
    func clearCurrentTransfer(){
        self.currentSetup = nil
        self.currentBytesArray = nil
    }
    
    func checkEndBoundOn(bytesArray:[UInt8])->Bool{
        if let setup = self.currentSetup {
            let sizeArray = bytesArray.count-1
            for i in 0..<setup.nbBytes{
                if bytesArray[sizeArray-i] != setup.endBytes{
                    return false
                }
            }
            return true
        }
        return false
    }
    
    func buildDatableObjectFrom(bytesArray:[UInt8])->Datable?{
        if let setup = currentSetup{
            switch setup.headerValue {
            case .headerImage:
                return UIImage(data: Data(bytesArray))
            case .headerString:
                return String(data: Data(bytesArray), encoding: .utf8)
            default:
                return nil
            }
        }
        return nil
    }
    
    func newDataIncoming(data:Data)->Datable?{
        
        if let setup = currentSetup{
            var byteArray = self.convertToBytesArray(data: data)
            self.currentBytesArray?.append(contentsOf: byteArray)
            
            if checkEndBoundOn(bytesArray: byteArray){
                if var finalBytes = self.currentBytesArray{
                    removeBoundsOn(bytesArray: &finalBytes)
                    return buildDatableObjectFrom(bytesArray: finalBytes)
                }
            }
            
            
        }else{
            //check first bytes -> set current setup
            var bytesArray = self.convertToBytesArray(data: data)
            let header = Array(bytesArray[0..<3])
            if let setup = ChunkSetup.buildSetupForBytes(header){
                self.currentSetup = setup
                self.currentBytesArray = bytesArray
                
                if checkEndBoundOn(bytesArray: bytesArray){
                    if var finalBytes = self.currentBytesArray{
                        removeBoundsOn(bytesArray: &finalBytes)
                        return buildDatableObjectFrom(bytesArray: finalBytes)
                    }
                }
            }
        }
        
        
        return nil
    }
    
    func prepareForSending<T:Datable>(obj:T) -> [[UInt8]]? {
        guard let data = convertToData(obj: obj) else{
            return nil
        }
        
//        print(data.count)
//        print(data.compress(withAlgorithm: .lz4)?.count)
        
        var setup:ChunkSetup
        switch obj {
        case is UIImage: setup = ChunkSetup.imageSetup()
        case is String: setup = ChunkSetup.stringSetup()
        default:
            return nil
        }
        
        var bytesArray = convertToBytesArray(data: data)
        //& = je passe pas la valeur mais la référence : changement global, comme on garde seulement la référence et pas les valeur on gard la taille
        
        let boundedArray = addBorn(bytesArray: &bytesArray, bytesNum: setup.nbBytes, startBytes: setup.startBytes, endBytes: setup.endBytes)
        
        let chunckedArray = chunkByteArray(boundedArray, chunkSize: setup.chunkSize)
        return chunckedArray
    }
    
    
    
    private func chunkByteArray(_ byteArray:[UInt8],chunkSize:Int)->[[UInt8]]{
        return byteArray.chunked(into: chunkSize)
    }
    
    private func addBorn(bytesArray:inout [UInt8],bytesNum:Int,startBytes:UInt8,endBytes:UInt8)->[UInt8]{
        for i in 0..<bytesNum{
            bytesArray.insert(startBytes, at: 0)
            bytesArray.append(endBytes)
        }
        return bytesArray
    }
    
    private func convertToBytesArray(data:Data)->[UInt8]{
        return [UInt8](data)
    }
    
    private func convertToData<T:Datable>(obj:T) ->Data?{
        return obj.convertToData()
    }
}



protocol Datable {
    func convertToData()->Data?
}

extension String:Datable{
    func convertToData() -> Data? {
        return self.data(using: .utf8)
    }
    
}

extension UIImage:Datable{
    func convertToData() -> Data? {
        return self.pngData()
    }
}

