//
//  SocketManager.swift
//  Remote
//
//  Created by Indiana Kernick on 29/1/21.
//  Copyright © 2021 Indiana Kernick. All rights reserved.
//

import Foundation
import Starscream

protocol SocketManagerDelegate: AnyObject {
    func onlineStatusChanged(online: Bool)
}

class SocketManager: WebSocketDelegate {
    private static let retryDelay = 1.0
    private static let tickDelay = 0.05
    private static let maxTickCount = Int(30.0 / tickDelay)
    private static let emptyData = Data()
    
    private var socket: WebSocket!
    private var tickTimer: Timer?
    private var tickCount = 0
    private var onlineStatus = false
    private var dummyMode = false
    private var host = ""
    private var lowLatencyMode = true

    weak var delegate: SocketManagerDelegate?
    
    func connectTo(host: String) {
        self.host = host
        stopTicking()
        updateOnlineStatus(online: false)
        
        if host == "dummy" {
            dummyMode = true
            updateOnlineStatus(online: true)
        } else {
            dummyMode = false
            if let url = URL(string: "ws://" + host + ":80") {
                socket = WebSocket(url: url)
                socket.delegate = self
                socket.connect()
            }
        }
    }

    func reconnect() {
        if !dummyMode {
            socket.connect()
        }
    }

    func websocketDidConnect(socket: WebSocketClient) {
        updateOnlineStatus(online: true)
        tickCount = 0
        startTicking()
    }

    func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        stopTicking()
        updateOnlineStatus(online: false)
        DispatchQueue.main.asyncAfter(deadline: .now() + SocketManager.retryDelay) {
            self.reconnect()
        }
    }

    func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {}

    func websocketDidReceiveData(socket: WebSocketClient, data: Data) {}

    func send(_ data: Data) {
        if dummyMode { return }
        socket.write(data: data)
        tickCount = 0
        if tickTimer == nil {
            startTicking()
        }
    }
    
    func send(_ data: [UInt8]) {
        send(Data(data))
    }
    
    func getOnlineStatus() -> Bool {
        onlineStatus
    }
    
    func getOnlineHost() -> String? {
        onlineStatus ? host : nil
    }
    
    func setLowLatencyMode(enabled: Bool) {
        lowLatencyMode = enabled
        if lowLatencyMode {
            startTicking()
        } else {
            stopTicking()
        }
    }

    private func startTicking() {
        if lowLatencyMode {
            tickTimer = Timer.scheduledTimer(
                timeInterval: SocketManager.tickDelay,
                target: self,
                selector: #selector(self.sendTick),
                userInfo: nil,
                repeats: true
            )
        }
    }
    
    private func stopTicking() {
        tickTimer?.invalidate()
        tickTimer = nil
    }
    
    @objc private func sendTick() {
        if dummyMode || tickTimer == nil { return }
        socket.write(data: SocketManager.emptyData)
        tickCount += 1
        if tickCount > SocketManager.maxTickCount {
            stopTicking()
        }
    }
    
    private func updateOnlineStatus(online: Bool) {
        if online != onlineStatus {
            onlineStatus = online
            delegate?.onlineStatusChanged(online: onlineStatus)
        }
    }
}
