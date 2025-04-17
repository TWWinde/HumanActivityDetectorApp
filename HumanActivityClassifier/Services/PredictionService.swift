//
//  PredictionService.swift
//  HumanActivityClassifier
//
//  Created by Tang Wenwu on 17.04.25.
//

import CoreML

class PredictionService {
    static let shared = PredictionService()
    private let classifier = HumanActivityClassifier()
    
    private init() {}
    
    func predict(windowData: [[Double]]) -> String? {
        guard let mlArray = try? MLMultiArray(shape: [1, 64, 6], dataType: .double) else { return nil }
        
        for (t, frame) in windowData.enumerated() {
            for (c, value) in frame.enumerated() {
                let index = [0, t, c] as [NSNumber]
                mlArray[index] = NSNumber(value: value)
            }
        }
        
        return classifier.predict(input: mlArray)
    }
}
