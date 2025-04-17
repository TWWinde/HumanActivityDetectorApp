//
//  ActivityClassifier.swift
//  HumanActivityClassifier
//
//  Created by Tang Wenwu on 17.04.25.
//

import CoreML

final class HumanActivityClassifier {
    private let model: HumanActivityClassifierModel
    
    init() {
        guard let model = try? HumanActivityClassifierModel(configuration: MLModelConfiguration()) else {
            fatalError("❌ 模型加载失败")
        }
        self.model = model
    }
    
    func predict(input: MLMultiArray) -> String? {
        guard let result = try? model.prediction(input: HumanActivityClassifierModelInput(input: input)) else {
            return nil
        }
        return result.classLabel
    }
}
