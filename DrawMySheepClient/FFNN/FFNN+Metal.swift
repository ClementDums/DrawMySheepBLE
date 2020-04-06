//
//  FFNN+Metal.swift
//  ImageDatasGetter
//
//  Created by alban perli on 24.02.17.
//  Copyright © 2017 alban perli. All rights reserved.
//

import Foundation
import Metal
import MetalKit
import QuartzCore

class FFNNMetal {
    var device: MTLDevice!
    var commandQueue: MTLCommandQueue?
    var metalNNLibrary: MTLLibrary?
    var computeCommandEncoder:MTLComputeCommandEncoder?
    var commandBuffer: MTLCommandBuffer?
    var computePipelineFilterSigmoid:MTLComputePipelineState?
    var computePipelineFilterUpdatedHidden:MTLComputePipelineState?
    
    static let instance = FFNNMetal()
    
    // Shared memory
    var hiddenMemoryPtr:UnsafeMutableRawPointer? = nil
    var tmp = [Float]()
    
    init() {
        setupMetal()
    }
    
    func setupMetal() {
        
        self.device = MTLCreateSystemDefaultDevice()!
        // Queue to handle an ordered list of command buffers
        self.commandQueue = device.makeCommandQueue()
        
        if let defaultLib = device.makeDefaultLibrary(){
            //let sigmoidProgram = defaultLib.makeFunction(name: "sigmoid")
            //computePipelineFilterSigmoid = try! device?.makeComputePipelineState(function:sigmoidProgram!)
            let updatedHiddenWeightProgramm = defaultLib.makeFunction(name: "updateSwiftAIWeights")
            computePipelineFilterUpdatedHidden = try! device.makeComputePipelineState(function:updatedHiddenWeightProgramm!)
        }
        
    }
    
    func generateArrayBuffers(inputArrays:[Float],memoryLayoutSize:Int) -> MTLBuffer {
        
        let myvectorByteLength = inputArrays.count*memoryLayoutSize
        
        let inVectorBuffer = device.makeBuffer(bytes: UnsafeRawPointer(inputArrays), length: myvectorByteLength)
        
        return inVectorBuffer!
    }
    
    func generateIntArrayBuffers(inputArrays:[Int],memoryLayoutSize:Int) -> MTLBuffer {
        
        let myvectorByteLength = inputArrays.count*memoryLayoutSize
        
        let inVectorBuffer = device.makeBuffer(bytes: UnsafeRawPointer(inputArrays), length: myvectorByteLength)
        
        return inVectorBuffer!
    }
    
    func initEmptyArray(hiddenWeightArray:[Float]) {
        
        tmp = Array<Float>(repeatElement(-1.0, count: hiddenWeightArray.count))
    }
    
    func setupSharedHiddenWeightsArray(hiddenWeightArray:[Float]) {
        
        let alignment:Int = 0x4000 // 16K aligned
        let size:Int = Int(hiddenWeightArray.count) * MemoryLayout<Float>.size
        
        posix_memalign(&hiddenMemoryPtr, alignment, size)

        let voidPtr: OpaquePointer = OpaquePointer(hiddenMemoryPtr!)
        let floatMutablePtr: UnsafeMutablePointer<Float>! = UnsafeMutablePointer(voidPtr)
        var floatMutableBufferPtr = UnsafeMutableBufferPointer<Float>(start: floatMutablePtr, count: hiddenWeightArray.count)
        
        for index in floatMutableBufferPtr.startIndex..<floatMutableBufferPtr.endIndex {
            floatMutableBufferPtr[index] = 0.0
        }
        
    }
    
    // https://gist.github.com/kirsteins/6d6e96380db677169831
    // http://memkite.com/blog/2014/12/30/example-of-sharing-memory-between-gpu-and-cpu-with-swift-and-metal-for-ios8/
    // https://github.com/FlexMonkey/MercurialPaint/blob/master/MercurialPaint/components/MercurialPaint.swift
    
    
    func generateFloatBuffer(value:Float) -> MTLBuffer {
        
        var varValue = value
        let inVectorBuffer = device.makeBuffer(bytes: &varValue,
                                                length: MemoryLayout<Float>.size)
        return inVectorBuffer!
    }
    
    
    
    func appendBufferToCommandEncoder(buffers:[MTLBuffer]) {
        
        for i in 0..<buffers.count {
            
            computeCommandEncoder?.setBuffer(buffers[i], offset: 0, index: i)
        }
    }
    
    func updateHiddenWeight(hiddenWeights:[Float],
                            previousHiddenWeights:[Float],
                            hiddenErrorIndices:[Int],
                            inputIndices:[Int],
                            inputCache:[Float],
                            mfLR:Float,
                            momentumFactor:Float,
                            hiddenOutputCache:[Float],
                            hiddenErrorsCache:[Float],
                            newHiddenWeights:inout [Float]){
        
        //BenchmarkTimer.start(label: "updateHiddenWeight")
        
        
        
        //autoreleasepool {
            
            commandBuffer = commandQueue?.makeCommandBuffer()
            self.computeCommandEncoder = commandBuffer?.makeComputeCommandEncoder()
            self.computeCommandEncoder?.setComputePipelineState(computePipelineFilterUpdatedHidden!)
            
            var buffers = [MTLBuffer]()
            
            buffers.append(generateArrayBuffers(inputArrays: hiddenWeights, memoryLayoutSize: MemoryLayout<Float>.size))
            buffers.append(generateArrayBuffers(inputArrays: previousHiddenWeights, memoryLayoutSize: MemoryLayout<Float>.size))
            buffers.append(generateIntArrayBuffers(inputArrays: hiddenErrorIndices, memoryLayoutSize: MemoryLayout<Int>.size))
            buffers.append(generateIntArrayBuffers(inputArrays: inputIndices, memoryLayoutSize: MemoryLayout<Int>.size))
            
            buffers.append(generateArrayBuffers(inputArrays: inputCache, memoryLayoutSize: MemoryLayout<Float>.size))
            buffers.append(generateFloatBuffer(value: mfLR))
            buffers.append(generateFloatBuffer(value: momentumFactor))
            buffers.append(generateArrayBuffers(inputArrays: hiddenOutputCache, memoryLayoutSize: MemoryLayout<Float>.size))
            buffers.append(generateArrayBuffers(inputArrays: hiddenErrorsCache, memoryLayoutSize: MemoryLayout<Float>.size))
            
            
            let newOutputWeightsLength = hiddenWeights.count*MemoryLayout<Float>.size
            var outVectorBuffer = device.makeBuffer(length: newOutputWeightsLength, options: [])
        buffers.append(outVectorBuffer!)
            
            appendBufferToCommandEncoder(buffers: buffers)
            
            buffers = [MTLBuffer]()
            
            let threadsPerGroup = MTLSize(width:1,height:1,depth:1)
            let numThreadgroups = MTLSize(width:hiddenWeights.count, height:1, depth:1)
            
            computeCommandEncoder?.dispatchThreadgroups(numThreadgroups, threadsPerThreadgroup: threadsPerGroup)
            
            computeCommandEncoder?.endEncoding()
            self.commandBuffer?.commit()
            self.commandBuffer?.waitUntilCompleted()
            //commandBuffer = nil
                        
        var data = NSData(bytes: outVectorBuffer?.contents(),
                              length:  hiddenWeights.count*MemoryLayout<Float>.size)
            
            data.getBytes(&newHiddenWeights, length:hiddenWeights.count*MemoryLayout<Float>.size)
            
        //}
        //BenchmarkTimer.stop()
        
        
        
        //return newOutputWeights
    }
    
    
}
