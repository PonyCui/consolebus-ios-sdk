//
//  ViewController.swift
//  ios-sdk-sample
//
//  Created by PonyCui on 2025/1/30.
//

import UIKit
import consolebus_ios_sdk

class ViewController: UIViewController {

    let cbSDK = ConsoleBusIOSSDK(
        connectorConfig: WebSocketConnectorConfig(host: "localhost", port: 9090)
//        connectorConfig: LocalFileConnectorConfig(filename: nil)
    )
    
    private lazy var testButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("发送调试日志", for: .normal)
        button.addTarget(self, action: #selector(sendDebugLog), for: .touchUpInside)
        return button
    }()
    
    private lazy var githubButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("发送 GitHub 请求", for: .normal)
        button.addTarget(self, action: #selector(sendGitHubRequest), for: .touchUpInside)
        return button
    }()
    
    private lazy var postButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("发送 POST 请求", for: .normal)
        button.addTarget(self, action: #selector(sendPostRequest), for: .touchUpInside)
        return button
    }()
    
    private lazy var avatarButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("请求 GitHub 头像", for: .normal)
        button.addTarget(self, action: #selector(sendAvatarRequest), for: .touchUpInside)
        return button
    }()
    
    private lazy var failedButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("发送失败请求", for: .normal)
        button.addTarget(self, action: #selector(sendFailedRequest), for: .touchUpInside)
        return button
    }()
    
    private lazy var cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("发送并取消请求", for: .normal)
        button.addTarget(self, action: #selector(sendAndCancelRequest), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        LocalFileManager.cleanLogFiles(config: LocalFileManagerConfig())
        cbSDK.start()
        NetworkURLSessionAdapter.register()
        PreferenceUserDefaultsAdapter.register()
        setupUI()
    }
    
    private func setupUI() {
        view.addSubview(testButton)
        view.addSubview(githubButton)
        view.addSubview(postButton)
        view.addSubview(avatarButton)
        view.addSubview(failedButton)
        view.addSubview(cancelButton)
        testButton.translatesAutoresizingMaskIntoConstraints = false
        githubButton.translatesAutoresizingMaskIntoConstraints = false
        postButton.translatesAutoresizingMaskIntoConstraints = false
        avatarButton.translatesAutoresizingMaskIntoConstraints = false
        failedButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            testButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            testButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            githubButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            githubButton.topAnchor.constraint(equalTo: testButton.bottomAnchor, constant: 20),
            
            postButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            postButton.topAnchor.constraint(equalTo: githubButton.bottomAnchor, constant: 20),
            
            avatarButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            avatarButton.topAnchor.constraint(equalTo: postButton.bottomAnchor, constant: 20),
            
            failedButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            failedButton.topAnchor.constraint(equalTo: avatarButton.bottomAnchor, constant: 20),
            
            cancelButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cancelButton.topAnchor.constraint(equalTo: failedButton.bottomAnchor, constant: 20)
        ])
    }
    
    @objc private func sendAvatarRequest() {
        let url = URL(string: "https://avatars.githubusercontent.com/u/5013664?v=4")!
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error: \(error)")
                return
            }
            if let data = data {
                if let img = UIImage(data: data) {
                    LogUtil.debug(tag: "sendAvatarRequest") { img }
                }
                print("Received image data of size: \(data.count) bytes")
            }
        }
        task.resume()
    }
    
    @objc private func sendGitHubRequest() {
        let url = URL(string: "https://api.github.com")!
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error: \(error)")
                return
            }
            if let data = data,
               let responseString = String(data: data, encoding: .utf8) {
                print("Response: \(responseString)")
            }
        }
        task.resume()
    }
    
    @objc private func sendPostRequest() {
        let url = URL(string: "https://httpbin.org/post")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload = ["test": "data", "time": Date().timeIntervalSince1970] as [String : Any]
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error)")
                return
            }
            if let data = data,
               let responseString = String(data: data, encoding: .utf8) {
                print("Response: \(responseString)")
            }
        }
        task.resume()
    }
    
    @objc private func sendDebugLog() {
        LogUtil.captureScreenWhenError = true
        LogUtil.debug(tag: "TestButton") { "用户点击了测试按钮" }
        LogUtil.debug(tag: "TestButton") { ["tips": ["用户点击了测试按钮"]] }
        LogUtil.error(tag: "TestError") { "这是一条错误信息" }
    }
    
    @objc private func sendFailedRequest() {
        let url = URL(string: "https://non-existent-domain-12345.com")!
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error: \(error)")
                return
            }
        }
        task.resume()
    }
    
    @objc private func sendAndCancelRequest() {
        let url = URL(string: "https://api.github.com/repos/torvalds/linux")!
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error: \(error)")
                return
            }
        }
        task.resume()
        task.cancel()
    }

}

