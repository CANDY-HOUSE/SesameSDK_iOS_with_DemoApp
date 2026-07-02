//
//  FirmwareZipRuntimeCache.swift
//  SesameWatchKitSDK
//
//  Created by frey Mac on 2026/7/1.
//  Copyright © 2026 CandyHouse. All rights reserved.
//

import Foundation

final class FirmwareZipRuntimeCache {
    
    static let shared = FirmwareZipRuntimeCache()
    
    private var cachedFiles: [String: URL] = [:]
    private let lockQueue = DispatchQueue(label: "co.candyhouse.firmware.runtime.cache")
    
    private init() {}
    
    func getFirmwarePath(
        zipUrl: String,
        fileName: String,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        if let cached = cachedFile(for: zipUrl),
           FileManager.default.fileExists(atPath: cached.path),
           fileSize(cached) > 0 {
            completion(.success(cached))
            return
        }
        
        guard let url = URL(string: zipUrl) else {
            completion(.failure(NSError(
                domain: "FirmwareZipRuntimeCache",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid firmware url"]
            )))
            return
        }
        
        let safeFileName = sanitizeFileName(fileName)
        
        guard !safeFileName.isEmpty else {
            completion(.failure(NSError(
                domain: "FirmwareZipRuntimeCache",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "Invalid firmware fileName"]
            )))
            return
        }
        
        let cacheDir = firmwareCacheDir()
        
        do {
            try FileManager.default.createDirectory(
                at: cacheDir,
                withIntermediateDirectories: true
            )
        } catch {
            completion(.failure(error))
            return
        }
        
        let targetURL = cacheDir.appendingPathComponent(safeFileName)
        
        URLSession.shared.downloadTask(with: url) { [weak self] tempURL, response, error in
            guard let self = self else { return }
            
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse,
               !(200...299).contains(httpResponse.statusCode) {
                completion(.failure(NSError(
                    domain: "FirmwareZipRuntimeCache",
                    code: httpResponse.statusCode,
                    userInfo: [NSLocalizedDescriptionKey: "Download firmware failed: \(httpResponse.statusCode)"]
                )))
                return
            }
            
            guard let tempURL = tempURL else {
                completion(.failure(NSError(
                    domain: "FirmwareZipRuntimeCache",
                    code: -3,
                    userInfo: [NSLocalizedDescriptionKey: "Downloaded firmware temp file is missing"]
                )))
                return
            }
            
            do {
                if FileManager.default.fileExists(atPath: targetURL.path) {
                    try FileManager.default.removeItem(at: targetURL)
                }
                
                try FileManager.default.moveItem(at: tempURL, to: targetURL)
                
                guard self.fileSize(targetURL) > 0 else {
                    throw NSError(
                        domain: "FirmwareZipRuntimeCache",
                        code: -4,
                        userInfo: [NSLocalizedDescriptionKey: "Downloaded firmware file is empty"]
                    )
                }
                
                self.setCachedFile(targetURL, for: zipUrl)
                
                completion(.success(targetURL))
            } catch {
                try? FileManager.default.removeItem(at: targetURL)
                completion(.failure(error))
            }
        }.resume()
    }
    
    private func cachedFile(for zipUrl: String) -> URL? {
        lockQueue.sync {
            cachedFiles[zipUrl]
        }
    }
    
    private func setCachedFile(_ file: URL, for zipUrl: String) {
        lockQueue.sync {
            cachedFiles[zipUrl] = file
        }
    }
    
    private func firmwareCacheDir() -> URL {
        FileManager.default.urls(
            for: .cachesDirectory,
            in: .userDomainMask
        )[0].appendingPathComponent("firmware_runtime", isDirectory: true)
    }
    
    private func sanitizeFileName(_ fileName: String) -> String {
        let name = fileName
            .split(separator: "/")
            .last
            .map(String.init) ?? fileName
        
        let cleanName = name
            .split(separator: "?")
            .first
            .map(String.init) ?? name
        
        return cleanName.replacingOccurrences(
            of: "[^A-Za-z0-9._-]",
            with: "_",
            options: .regularExpression
        )
    }
    
    private func fileSize(_ url: URL) -> UInt64 {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let size = attributes[.size] as? UInt64 else {
            return 0
        }
        
        return size
    }
}
