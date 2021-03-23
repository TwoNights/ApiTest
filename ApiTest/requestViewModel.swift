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
/// 数据处理线程
private var dataQueue: DispatchQueue = DispatchQueue(label: "ApiTestRequestViewModel.data")
/// 成功闭包
typealias requestSuccessClosures = ([(tilte: String, content: String)]) -> Void
/// 失败闭包
typealias requestFailClosures = (String?) -> Void
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
    /// 成功回调方法
    private var successClosures: requestSuccessClosures?
    /// 失败回调方法
    private var failClosures: requestFailClosures?
    /// 定时器
    private var timer: EDGCDTimer?
    //=================================================================
    //                              公开方法
    //=================================================================
    /// 开始刷新数据
    /// - Parameters:
    ///   - success: 成功回调
    ///   - fail: 失败回调
    static func start(success: requestSuccessClosures?, fail: requestFailClosures?) {
        shared.successClosures = success
        shared.failClosures = fail
        //防止外部多次调用
        if shared.timer != nil {
            shared.timer?.cancel()
        }
        shared.timer = EDGCDTimer(interval: 5, action: {
            netRequest()
        })
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
                shared.failClosures?(error?.localizedDescription)
                return
            }
            guard data != nil else {
                shared.failClosures?("返回data为空")
                return
            }
            // 数据解析
            do {
                if let responseData: Dictionary = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.allowFragments) as? [String: Any] {
                    analysisModel(dict: responseData)
                }
            }catch{
                shared.failClosures?("数据解析失败")
            }
        }
        task.resume()
    }
    /// 数据模型解析
    /// - Parameter dict: dict
    private static func analysisModel(dict: [String: Any]) {
        dataQueue.async {
            // 指定长度数组
            var array = [(tilte: String, content: String)](repeating: ("", ""), count: dict.keys.count)
            // 赋值
            _ = dict.keys.enumerated().map { (idx,key) in
                array[idx] = (key, dict[key] as? String ?? "")
            }
            // 主线程执行回调
            DispatchQueue.main.async {
                shared.successClosures?(array)
            }
        }
    }
    /// 移除通知
    deinit {
        NotificationCenter.default.removeObserver(self)
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
