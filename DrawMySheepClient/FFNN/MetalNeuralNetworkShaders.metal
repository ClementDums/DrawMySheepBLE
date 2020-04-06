//
//  MetalNeuralNetworkShaders.metal
//  AIToolbox
//
//  Created by Kevin Coble on 1/7/16.
//  Copyright © 2016 Kevin Coble. All rights reserved.
//

//  This is duplicated as a string in the .swift version of the file
//  This file is left as a way to test the compile of the shaders at build time

#include <metal_stdlib>
using namespace metal;

kernel void updateSwiftAIWeights(const device float *hiddenWeights [[ buffer(0) ]],
                                 const device float *previousHiddenWeights [[ buffer(1) ]],
                                 const device float *hiddenErrorIndices [[ buffer(2) ]],
                                 const device int *inputIndices [[ buffer(3) ]],
                                 const device int *inputCache [[ buffer(4) ]],
                                 const device float &mfLR [[ buffer(5) ]],
                                 const device float &momentumFactor [[ buffer(6) ]],
                                 const device float *hiddenOutputCache [[ buffer(7) ]],
                                 const device float *hiddenErrorsCache [[ buffer(8) ]],
                                 device float *newOutputWeights [[ buffer(9) ]],
                                 uint id [[ thread_position_in_grid ]])
{
    float offset = hiddenWeights[id] + (momentumFactor * (hiddenWeights[id] - previousHiddenWeights[id]));
    int errorIndex = hiddenErrorIndices[id];
    int inputIndex = inputIndices[id];
    // Note: +1 on errorIndex to offset for bias 'error', which is ignored
    float mfLRErrIn = mfLR * hiddenErrorsCache[errorIndex + 1] * inputCache[inputIndex];
    newOutputWeights[id] = offset + mfLRErrIn;
}

kernel void sigmoid(const device float *inVector [[ buffer(0) ]],
                    device float *outVector [[ buffer(1) ]],
                    uint id [[ thread_position_in_grid ]]) {
    // This calculates sigmoid for _one_ position (=id) in a vector per call on the GPU
    outVector[id] = 1.0 / (1.0 + exp(-inVector[id]));
}


