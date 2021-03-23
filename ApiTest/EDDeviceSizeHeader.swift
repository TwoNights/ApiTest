//
//  EDDeviceSizeHeader.swift
//  EddidOne
//
//  Created by Ad on 2020/4/13.
//  Copyright © 2020 Ad. All rights reserved.
//

import UIKit

/// 状态栏高度
let statusBarHeight = isFullScreen ? CGFloat(44.0) : CGFloat(20.0)
/// NavigationBar 高度
let navBarHeight = CGFloat(44.0)
///tabbar高度
let tabbarHeight = isFullScreen ? CGFloat(49+34) : CGFloat(49)
/// 状态栏 + NavigationBar 高度
let statusNavBarHeight = statusBarHeight + navBarHeight
/// 屏幕宽度
let screenWidth = UIScreen.main.bounds.width
/// 屏幕高度
let screenHeight = UIScreen.main.bounds.height
/// 屏幕真实宽度
let screenTrueWidth = screenWidth * UIScreen.main.scale
/// 屏幕真实高度
let screenTrueHeight = screenHeight * UIScreen.main.scale
/// 底部安全高度
let safeBottomHeight = isFullScreen ? 15.0 : 0.0
/// 全面屏判断(暂时用)
var isFullScreen: Bool {
    let width = screenWidth
    let height = screenHeight
    if (width == 375.0 && height == 812.0) ||
        (width == 812.0 && height == 375.0) ||
        (width == 414.0 && height == 896.0) ||
        (width == 896.0 && height == 414.0) ||
        (width == 390.0 && height == 844.0) ||
        (width == 428.0 && height == 926.0) {
        return true
    } else {
        return false
    }
}
