//
//  ErrorMessage.swift
//  sesame-sdk-test-app
//
//  Created by Wayne Hsiao on 2020/5/3.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
import AWSMobileClient

public struct ErrorMessage {
    public static func descriptionFromError(error: Error) -> String {
        if let error = error as? AWSMobileClientError {
            let printableMessage: String
            switch error {
            case .aliasExists(let message): printableMessage = message
            case .codeDeliveryFailure(let message): printableMessage = message
            case .codeMismatch(let message): printableMessage = message
            case .expiredCode(let message): printableMessage = message
            case .groupExists(let message): printableMessage = message
            case .internalError(let message): printableMessage = message
            case .invalidLambdaResponse(let message): printableMessage = message
            case .invalidOAuthFlow(let message): printableMessage = message
            case .invalidParameter(let message): printableMessage = message
            case .invalidPassword(let message): printableMessage = message
            case .invalidUserPoolConfiguration(let message): printableMessage = message
            case .limitExceeded(let message): printableMessage = message
            case .mfaMethodNotFound(let message): printableMessage = message
            case .notAuthorized(let message): printableMessage = message
            case .passwordResetRequired(let message): printableMessage = message
            case .resourceNotFound(let message): printableMessage = message
            case .scopeDoesNotExist(let message): printableMessage = message
            case .softwareTokenMFANotFound(let message): printableMessage = message
            case .tooManyFailedAttempts(let message): printableMessage = message
            case .tooManyRequests(let message): printableMessage = message
            case .unexpectedLambda(let message): printableMessage = message
            case .userLambdaValidation(let message): printableMessage = message
            case .userNotConfirmed(let message): printableMessage = message
            case .userNotFound(let message): printableMessage = message
            case .usernameExists(let message): printableMessage = message
            case .unknown(let message): printableMessage = message
            case .notSignedIn(let message): printableMessage = message
            case .identityIdUnavailable(let message): printableMessage = message
            case .guestAccessNotAllowed(let message): printableMessage = message
            case .federationProviderExists(let message): printableMessage = message
            case .cognitoIdentityPoolNotConfigured(let message): printableMessage = message
            case .unableToSignIn(let message): printableMessage = message
            case .invalidState(let message): printableMessage = message
            case .userPoolNotConfigured(let message): printableMessage = message
            case .userCancelledSignIn(let message): printableMessage = message
            case .badRequest(let message): printableMessage = message
            case .expiredRefreshToken(let message): printableMessage = message
            case .errorLoadingPage(let message): printableMessage = message
            case .securityFailed(let message): printableMessage = message
            case .idTokenNotIssued(let message): printableMessage = message
            case .idTokenAndAcceessTokenNotIssued(let message): printableMessage = message
            case .invalidConfiguration(let message): printableMessage = message
            case .deviceNotRemembered(let message): printableMessage = message
            }
            return printableMessage.localizedCapitalized
        }
        return error.localizedDescription
    }
}
