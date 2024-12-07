//
//  ContentView.swift
//  MXTraceGUI
//
//  Created by Max Xu on 2024/11/6.
//

import SwiftUI
import MapKit

enum PickerOptions: String, CaseIterable, Identifiable {
    case TraceRT = "TraceRT"
    case Ping = "Ping"
    
    var id: String { self.rawValue }
}

struct ContentView: View {
    // 输入框内容
    @State private var inputAddress: String = ""
    
    // 列表数据
    @State private var listModels: [ListModel] = []
    @State private var isRunning: Bool = false
    
    @State private var selectedOption: PickerOptions = .TraceRT

    var body: some View {
        VStack {
            HStack {
                TextField("请输入IP地址或域名", text: $inputAddress)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Picker("选择模式", selection: $selectedOption) {
                    ForEach(PickerOptions.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                
                Button(action: startRunning) {
                    Text(isRunning ? "追踪中..." : "开始追踪")
                        .foregroundStyle(.primary)
                }
#if os(iOS)
                .frame(width: 100, height: 30) // 设置按钮宽度和高度
                .background(Color(.systemBackground))
                .cornerRadius(15)
#endif
                .disabled(inputAddress.isEmpty || isRunning)
                .padding()
            }
            
            HStack {
                Text("序号")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                Text("IP地址")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                Text("地理位置")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                Text("延迟")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(.horizontal)
            .padding(.vertical, 5)
            .background(in: .capsule)

            List(listModels) { result in
                HStack {
                    Text("\(result.num)")
                        .frame(maxWidth: .infinity, alignment: .center)
                    Text(result.ip)
                        .frame(maxWidth: .infinity, alignment: .center)
                    Text(result.ipInfo?.location ?? "*")
                        .frame(maxWidth: .infinity, alignment: .center)
                    Text(result.duration)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            
            
        }
        .padding()
    }
    
    private func startRunning() {
        isRunning = true
        listModels.removeAll()
        switch selectedOption {
        case .TraceRT:
            startTraceRoute()
        case .Ping:
            startPing()
        }
    }

    private func startTraceRoute() {
        
        let targetAddress = cleanInputAddressUsingURLComponentsAndTrimSuffix(inputAddress)
        
        Traceroute.start(withHost: targetAddress, queue: DispatchQueue.global()) { record in
            if let record = record {
                let result = ListModel(record: record)
                result.fetchIPInfo { succeed in
                    listModels.append(result)
                }
            }
        } finish: { records, isSucceed in
            if isSucceed {
                print(records ?? "")
            }
            isRunning = false
        }
    }
    
    private func startPing() {
        let targetAddress = cleanInputAddressUsingURLComponentsAndTrimSuffix(inputAddress)
        let pingTask = PingUtility(host: targetAddress) { result in
            if let result = result {
                let models = ListModel.setup(result: result)
                for model in models {
                    model.fetchIPInfo { succeed in
                        listModels.append(model)
                    }
                }
            }
            isRunning = false
        }
        pingTask?.startPing()
    }
    
    func cleanInputAddressUsingURLComponentsAndTrimSuffix(_ address: String) -> String {
        // 尝试将输入转换为 URL
        guard let url = URL(string: address), let host = url.host else {
            // 如果不是完整 URL
            // 检查并去掉 www. 前缀
            if address.hasPrefix("www.") {
                return String(address.dropFirst(4)) // 去掉 "www."
            }
            return address
        }
        return host
    }
    
}

#Preview {
    ContentView()
}
