//
//  requestViewModel.swift
//  ApiTest
//
//  Created by Ad on 2021/3/23.
//
import Foundation
import UIKit

/**
 简单demo项目,故未导入第三方库和网络库封装,直接使用viewModel来实现
 */
/// 请求回调闭包
typealias requestClosures = (_ success: Bool, _ errorMsg: String?) -> Void
/// 数据处理线程
private var dataQueue: DispatchQueue = DispatchQueue(label: "ApiTestRequestViewModel.Data", attributes: .concurrent)
/// 数据解析线程
private var analysisQueue: DispatchQueue = DispatchQueue(label: "ApiTestRequestViewModel.Analysis")
/// 缓存key
private let apiTestDataCacheKey = "apiTest_dataCache_key"
class requestViewModel {
    //=================================================================
    //                              属性列表
    //=================================================================
    // MARK: - 属性列表
    /// 单例
    private static var shared: requestViewModel = requestViewModel()
    /// request
    private lazy var request: URLRequest = {
        var request = URLRequest(url: URL(string: "https://api.github.com")!)
        request.httpMethod = "GET"
        return request
    }()
    /// session
    private lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 5
        return URLSession(configuration: configuration)
    }()
    /// 回调方法
    private var requestClosures: requestClosures?
    /// 定时器
    private var timer: GCDTimer?
    /// 展示状态[安全属性]
    private var showHistory: Bool {
        get {
            dataQueue.sync {
                return _showHistory
            }
        }
        set {
            dataQueue.async(flags: .barrier) {
                self._showHistory = newValue
            }
        }
    }
    /// 展示状态[非安全,请勿直接使用]
    private var _showHistory: Bool = false
    /// 数据源[安全属性]
    private var modelArray: [(tilte: String, content: String)]? {
        get {
            dataQueue.sync {
                return _modelArray
            }
        }
        set {
            dataQueue.async(flags: .barrier) {
                self._modelArray = newValue
            }
        }
    }
    /// 数据源[非安全,请勿直接使用]
    private var _modelArray: [(tilte: String, content: String)]?
    /// 历史数据源[安全属性]
    private var historyArray: [(tilte: String, content: String)] {
        get {
            dataQueue.sync {
                return _historyArray
            }
        }
        set {
            dataQueue.async(flags: .barrier) {
                self._historyArray = newValue
            }
        }
    }
    /// 历史数据源[非安全,请勿直接使用]
    private var _historyArray = [(tilte: String, content: String)]()
    /// dateFormatter创建比较耗时,每次用同一个
    private lazy var timeFormatter: DateFormatter = {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm:ss.SSS"
        timeFormatter.timeZone = TimeZone(secondsFromGMT: 8 * 60 * 60) ?? TimeZone.current
        return timeFormatter
    }()
    //=================================================================
    //                              公开方法
    //=================================================================
    // MARK: 公开方法
    /// 开始刷新数据
    /// - Parameter closures: 回调
    static func start(closures: requestClosures?) {
        shared.requestClosures = closures
        // 读取缓存
        if let dict = readDict() {
            analysisModel(dict: dict, isLocal: true)
        }
        // 开启定时
        shared.timer = GCDTimer(interval: 5, action: {
            netRequest()
        })
    }
    /// 读取模型数据源
    static func readModelArray() -> [(tilte: String, content: String)]? {
        var modelArray: [(tilte: String, content: String)]?
        modelArray = shared.showHistory ? shared.historyArray : shared.modelArray
        return modelArray
    }
    /// 数据源切换
    static func switchShowModel() {
        shared.showHistory.toggle()
    }
    //=================================================================
    //                              私有方法
    //=================================================================
    // MARK: - 私有方法
    /// 网络请求
    private static func netRequest() {
        let task = shared.session.dataTask(with: shared.request) { (data, response, error) in
            // 异常判断
            guard error == nil else {
                DispatchQueue.main.async {
                    shared.requestClosures?(false, error.debugDescription)
                }
                addHistoryModel(title: "失败", content: error.debugDescription)
                return
            }
            guard data != nil else {
                DispatchQueue.main.async {
                    shared.requestClosures?(false, "返回data为空")
                }
                addHistoryModel(title: "失败", content: "返回data为空")
                return
            }
            // 数据解析
            do {
                if let responseData: Dictionary = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.allowFragments) as? [String: Any] {
                    analysisModel(dict: responseData)
                }
            }catch{
                DispatchQueue.main.async {
                    shared.requestClosures?(false, "数据解析失败")
                }
                addHistoryModel(title: "失败", content: "数据解析失败")
            }
        }
        task.resume()
    }
    /// 数据模型解析
    /// - Parameter dict: dict
    private static func analysisModel(dict: [String: Any], isLocal: Bool = false) {
        analysisQueue.async {
            // 指定长度数组
            var array = [(tilte: String, content: String)](repeating: ("", ""), count: dict.keys.count)
            // 赋值
            _ = dict.keys.enumerated().map { (idx,key) in
                array[idx] = (key, dict[key] as? String ?? "")
            }
            // 从网络获取才保存,记录
            if isLocal == false {
                saveCache(dict: dict)
                addHistoryModel(title: "成功", content: "")
            }
            shared.modelArray = array
            // 主线程执行回调
            DispatchQueue.main.async {
                shared.requestClosures?(true, nil)
            }
        }
    }
    /// 添加历史内容
    /// - Parameters:
    ///   - title: 标题
    ///   - content: 内容
    private static func addHistoryModel(title: String, content: String) {
        let finalContent = shared.timeFormatter.string(from: Date()) as String + content
        shared.historyArray.insert((tilte: title, content: finalContent), at: 0)
        // 防止内存占用过大
        if shared.historyArray.count > 1500 {
            shared.historyArray.removeLast(50)
        }
    }
    /// 移除通知
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
//=================================================================
//                           缓存读写
//=================================================================
// MARK: - 缓存读写
extension requestViewModel {
    /// 读取缓存
    /// - Returns: dict
    private static func readDict() -> [String: Any]? {
        return UserDefaults.standard.value(forKey: apiTestDataCacheKey) as? [String: Any]
    }
    /// 保存缓存
    /// - Parameter dict: dict
    private static func saveCache(dict: [String: Any]) {
        UserDefaults.standard.setValue(dict, forKey: apiTestDataCacheKey)
        UserDefaults.standard.synchronize()
    }
}
