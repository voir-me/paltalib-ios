import Foundation
import AppsFlyerLib

protocol PaltaAppsflyerAdapterDelegate: AnyObject {
    func didReceiveConversion(_ adapter: PaltaAppsflyerAdapter, with result: Result<[AnyHashable: Any], Error>)
    func didReceiveAttributionInfo(_ adapter: PaltaAppsflyerAdapter, with result: Result<[AnyHashable: Any], Error>)
    func didReceiveDeepLink(_ attribution: PaltaAppsflyerAdapter, deepLink: PaltaAttribution.DeepLink)
}

final class PaltaAppsflyerAdapter: NSObject {
    private static let _sharedInstance = PaltaAppsflyerAdapter(appsflyerInstance: AppsFlyerLib.shared())
    static var sharedInstance: PaltaAppsflyerAdapter {
        defer {
            _sharedInstance.checkAppsflyerDelegateWasNotStolen()
        }

        return _sharedInstance
    }

    weak var delegate: PaltaAppsflyerAdapterDelegate?

    private let appsflyerInstance: AppsFlyerLib
    init(appsflyerInstance: AppsFlyerLib) {
        self.appsflyerInstance = appsflyerInstance

        super.init()

        appsflyerInstance.delegate = self
        appsflyerInstance.deepLinkDelegate = self
    }

    var appsflyerUID: String {
        return appsflyerInstance.getAppsFlyerUID()
    }

    func setAppsflyerDevKey(_ key: String) {
        appsflyerInstance.appsFlyerDevKey = key
    }

    func setAppleAppID(_ appID: String) {
        appsflyerInstance.appleAppID = appID
    }

    func setCustomerUserID(_ userID: String) {
        appsflyerInstance.customerUserID = userID
    }

    func setUseUninstallSandbox(_ use: Bool) {
        appsflyerInstance.useUninstallSandbox = use
    }

    func waitForATTUserAuthorization(with timeout: TimeInterval) {
        appsflyerInstance.waitForATTUserAuthorization(timeoutInterval: timeout)
    }

    func start() {
        appsflyerInstance.start()
    }

    func continueUserActivity(_ userActivity: NSUserActivity,
                              restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        appsflyerInstance.continue(userActivity, restorationHandler: nil)
        return true
    }

    func open(url: URL,
              options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        appsflyerInstance.handleOpen(url, options: options)
        return true
    }

    func registerUninstall(deviceToken: Data) {
        appsflyerInstance.registerUninstall(deviceToken)
    }

    private func checkAppsflyerDelegateWasNotStolen() {
        guard appsflyerInstance.delegate === self else {
            fatalError("Appsflyer delegate has been reset to \(appsflyerInstance.delegate ?? nil)")
        }
    }
}

extension PaltaAppsflyerAdapter: AppsFlyerLibDelegate {
    func onConversionDataSuccess(_ conversionInfo: [AnyHashable: Any]) {
        delegate?.didReceiveConversion(self, with: .success(conversionInfo))
    }

    func onConversionDataFail(_ error: Error) {
        delegate?.didReceiveConversion(self, with: .failure(error))
    }

    func onAppOpenAttribution(_ attributionData: [AnyHashable: Any]) {
        delegate?.didReceiveAttributionInfo(self, with: .success(attributionData))
    }

    func onAppOpenAttributionFailure(_ error: Error) {
        delegate?.didReceiveAttributionInfo(self, with: .failure(error))
    }
}

extension PaltaAppsflyerAdapter: DeepLinkDelegate {
    func didResolveDeepLink(_ result: DeepLinkResult) {
        switch result.status {
        case .notFound:
            print("Deep link not found")
        case .found:
            guard let deepLink = result.deepLink else {
                assertionFailure()
                return
            }

            let deepLinkStr: String = deepLink.toString()
            print("DeepLink data is: \(deepLinkStr)")
            if( result.deepLink?.isDeferred == true) {
                print("This is a deferred deep link")
            } else {
                print("This is a direct deep link")
            }
            let result = PaltaAttribution.DeepLink(clickEvent: deepLink.clickEvent,
                                                   deeplinkValue: deepLink.deeplinkValue,
                                                   matchType: deepLink.matchType,
                                                   clickHTTPReferrer: deepLink.clickHTTPReferrer,
                                                   mediaSource: deepLink.mediaSource,
                                                   campaign: deepLink.campaign,
                                                   campaignId: deepLink.campaignId,
                                                   afSub1: deepLink.afSub1,
                                                   afSub2: deepLink.afSub2,
                                                   afSub3: deepLink.afSub3,
                                                   afSub4: deepLink.afSub4,
                                                   afSub5: deepLink.afSub5,
                                                   isDeferred: deepLink.isDeferred)
            delegate?.didReceiveDeepLink(self, deepLink: result)
        case .failure:
            print("Error %@", result.error!)
        }
    }
}
