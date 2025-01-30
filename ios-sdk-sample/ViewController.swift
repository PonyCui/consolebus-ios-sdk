//
//  ViewController.swift
//  ios-sdk-sample
//
//  Created by PonyCui on 2025/1/30.
//

import UIKit
import consolebus_ios_sdk

class ViewController: UIViewController {

    let cbSDK = ConsoleBusIOSSDK(config: ConsoleBusConfig(host: "localhost", port: 9090))
    
    private lazy var testButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("发送调试日志", for: .normal)
        button.addTarget(self, action: #selector(sendDebugLog), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cbSDK.start()
        setupUI()
    }
    
    private func setupUI() {
        view.addSubview(testButton)
        testButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            testButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            testButton.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    @objc private func sendDebugLog() {
        LogUtil.debug(tag: "TestButton") { "用户点击了测试按钮" }
    }

}

