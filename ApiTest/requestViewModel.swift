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
private var dataQueue: DispatchQueue = DispatchQueue(label: "ApiTestRequestViewModel.data")
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
        configuration.timeoutIntervalForRequest = 4
        return URLSession(configuration: configuration)
    }()
    /// 回调方法
    private var requestClosures: requestClosures?
    /// 定时器
    private var timer: GCDTimer?
    /// 展示历史数据模型
    private var showHistory: Bool = false
    /// 数据源
    private var modelArray: [(tilte: String, content: String)]?
    /// 历史数据源
    private var historyArray = [(tilte: String, content: String)]()
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
    /// - Parameter closures: 回到,errorMsg为nil时为成功
    static func start(closures: requestClosures?) {
        shared.requestClosures = closures
        // 读取缓存
        if let dict = readDict() {
            analysisModel(dict: dict, isLocal: true)
        }
        //防止外部多次调用
        if shared.timer != nil {
            shared.timer?.cancel()
        }
        shared.timer = GCDTimer(interval: 5, action: {
            netRequest()
        })
    }
    /// 读取模型数据源
    static func readModelArray() -> [(tilte: String, content: String)]? {
        return shared.showHistory ? shared.historyArray : shared.modelArray
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
                shared.requestClosures?(false, error.debugDescription)
                addHistoryModel(title: "失败", content: error.debugDescription)
                return
            }
            guard data != nil else {
                shared.requestClosures?(false, "返回data为空")
                addHistoryModel(title: "失败", content: "返回data为空")
                return
            }
            // 数据解析
            do {
                if let responseData: Dictionary = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.allowFragments) as? [String: Any] {
                    analysisModel(dict: responseData)
                }
            }catch{
                shared.requestClosures?(false, "数据解析失败")
                addHistoryModel(title: "失败", content: "数据解析失败")
            }
        }
        task.resume()
    }
    /// 数据模型解析
    /// - Parameter dict: dict
    private static func analysisModel(dict: [String: Any], isLocal: Bool = false) {
        dataQueue.async {
            // 指定长度数组
            var array = [(tilte: String, content: String)](repeating: ("", ""), count: dict.keys.count)
            // 赋值
            _ = dict.keys.enumerated().map { (idx,key) in
                array[idx] = (key, dict[key] as? String ?? "")
            }
            // 缓存解析不保存
            if isLocal == false{
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
        dataQueue.async {
            let strNowTime = shared.timeFormatter.string(from: Date()) as String + content
            shared.historyArray.insert((tilte: title, content: strNowTime), at: 0)
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
//=================================================================
//                              通知
//=================================================================
// MARK: - 通知
extension requestViewModel {
    /// 通知初始化
    private func setupNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForegroundNotification(notification:)), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackgroundNotification(notification:)), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    /// 监听进入前台的通知
    @objc private func willEnterForegroundNotification(notification: Notification) {
        self.timer?.resume()
    }
    /// 监听进入后台的通知
    @objc private func didEnterBackgroundNotification(notification: Notification) {
        self.timer?.suspend()
    }
}
