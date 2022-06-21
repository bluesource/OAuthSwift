//
//  ASWebAuthenticationURLHandler.swift
//  OAuthSwift
//
//  Created by phimage on 01/11/2019.
//  Copyright © 2019 Dongri Jin, Marchand Eric. All rights reserved.
//

#if targetEnvironment(macCatalyst) || os(iOS)

import AuthenticationServices
import Foundation

@available(iOS 13.0, macCatalyst 13.0, *)
open class ASWebAuthenticationURLHandler: OAuthSwiftURLHandlerType {
    var webAuthSession: ASWebAuthenticationSession!
    let prefersEphemeralWebBrowserSession: Bool
    let callbackUrlScheme: String

    weak var presentationContextProvider: ASWebAuthenticationPresentationContextProviding?

    public init(callbackUrlScheme: String, presentationContextProvider: ASWebAuthenticationPresentationContextProviding?, prefersEphemeralWebBrowserSession: Bool = false) {
        self.callbackUrlScheme = callbackUrlScheme
        self.presentationContextProvider = presentationContextProvider
        self.prefersEphemeralWebBrowserSession = prefersEphemeralWebBrowserSession
    }

    public func handle(_ url: URL) {
        webAuthSession = ASWebAuthenticationSession(
            url: url,
            callbackURLScheme: callbackUrlScheme,
            completionHandler: { callback, error in
                if let error = error {
                    let msg = error.localizedDescription.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
                    let errorDomain = (error as NSError).domain
                    let errorCode = (error as NSError).code
                    let urlString = "\(self.callbackUrlScheme):?error=\(msg ?? "UNKNOWN")&error_domain=\(errorDomain)&error_code=\(errorCode)"
                    let url = URL(string: urlString)!
                    #if !OAUTH_APP_EXTENSIONS
                    OAuthSwift.handle(url: url)
                    // dont call UIApplication.shared.open this can be handlet without any callback
                    // UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    #endif
                } else if let successURL = callback {
                    #if !OAUTH_APP_EXTENSIONS
                    // ont call UIApplication.shared.open this can be handlet without any callback
                    // the app is running in the background. calling open would result in an error
                    OAuthSwift.handle(url: successURL)
                    // UIApplication.shared.open(successURL, options: [:], completionHandler: nil)
                    #endif
                }
        })
        webAuthSession.presentationContextProvider = presentationContextProvider
        webAuthSession.prefersEphemeralWebBrowserSession = prefersEphemeralWebBrowserSession

        _ = webAuthSession.start()
        OAuthSwift.log?.trace("ASWebAuthenticationSession is started")

    }
}

@available(iOS 13.0, macCatalyst 13.0, *)
extension ASWebAuthenticationURLHandler {
    static func isCancelledError(domain: String, code: Int) -> Bool {
        return domain == ASWebAuthenticationSessionErrorDomain &&
            code == ASWebAuthenticationSessionError.canceledLogin.rawValue
    }
}
#endif
