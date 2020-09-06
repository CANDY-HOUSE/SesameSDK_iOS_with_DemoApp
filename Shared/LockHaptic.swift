//
//  LockHaptic.swift
//  SesameUI
//
//  Created by Wayne Hsiao on 2020/9/1.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
#if os(iOS)
import UIKit
import SesameSDK
#elseif os(watchOS)
import WatchKit
import SesameWatchKitSDK
#endif

protocol LockHaptic: class {
    var lockIntention: ((CHSesame2Intention) -> Void)? { get set }
}

extension LockHaptic {
    private func startHaptic() {
        #if os(iOS)
        let impactFeedbackgenerator = UIImpactFeedbackGenerator(style: .medium)
        impactFeedbackgenerator.prepare()
        impactFeedbackgenerator.impactOccurred()
        #elseif os(watchOS)
        WKInterfaceDevice.current().play(.start)
        #endif
    }
    
    private func completeHaptic() {
        #if os(iOS)
        let notificationFeedbackGenerator = UINotificationFeedbackGenerator()
        notificationFeedbackGenerator.prepare()
        notificationFeedbackGenerator.notificationOccurred(.success)
        #elseif os(watchOS)
        WKInterfaceDevice.current().play(.stop)
        #endif
    }
    
    func toggleWithHaptic(sesame2: CHSesame2, _ completion: @escaping (() -> Void)) {
        lockIntention = { [weak self] intention in
            if intention == .idle {
                self?.completeHaptic()
                self?.lockIntention = nil
                completion()
            }
        }
        startHaptic()
        sesame2.toggle { _ in
            
        }
    }
}
