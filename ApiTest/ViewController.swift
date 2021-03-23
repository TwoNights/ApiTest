//
//  ViewController.swift
//  ApiTest
//
//  Created by Ad on 2021/3/23.
//

import UIKit
private let ApiTestModelID = "ApiTestModelID" /// cell Id
class ViewController: UIViewController {
    /// tableView
    private lazy var tableView: UITableView = {
        // 没导入约束库,暂时用frame实现
        let topMargin = switchButton.frame.height + switchButton.frame.origin.y
        let tableView = UITableView(frame: CGRect(x: 0, y: topMargin, width: screenWidth, height: screenHeight - topMargin - CGFloat(safeBottomHeight)), style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        return tableView
    }()
    /// 头部标题
    private lazy var topLabel: UILabel = {
        let topLabel = UILabel(frame: CGRect(x: 0, y: statusBarHeight, width: screenWidth * 0.5, height: 60))
        topLabel.numberOfLines = 3
        topLabel.text = "请求中"
        topLabel.backgroundColor = .yellow
        topLabel.adjustsFontSizeToFitWidth = true
        topLabel.textAlignment = .center
        return topLabel
    }()
    /// 历史切换按钮
    private lazy var switchButton: UIButton = {
        let switchButton = UIButton(frame: CGRect(x: screenWidth * 0.5, y: statusBarHeight, width: screenWidth * 0.5, height: 60))
        switchButton.setTitle("点击显示历史记录", for: .normal)
        switchButton.setTitle("点击显示最新列表数据", for: .selected)
        switchButton.titleLabel?.adjustsFontSizeToFitWidth = true
        switchButton.backgroundColor = .darkGray
        switchButton.addTarget(self, action: #selector(switchButtonAction), for: .touchUpInside)
        switchButton.setTitleColor(.black, for: .normal)
        switchButton.setTitleColor(.black, for: .selected)
        return switchButton
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        // UI配置
        configUI()
        // 开启请求
        requestViewModel.start { [weak self] (_ success, _ errorMsg) in
            if success {
                self?.topLabel.text = "请求成功"
                self?.topLabel.backgroundColor = .green
                self?.tableView.reloadData()
            } else {
                self?.topLabel.backgroundColor = .red
                self?.topLabel.text = "刷新失败,\(errorMsg ?? "")"
            }
        }
    }
    /// 切换按钮点击事件
    @objc private func switchButtonAction() {
        switchButton.isSelected.toggle()
        requestViewModel.switchShowModel()
        tableView.reloadData()
    }
    /// UI布局初始化
    private func configUI() {
        view.addSubview(topLabel)
        view.addSubview(switchButton)
        view.addSubview(tableView)
    }
}
//=================================================================
//                    tableView代理
//=================================================================
// MARK: - tableView代理
extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return requestViewModel.readModelArray()?.count ?? 0
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // 不想导约束库,暂时写死
        return 100
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ApiTestModelID) ?? UITableViewCell(style: .subtitle, reuseIdentifier: ApiTestModelID)
        if indexPath.row < requestViewModel.readModelArray()?.count ?? 0 {
            cell.textLabel?.text = requestViewModel.readModelArray()?[indexPath.row].tilte
            cell.detailTextLabel?.text = requestViewModel.readModelArray()?[indexPath.row].content
        }
        cell.detailTextLabel?.numberOfLines = 0
        return cell
    }
}
