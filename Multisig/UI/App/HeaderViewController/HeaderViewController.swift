//
//  HeaderViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 21.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

/// Header bar will adapt to the devices size
final class HeaderViewController: ContainerViewController {
    @IBOutlet private weak var headerBar: UIView!
    @IBOutlet private weak var barShadowView: UIImageView!
    @IBOutlet private weak var safeBarView: SafeBarView!
    @IBOutlet private weak var noSafeBarView: NoSafeBarView!
    @IBOutlet private weak var switchSafeButton: UIButton!
    @IBOutlet private weak var contentView: UIView!
    @IBOutlet private weak var headerBarHeightConstraint: NSLayoutConstraint!

    private var rootViewController: UIViewController?

    var notificationCenter = NotificationCenter.default

    convenience init(rootViewController: UIViewController) {
        self.init(namedClass: nil)
        self.rootViewController = rootViewController
        viewControllers = [rootViewController]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        safeBarView.addTarget(self, action: #selector(didTapSafeBarView(_:)), for: .touchUpInside)
        reloadHeaderBar()
        displayRootController()
        notificationCenter.addObserver(self,
                                       selector: #selector(reloadHeaderBar),
                                       name: .selectedSafeChanged,
                                       object: nil)
        headerBarHeightConstraint.constant = ScreenMetrics.safeHeaderHeight
    }

    private func displayRootController() {
        assert(!viewControllers.isEmpty)
        displayChild(at: 0, in: contentView)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.isHidden = false
    }

    @IBAction private func didTapSwitchSafe(_ sender: Any) {
        let switchSafesVC = SwitchSafesViewController()
        let nav = UINavigationController(rootViewController: switchSafesVC)
        present(nav, animated: true)
    }

    @objc private func didTapSafeBarView(_ sender: Any) {
        let vc = SafeInfoViewController(nibName: nil, bundle: nil)
        vc.modalPresentationStyle = .overFullScreen
        vc.modalTransitionStyle = .crossDissolve
        present(vc, animated: true, completion: nil)
    }

    @objc private func reloadHeaderBar() {
        do {
            let selectedSafe = try Safe.getSelected()
            let hasSafe = selectedSafe != nil
            safeBarView.isHidden = !hasSafe
            switchSafeButton.isHidden = !hasSafe
            noSafeBarView.isHidden = hasSafe

            if let safe = selectedSafe {
                safeBarView.setAddress(safe.addressValue)
                safeBarView.setName(safe.displayName, readOnly: App.configuration.toggles.signing)
            }
        } catch {
            App.shared.snackbar.show(
                error: GSError.error(description: "Failed to update selected safe", error: error))
        }
    }

}
