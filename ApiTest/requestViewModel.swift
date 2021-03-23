//
//  requestViewModel.swift
//  ApiTest
//
//  Created by Ad on 2021/3/23.
//
import Foundation
/**
 简单demo项目,故未导入第三方库和网络库封装,直接使用viewModel来实现
 */
struct requestViewModel {
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
    /// 数据处理线程
    private lazy var dataQueue: DispatchQueue = DispatchQueue(label: "")
    /// 回调方法
    private var dataBlock: (([(tilte: String?, content: String?)]) -> Void)?
    //=================================================================
    //                              公开方法
    //=================================================================

    //=================================================================
    //                              私有方法
    //=================================================================
    // MARK: - 私有方法
    /// 网络请求
    static func netRequest() {
        let task = shared.session.dataTask(with: shared.request) { (data, response, error) in
            guard error == nil, data != nil else {
                return
            }
            do {
                if let responseData: Dictionary = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.allowFragments) as? [String: Any] {
                    analysisModel(dict: responseData)
                }
            }catch{
            }
        }
        task.resume()
    }
    /// 数据模型解析
    /// - Parameter dict: dict
    private static func analysisModel(dict: [String: Any]) {
        shared.dataQueue.async {
            // 指定长度数组
            var array = [(tilte: String?, content: String?)](repeating: (nil, nil), count: dict.keys.count)
            // 赋值
            _ = dict.keys.enumerated().map { (idx,key) in
                array[idx] = (key, dict[key] as? String)
            }
            // 主线程执行回调
            DispatchQueue.main.async {
                shared.dataBlock?(array)
            }
        }
    }
}
