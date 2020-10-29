//
//  HeaderViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 21.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

/// Header bar will adapt to the devices size
class HeaderViewController: ContainerViewController {
    @IBOutlet weak var headerBar: UIView!
    @IBOutlet weak var barShadowView: UIImageView!
    @IBOutlet weak var safeBarView: SafeBarView!
    @IBOutlet weak var noSafeBarView: NoSafeBarView!
    @IBOutlet weak var switchSafeButton: UIButton!
    @IBOutlet weak var contentView: UIView!

    var rootViewController: UIViewController?

    var notificationCenter = NotificationCenter.default

    convenience init(rootViewController: UIViewController) {
        self.init(namedClass: nil)
        self.rootViewController = rootViewController
        viewControllers = [rootViewController]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        safeBarView.button.addTarget(self, action: #selector(didTapSafeBarView(_:)), for: .touchUpInside)
        reloadHeaderBar()
        displayRootController()
        notificationCenter.addObserver(self,
                                       selector: #selector(reloadHeaderBar),
                                       name: .selectedSafeChanged,
                                       object: nil)
    }

    func displayRootController() {
        assert(!viewControllers.isEmpty)
        displayChild(at: 0, in: contentView)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    @IBAction func didTapSwitchSafe(_ sender: Any) {
        // present Switch Safe VC modally
    }

    @objc func didTapSafeBarView(_ sender: Any) {
        // present Safe Info VC modally
        // using the custom "CenteredCard" animator for transitioning delegate
    }

    @objc func reloadHeaderBar() {
        do {
            let selectedSafe = try Safe.getSelected()
            let hasSafe = selectedSafe != nil
            safeBarView.isHidden = !hasSafe
            switchSafeButton.isHidden = !hasSafe
            noSafeBarView.isHidden = hasSafe

            if let safe = selectedSafe {
                safeBarView.setAddress(safe.displayAddress)
                safeBarView.setName(safe.displayName)
            }
        } catch {
            // TODO: snackbar error
            LogService.shared.error("Failed to load selected safe: \(error)")
        }
    }

    // TODO: clarify with Sasha
    // change header bar height depending on the device height / configuration (height is compact)
    //      how to get it or how to get notified?

}