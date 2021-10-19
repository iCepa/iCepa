//
//  WebViewController.swift
//  iCepa
//
//  Created by Benjamin Erhart on 21.09.21.
//  Copyright © 2021 Guardian Project. All rights reserved.
//

import UIKit
import WebKit

class WebViewController: UIViewController, WKNavigationDelegate {

    @IBOutlet weak var webView: WKWebView?

    override func viewDidLoad() {
        super.viewDidLoad()

        webView?.navigationDelegate = self

        check()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super .viewWillDisappear(animated)

        webView?.stopLoading()
        webView?.navigationDelegate = nil
        webView = nil
    }
    

    // MARK: Actions

    @IBAction func check() {
        load(URL.checkTor)
    }

    @IBAction func ddg() {
        load(URL.ddgOnion) // .onion v3 address
    }

    @IBAction func fb() {
        load(URL.fbOnion) // .onion v2 address
    }

    @IBAction func neverSsl() {
        load(URL.neverSsl) // unencrypted site should also be allowed.
    }


    // MARK: WKNavigationDelegate

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, preferences: WKWebpagePreferences)
    async -> (WKNavigationActionPolicy, WKWebpagePreferences)
    {
        log("#decidePolicyFor: \(navigationAction) preferences: \(preferences)")

        return (.allow, preferences)
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse)
    async -> WKNavigationResponsePolicy
    {
        log("#decidePolicyForNavigationResponse: \(navigationResponse)")

        return .allow
    }


    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        log("#didStartProvisionalNavigation")
    }

    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        log("#didReceiveServerRedirectForProvisionalNavigation")
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        log("#didFailProvisionalNavigation:withError: \(error)")
    }

    @available(iOS 15.0, *)
    func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
        log("#navigationAction:didBecome:download")
    }

    @available(iOS 15.0, *)
    func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) {
        log("#navigationResponse:didBecome:download")
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        log("#didCommit")
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        log("#didFinish")
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        log("#didFail:withError: \(error.localizedDescription)")
    }

    func webView(_ webView: WKWebView, respondTo challenge: URLAuthenticationChallenge)
    async -> (URLSession.AuthChallengeDisposition, URLCredential?)
    {
        log("#respondTo \(challenge)")

        return (.useCredential, nil)
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        log("#webViewWebContentProcessDidTerminate")
    }

    func webView(_ webView: WKWebView, shouldAllowDeprecatedTLSFor challenge: URLAuthenticationChallenge) async -> Bool {
        log("#shouldAllowDeprecatedTLSFor \(challenge)")

        return true
    }


    // MARK: Private Methods

    private func load(_ url: URL) {
        webView?.stopLoading()

        navigationItem.title = url.host

        webView?.load(URLRequest(url: url))
    }

    private func log(_ msg: String) {
        print("[\(String(describing: type(of: self)))] \(msg)")
    }

}
