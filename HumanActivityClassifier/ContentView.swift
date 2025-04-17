//
//  ContentView.swift
//  HumanActivityClassifier
//
//  Created by Tang Wenwu on 17.04.25.
//

import SwiftUI

class PlotData: ObservableObject {
    @Published var accX: [Double] = []
    @Published var accY: [Double] = []
    @Published var accZ: [Double] = []

    let maxCount = 100

    func append(acceleration: [Double]) {
        if accX.count >= maxCount {
            accX.removeFirst()
            accY.removeFirst()
            accZ.removeFirst()
        }
        accX.append(acceleration[0])
        accY.append(acceleration[1])
        accZ.append(acceleration[2])
    }
}

struct LineGraphView: View {
    var data: [Double]
    var color: Color

    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                guard data.count > 1 else { return }
                let stepX = size.width / CGFloat(data.count - 1)
                let minY = data.min() ?? 0
                let maxY = data.max() ?? 1
                let scaleY = maxY - minY == 0 ? 1 : maxY - minY

                var path = Path()
                for i in data.indices {
                    let x = CGFloat(i) * stepX
                    let y = size.height - CGFloat((data[i] - minY) / scaleY) * size.height
                    if i == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                context.stroke(path, with: .color(color), lineWidth: 2)
            }
        }
        .frame(height: 100)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}


struct ContentView: View {
    @StateObject private var motionService = MotionService()
    @State private var prediction: String = "Click To Start"
    @State private var dataWindow: [[Double]] = []
    @StateObject private var plotData = PlotData()
    
    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)]),
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // 预测结果卡片
                VStack(spacing: 10) {
                    Text("PREDICTION")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Text(prediction)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(15)
                        .shadow(color: .gray.opacity(0.4), radius: 8, x: 0, y: 4)
                        .animation(.easeInOut, value: prediction)
                }
                .padding(.horizontal)

                Divider().background(Color.white.opacity(0.4))

                // 传感器数据卡片
                HStack(spacing: 20) {
                    sensorCard(title: "ACCELERAION", values: Array(motionService.sensorData.prefix(3)))
                    sensorCard(title: "GYROSCOPE", values: Array(motionService.sensorData.suffix(3)))
                }
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("ACCELERAION PLOT")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.leading)

                    LineGraphView(data: plotData.accX, color: .red)
                    LineGraphView(data: plotData.accY, color: .green)
                    LineGraphView(data: plotData.accZ, color: .blue)
                }
                .padding(.horizontal)

                // 控制按钮
                Button(action: toggleDetection) {
                    HStack {
                        Image(systemName: motionService.isRunning ? "stop.circle.fill" : "play.circle.fill")
                            .font(.title2)
                        Text(motionService.isRunning ? "Stop Preditcion" : "Start Prediction")
                            .fontWeight(.semibold)
                    }
                    .frame(width: 220, height: 55)
                    .background(motionService.isRunning ? Color.red : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(radius: 4)
                }

                Spacer()
            }
            .padding(.top, 60)
        }
        .onChange(of: motionService.sensorData) { newData in
            processSensorData()
            plotData.append(acceleration: Array(newData.prefix(3))) // 只绘制加速度
        }
    }
    
    private func toggleDetection() {
        if motionService.isRunning {
            motionService.stop()
            prediction = "Prediction Stopped"
        } else {
            motionService.start()
            dataWindow.removeAll()
            prediction = "Predicting..."
        }
    }
    
    private func processSensorData() {
        dataWindow.append(motionService.sensorData)
        
        // 当收集到64个样本（约1.28秒数据）时预测
        if dataWindow.count >= 64 {
            if let result = PredictionService.shared.predict(windowData: Array(dataWindow.suffix(64))) {
                prediction = result
            }
            dataWindow.removeFirst(32) // 滑动窗口50%重叠
        }
    }
    
    // MARK: - 卡片组件
    private func sensorCard(title: String, values: [Double]) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            
            ForEach(["X", "Y", "Z"].indices, id: \.self) { index in
                Text("\(["X", "Y", "Z"][index]): \(values[index], specifier: "%.2f")")
                    .font(.system(size: 16, design: .rounded))
                    .foregroundColor(.white)
            }
        }
        .padding()
        .frame(width: 140)
        .background(Color.black.opacity(0.3))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 4)
    }
}
