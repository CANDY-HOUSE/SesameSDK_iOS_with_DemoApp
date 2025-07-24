//
//  NotificationService.swift
//  NotificationService
//
//  Created by frey Mac on 2025/7/22.
//  Copyright © 2025 CandyHouse. All rights reserved.
//

import UserNotifications

class NotificationService: UNNotificationServiceExtension {
    
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    
    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        if let bestAttemptContent = bestAttemptContent {
            // 从 userInfo 获取图片 URL
            if let imageUrlString = bestAttemptContent.userInfo["imageUrl"] as? String,
               !imageUrlString.isEmpty,
               let imageUrl = URL(string: imageUrlString) {
                
                // 下载图片
                downloadImage(from: imageUrl) { localURL in
                    if let localURL = localURL {
                        if let attachment = try? UNNotificationAttachment(
                            identifier: "image",
                            url: localURL,
                            options: [
                                UNNotificationAttachmentOptionsThumbnailHiddenKey: false
                            ]
                        ) {
                            bestAttemptContent.attachments = [attachment]
                        }
                    }
                    contentHandler(bestAttemptContent)
                }
            } else {
                // 没有图片，直接显示
                contentHandler(bestAttemptContent)
            }
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        // 超时处理
        if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
    
    private func downloadImage(from url: URL, completion: @escaping (URL?) -> Void) {
        let task = URLSession.shared.downloadTask(with: url) { localURL, response, error in
            guard let localURL = localURL, error == nil else {
                completion(nil)
                return
            }
            
            // 将文件移动到临时目录
            let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension(url.pathExtension)
            
            do {
                try FileManager.default.moveItem(at: localURL, to: tempURL)
                completion(tempURL)
            } catch {
                completion(nil)
            }
        }
        task.resume()
    }
}
