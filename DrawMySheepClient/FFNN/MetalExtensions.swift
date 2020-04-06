//
//  MetalExtension.swift
//  ImageDatasGetter
//
//  Created by alban perli on 06.03.17.
//  Copyright © 2017 alban perli. All rights reserved.
//

import Foundation
import Metal


extension Float {
    
    mutating func toMetalBuffer(device:MTLDevice) -> MTLBuffer {
        
        let inVectorBuffer = device.makeBuffer(bytes: &self,
                                               length: MemoryLayout<Float>.size)
        return inVectorBuffer!
    }
    
}
