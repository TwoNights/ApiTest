//
//  GCDTimer.swift
//
//  Created by IMac on 2020/4/17.
//  Copyright © 2020 Ad. All rights reserved.
//
//定时器初始化默认延迟执行为0s, 重复,
// 定时器拥有 开启 暂停  取消 恢复

import Foundation

class GCDTimer: NSObject {
    typealias ActionBlock = () -> Void
    ///执行时间
    private var interval: TimeInterval!
    ///延迟时间
    private var delaySecs: TimeInterval!
    ///队列
    private var serialQueue: DispatchQueue!
    ///是否重复
    private var repeats: Bool = true
    ///响应
    private var action: ActionBlock?
    ///定时器
    private var timer: DispatchSourceTimer!
    ///是否正在运行
    private(set) var isRuning: Bool = false
    ///响应次数
    private (set) var actionTimes: NSInteger = 0
    /// 创建定时器
    /// - Parameters:
    ///   - interval: 间隔时间
    ///   - delaySecs: 第一次执行延迟时间，默认为0
    ///   - queue: 定时器调用的队列，默认子队列
    ///   - repeats: 是否重复执行，默认true
    ///   - autoStart: 自动start
    ///   - action: 响应
    init(interval: TimeInterval, delaySecs: TimeInterval = 0, queue: DispatchQueue = DispatchQueue.global(), repeats: Bool = true, autoStart: Bool = true, action: ActionBlock?) {
        super.init()
        self.interval = interval
        self.delaySecs = delaySecs
        self.repeats = repeats
        self.serialQueue = DispatchQueue.init(label: String(format: "CLGCDTimer.%p", self), target: queue)
        self.action = action
        timer = DispatchSource.makeTimerSource(queue: self.serialQueue)
        if autoStart {
            start()
        }
    }
    deinit {
        cancel()
    }
}
extension GCDTimer {
    ///开始定时器
    func start() {
        timer.schedule(deadline: .now() + delaySecs, repeating: interval, leeway: DispatchTimeInterval.never)
        timer.setEventHandler { [weak self] in
            guard let strongSelf = self else {
                return
            }
            strongSelf.actionTimes += 1
            strongSelf.action?()
            if !strongSelf.repeats {
                strongSelf.cancel()
            }
        }
        resume()
    }
    ///暂停
    func suspend() {
        if isRuning {
            timer.suspend()
            isRuning = false
        }
    }
    ///恢复定时器
    func resume() {
        if !isRuning {
            timer.resume()
            isRuning = true
        }
    }
    ///取消定时器
    func cancel() {
        if !isRuning {
            resume()
        }
        timer.cancel()
    }
}
