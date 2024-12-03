//
//  TraceRouteResultModel.swift
//  MXTraceGUI
//
//  Created by Max Xu on 2024/11/6.
//

class ListModel: Identifiable {
    
    let id = UUID()
    
    // 序号
    let num: Int
    
    // ip 地址
    let ip: String
    
    // 延迟
    let duration: String
    
    var ipInfo: IPInfoData? = nil
    
    init(num: Int, ip: String, duration: String) {
        self.num = num
        self.ip = ip
        self.duration = duration
    }
    
    init(record: TracerouteRecord) {
        let duration = (record.recvDurations?.average() ?? 0) * 1000
        self.num = record.ttl
        self.ip = record.ip ?? "*"
        self.duration = duration != 0.0 ? String(format: "%.2fms", duration) : "*"
    }
    
    static func setup(result: PingResult) -> [ListModel] {
        var list = [ListModel]()
        for (index, record) in result.recvDurations.enumerated() {
            let duration = record.floatValue * 1000
            let durationString = duration != 0.0 ? String(format: "%.2fms", duration) : "*"
            let model = ListModel(num: index + 1, ip: result.ipAddress, duration: String(describing: durationString))
            list.append(model)
        }
        return list
    }
        
    func fetchIPInfo(completion: @escaping (_ succeed:Bool)-> ()) {
        if ip != "*" {
            let urlString = "https://opendata.baidu.com/api.php"
            let parameters = [
                "query": ip,
                "co": "",
                "resource_id": "6006",
                "oe": "utf8"
            ]
            
            NetworkManager.shared.get(urlString: urlString, parameters: parameters) { (result: Result<IPInfoModel, NetworkError>) in
                switch result {
                case .success(let ipData):
                    self.ipInfo = ipData.data.first
                    completion(true)
                case .failure(let error):
                    print("Error:", error)
                    completion(false)
                }
            }
        } else {
            completion(false)
        }
    }
}
