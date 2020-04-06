//
//  Benchmark.swift
//  ImageDatasGetter
//
//  Created by alban perli on 24.02.17.
//  Copyright © 2017 alban perli. All rights reserved.
//

import Foundation

class BenchmarkTimer {
    
    static var startTime:CFAbsoluteTime?
    static var endTime:CFAbsoluteTime?
    static var label:String?
    
    class func start(label:String){
        startTime = CFAbsoluteTimeGetCurrent()
        BenchmarkTimer.label = label
    }
    
    
    class func stop() {
        BenchmarkTimer.endTime = CFAbsoluteTimeGetCurrent()
        
        print("\(BenchmarkTimer.label) : \(BenchmarkTimer.duration!)")
    }
    
    class var duration:CFAbsoluteTime? {
        if BenchmarkTimer.endTime != nil {
            return BenchmarkTimer.endTime! - BenchmarkTimer.startTime!
        } else {
            return nil
        }
    }
}
