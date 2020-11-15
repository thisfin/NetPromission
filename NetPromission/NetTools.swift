//
//  NetTools.swift
//  NetPromission
//
//  Created by 李毅 on 2020/11/12.
//

import CoreTelephony
import Foundation

enum NetworkType {
    case Unknown
    case Offline
    case WiFi
    case CellularData
}

public class NetPermission: NSObject {
    public static func check(result: @escaping ([String: Any]) -> Void) {
        var checkDic = [String: Any]()

        // 模拟器
        if isSimulator() {
            checkDic["des"] = "模拟器"
            checkDic["isReach"] = true
            result(checkDic)
            return
        }

        if YYReachability().isReachable {
            checkDic["des"] = "当前网络已授权"
            checkDic["isReach"] = true
            result(checkDic)
            return
        }

        let cellularData = CTCellularData()
        cellularData.cellularDataRestrictionDidUpdateNotifier = { state in
            switch state {
            // 位置
            case .restrictedStateUnknown:
                checkDic["des"] = "未知，请检查飞行模式、网络是否可用"
                checkDic["isReach"] = false
            case .restricted:
                checkDic["des"] = "网络权限未授权"
                checkDic["isReach"] = false
            case .notRestricted:
                checkDic["des"] = "网络权限未授权"
                checkDic["isReach"] = false
            @unknown default:
                checkDic["des"] = "未知，请检查飞行模式、网络是否可用"
                checkDic["isReach"] = false
            }
            result(checkDic)
        }
    } // CNCopySupportedInterfaces
//    let monitor = NWPathMonitor(requiredInterfaceType: .wifi)
//            let queue = DispatchQueue.global(qos: .background)
//            monitor.start(queue: queue)
//            monitor.pathUpdateHandler = { path in
//                if path.status == .satisfied {
//                    print("Connected")
//                }
//            }

    public static func getLocalDNS(domainName: String) -> [String: Any] {
        var checkDic = [String: Any]()
        var result: String?

        let host = CFHostCreateWithName(nil, domainName as CFString).takeRetainedValue()
        CFHostStartInfoResolution(host, .addresses, nil)
        var success: DarwinBoolean = false
        if let addresses = CFHostGetAddressing(host, &success)?.takeUnretainedValue() as NSArray?,
           let theAddress = addresses.firstObject as? NSData
        {
            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            if getnameinfo(theAddress.bytes.assumingMemoryBound(to: sockaddr.self), socklen_t(theAddress.length),
                           &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST) == 0
            {
                let numAddress = String(cString: hostname)
                result = numAddress
            }
        }
        if result != nil {
            checkDic["des"] = result
            checkDic["result"] = true
        } else {
            checkDic["des"] = "解析失败"
            checkDic["result"] = false
        }

        return checkDic
    }

    public static func getIpByHttpDNS(domainName: String) -> [String: Any] {
        var checkDic = [String: Any]()

        if !HipacConfigure.shared.commonConfigureModel.enableHttpDNS {
            checkDic["result"] = true
            checkDic["des"] = "httpDNS 未启用"
        } else {
            let ipStr = YTHttpDNSManager.shareInstance()?.getIpWithHost(domainName)
            if ipStr != nil {
                checkDic["result"] = true
                checkDic["des"] = ipStr
            } else {
                checkDic["result"] = false
                checkDic["des"] = "解析失败"
            }
        }

        return checkDic
    }

    private static func isSimulator() -> Bool {
        #if targetEnvironment(simulator)
            return true
        #else
            return false
        #endif
    }
}
