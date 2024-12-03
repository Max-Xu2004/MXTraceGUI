//
//  IPInfoData.swift
//  MXTraceGUI
//
//  Created by Max Xu on 2024/11/7.
//

import Foundation

struct IPInfoData: Codable {
    let ExtendedLocation: String
    let OriginQuery: String
    let SchemaVer: String
    let appinfo: String
    let disp_type: Int
    let fetchkey: String
    let location: String
    let origip: String
    let origipquery: String
    let resourceid: String
    let role_id: Int
    let schemaID: String
    let shareImage: Int
    let showLikeShare: Int
    let showlamp: String
    let strategyData: [String: String]  // You can adjust this if you know more about the structure of strategyData
    let titlecont: String
    let tplt: String
}
