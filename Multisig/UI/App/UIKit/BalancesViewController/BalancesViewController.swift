//
//  BalancesViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 22.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit
import Kingfisher

// Loads and displays balances
class BalancesViewController: LoadableViewController, UITableViewDelegate, UITableViewDataSource {

    var currentDataTask: URLSessionTask?
    var results: [TokenBalance] = []
    var totalBalance: String = "0.00"
    var lastError: Error?

    override var isEmpty: Bool { results.isEmpty }

    let rowHeight: CGFloat = 60
    let tableBackgroundColor: UIColor = .gnoWhite
    let totalCellIndex = 0

    var clientGatewayService = App.shared.clientGatewayService
    var notificationCenter = NotificationCenter.default

    convenience init() {
        self.init(namedClass: Self.superclass())
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.registerCell(BalanceTableViewCell.self)
        tableView.registerCell(TotalBalanceTableViewCell.self)

        tableView.allowsSelection = false
        tableView.rowHeight = rowHeight
        tableView.backgroundColor = tableBackgroundColor

        tableView.delegate = self
        tableView.dataSource = self

        emptyView.setText("Balances will appear here")

        notificationCenter.addObserver(self, selector: #selector(didChangeSafe), name: .selectedSafeChanged, object: nil)
    }

    @objc func didChangeSafe() {
        let isOnScreen = viewIfLoaded?.window != nil
        if isOnScreen {
            reloadData()
        } else {
            // Save battery and network requests if the view is off-screen
            setNeedsReload()
        }
    }

    override func reloadData() {
        super.reloadData()
        currentDataTask?.cancel()
        do {
            // get selected safe
            let safe = try Safe.getSelected()

            // get its address
            guard let string = safe?.address else {
                throw "Selected safe does not have a stored address"
            }
            let address = try Address(from: string)

            currentDataTask = clientGatewayService.asyncBalances(address: address) { [weak self] result in
                guard let `self` = self else { return }
                switch result {
                case .failure(let error):
                    DispatchQueue.main.async { [weak self] in
                        guard let `self` = self else { return }
                        // ignore cancellation error due to cancelling the
                        // currently running task. Otherwise user will see
                        // meaningless message.
                        if (error as NSError).code == URLError.cancelled.rawValue &&
                            (error as NSError).domain == NSURLErrorDomain {
                            return
                        }
                        self.lastError = error
                        self.onError()
                    }
                case .success(let summary):
                    let results = summary.items.map(TokenBalance.init)
                    let total = TokenBalance.displayCurrency(from: summary.fiatTotal)
                    DispatchQueue.main.async { [weak self] in
                        guard let `self` = self else { return }
                        self.results = results
                        self.totalBalance = total
                        self.onSuccess()
                    }
                }
            }
        } catch {
            lastError = error
            onError()
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        results.count + 1 /* for total cell */
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == totalCellIndex {
            let cell = tableView.dequeueCell(TotalBalanceTableViewCell.self, for: indexPath)
            cell.setMainText("Total")
            cell.setDetailText(totalBalance)
            return cell
        } else {
            let item = results[indexPath.row - 1]
            let cell = tableView.dequeueCell(BalanceTableViewCell.self, for: indexPath)
            cell.setMainText(item.symbol)
            cell.setDetailText(item.balance)
            cell.setSubDetailText(item.balanceUsd)
            cell.setImage(with: item.imageURL, placeholder: #imageLiteral(resourceName: "ico-token-placeholder"))
            return cell
        }
    }
}