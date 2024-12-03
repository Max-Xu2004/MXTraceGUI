//
//  NSNumberEX.swift
//  MXTraceGUI
//
//  Created by Max Xu on 2024/11/6.
//

import Foundation

extension Array where Element == NSObject {
    func average() -> Double {
        // 过滤掉 NSNull 元素，只保留 NSNumber 类型的元素
        let validNumbers = self.compactMap { $0 as? NSNumber }
        
        // 如果有效元素为空，返回 0
        guard !validNumbers.isEmpty else {
            return 0.0
        }
        
        // 计算所有有效 NSNumber 的总和
        let sum = validNumbers.reduce(0.0) { $0 + $1.doubleValue }
        
        // 返回平均值
        return sum / Double(validNumbers.count)
    }
}
