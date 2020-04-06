//
//  ViewController.swift
//  DrawMySheepClient
//
//  Created by  on 10/03/2020.
//  Copyright © 2020 clementdumas. All rights reserved.
//

import UIKit
import CoreMotion

class ViewController: UIViewController {
    
    @IBOutlet weak var detectingLabel: UILabel!
    @IBOutlet weak var isTrainingLabel: UILabel!
    @IBOutlet weak var textViewMoves: UITextView!
    @IBOutlet weak var isConnectedLabel: UILabel!
    let serverName = "clemin"
    var records = [Double]()
    var x = [Double]()
    var y = [Double]()
    var z = [Double]()
    let limitRecord = 50
    let counter = 0
    var myShapeString = ""
    var isDetecting = false
    let nn = FFNN(inputs: 150, hidden: 32, outputs: 3)
    
    @IBOutlet weak var counterDelayLabel: UILabel!
    var isRecording = false
    
    @IBOutlet weak var isRecordingLabel: UILabel!
    let motionManager = CMMotionManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        motionManager.accelerometerUpdateInterval = 1.0/20.0

        
        BLEManager.instance.listenForMessages { (data) in
            if let datable = BLEChunker.instance.newDataIncoming(data: data!){
                
                BLEChunker.instance.clearCurrentTransfer()
                switch datable {
                    
                case is String:
                    let string = datable as! String
                    self.myShapeString = string
                    self.displayReceiverMsg(msgContent: string)
                    
                default:
                    print("incorrect")
                }
            }
            
        }
        
    }
    
    @IBAction func onDetectButtonClicked(_ sender: Any) {
        isDetecting = true
        detectingLabel.text = "Detecting"
    }
    @IBAction func onTrainButtonClicked(_ sender: Any) {
        isTrainingLabel.text = "Training"
        let dataset = DatasetManager.instance.buildDataset()
        //On train
        try! nn.train(inputs: dataset.input, answers: dataset.expected, testInputs: dataset.input, testAnswers: dataset.expected, errorThreshold: 0.1)
        isTrainingLabel.text = ""
    }
    
    @IBAction func onConnectButtonClicked(_ sender: Any) {
        BLEManager.instance.stopScan()
        BLEManager.instance.scan { (periph, name) in
            ChatPeripherals.instance.availablePeripherals[name] = periph
        }
        
        delay(3.0) {
            BLEManager.instance.stopScan()
            ChatPeripherals.instance.connectToAll(serverName: self.serverName) { sucess in
                print("All connected")
                if sucess {
                    //                    self.performSegue(withIdentifier: "toChat", sender: self)
                    self.isConnectedLabel.text = "Status : CONNECTED !!"
                    self.startAccelero()
                } else {
                    self.displayAlertWithText("Unable to find \(self.serverName)")
                }
                
            }
        }
        
    }
    
    
    func displayReceiverMsg(msgContent:String) {
        textViewMoves.text = "Make a \(msgContent)"
    }
    
    func stopAccelero(){
        isRecording = false
        self.isRecordingLabel.text = ""
        if(!isDetecting){
            stockValues()
        }else{
            let recordToFloat = DatasetManager.convertoFloat(array: records)
            let response = try! nn.update(inputs: recordToFloat)
            
            print(response)
        }
        self.records.removeAll()
        self.x.removeAll()
        self.y.removeAll()
        self.z.removeAll()
        self.counterDelayLabel.text = "Ready?"
        print("stopped")
    }
    
    func returnDetectedShape(){
        
    }
    
    func stockValues(){
        var myShape:DatasetManager.Figure? = nil
        switch self.myShapeString {
        case "square":
            myShape = .square
        case "triangle":
            myShape = .triangle
        case "circle":
            myShape = .circle
        default:
            print("BAD STRING")
        }
        
        if let shape = myShape{
            DatasetManager.instance.appendData(figure: shape, acceleroData: Array(records[0..<150]))
        }
        
        sendDataToServer()
    }
    
    func sendDataToServer(){
        if let chunkedBytes = BLEChunker.instance.prepareForSending(obj: self.myShapeString){
            for chunk in chunkedBytes{
                BLEManager.instance.sendData(data: Data(chunk)) { (str) in
                    
                }
            }
        }
        
    }
    
    @IBAction func startRecordingOnClick(_ sender: Any) {
            delay(1) {
                self.counterDelayLabel.text = String(3)
                delay(1) {
                    self.counterDelayLabel.text = String(2)
                    delay(1) {
                        self.counterDelayLabel.text = String(1)
                        delay(1) {
                            self.counterDelayLabel.text = "GOOOOO"
                            self.isRecordingLabel.text = "RECORDING"
                            self.isRecording = true
                        }

                    }
                }
                
            }
    }
    
    func startAccelero(){
        motionManager.startAccelerometerUpdates(to: OperationQueue.main){(data,err) in
            if let e = err{
                print("Error")
            }else{
                if let accel = data?.acceleration{
                    if self.x.count == self.limitRecord && self.y.count == self.limitRecord && self.z.count == self.limitRecord{
                        self.stopAccelero()
                        
                    }else if self.isRecording{
                        
                        self.x.append(accel.x)
                        self.y.append(accel.y)
                        self.z.append(accel.z)
                        self.records.append(accel.x)
                        self.records.append(accel.y)
                        self.records.append(accel.z)
                        
                    }
                }
            }
        }
    }
}

