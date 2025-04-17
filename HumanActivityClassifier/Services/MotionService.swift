//
//  MotionService.swift
//  HumanActivityClassifier
//
//  Created by Tang Wenwu on 17.04.25.
//

import CoreMotion

class MotionService: ObservableObject {
    private let motionManager = CMMotionManager()
    private let queue = OperationQueue()
    
    @Published var sensorData: [Double] = Array(repeating: 0, count: 6) // [ax, ay, az, gx, gy, gz]
    
    var isRunning: Bool { motionManager.isDeviceMotionActive }
    
    func start() {
        guard motionManager.isDeviceMotionAvailable else { return }
        
        motionManager.deviceMotionUpdateInterval = 0.02 // 50Hz采样
        motionManager.startDeviceMotionUpdates(to: queue) { [weak self] data, _ in
            guard let data = data else { return }
            
            let accel = [data.userAcceleration.x, data.userAcceleration.y, data.userAcceleration.z]
            let gyro = [data.rotationRate.x, data.rotationRate.y, data.rotationRate.z]
            
            DispatchQueue.main.async {
                self?.sensorData = accel + gyro
            }
        }
    }
    
    func stop() {
        motionManager.stopDeviceMotionUpdates()
    }
}
