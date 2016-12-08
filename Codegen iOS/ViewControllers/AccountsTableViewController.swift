//
//  AccountsTableViewController.swift
//  Codegen
//
//  Created by Chris Amanse on 09/30/2016.
//
//

import UIKit
import RealmSwift

class AccountsTableViewController: UITableViewController {
    var realm: Realm!
    var store: OTPAccountStore!
    var token: NotificationToken?
    
    var timer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.leftBarButtonItem = self.editButtonItem
        
        do {
            realm = try Realm()
            store = try OTPAccountStore.defaultStore(in: realm)
            
            token = store.accounts.addNotificationBlock{ [weak self] in
                self?.accountsDidChange(change: $0)
            }
        } catch let error {
            fatalError("Failed to open to Realm file: \(error)")
        }
    }
    
    func applicationDidBecomeActive(_ notification: NSNotification) {
        tableView.reloadData()
        
        createTimer()
    }
    
    func applicationDidEnterBackground(_ notification: NSNotification) {
        destroyTimer()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Add observers
        registerObservers()
        
        tableView.reloadData()
        
        createTimer()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        destroyTimer()
        
        // Remove observers
        unregisterObservers()
    }
    
    deinit {
        destroyTimer()
    }
    
    @IBAction func didPressAdd(_ sender: UIBarButtonItem) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let scanAction = UIAlertAction(title: "Scan", style: .default) { [unowned self] _ in
            self.performSegue(withIdentifier: "presentAddScan", sender: nil)
        }
        let manualAction = UIAlertAction(title: "Manual", style: .default) { [unowned self] _ in
            self.performSegue(withIdentifier: "presentAddManual", sender: nil)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        actionSheet.addAction(scanAction)
        actionSheet.addAction(manualAction)
        actionSheet.addAction(cancelAction)
        
        self.present(actionSheet, animated: true)
    }
    
    func registerObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive(_:)), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground(_:)), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
    }
    
    func unregisterObservers() {
        NotificationCenter.default.removeObserver(self)
    }
    
    func createTimer() {
        guard self.timer == nil else {
            return
        }
        
        // Get date for next second for precise tick
        let now = Date()
        let incremented = round(now.timeIntervalSince1970) + 1
        let next = Date(timeIntervalSince1970: incremented)
        
        // Create timer with fire date for next second
        let timer = Timer(fire: next, interval: 1.0, repeats: true, block: self.didTick(timer:))
        
        self.timer = timer
        
        // Add timer to main run loop for common modes
        RunLoop.main.add(timer, forMode: .commonModes)
    }
    
    func destroyTimer() {
        timer?.invalidate()
        
        timer = nil
    }
    
    func forEachVisibleCell(body: (AccountTableViewCell, OTPAccount) throws -> Void) rethrows {
        let indexPaths = tableView.indexPathsForVisibleRows ?? []
        let lazy = indexPaths.lazy
        let accounts = lazy.map { indexPath -> OTPAccount? in
            let index = indexPath.row
            guard (0 ..< self.store.accounts.count).contains(index) else {
                return nil
            }
            
            return self.store.accounts[index]
        }
        
        let cells = lazy.map { self.tableView.cellForRow(at: $0) as? AccountTableViewCell }
        
        for i in 0 ..< indexPaths.count {
            guard let account = accounts[i] else {
                print("NO ACCOUNT IN VISIBLE INDEXPATH")
                continue
            }
            guard let cell = cells[i] else {
                print("NO CELL IN VISIBLE INDEXPATH")
                continue
            }
            
            try body(cell, account)
        }
    }
    
    func updateProgressViews(for date: Date) {
        let timeInterval = UInt64(round(date.timeIntervalSince1970))
        
        #if DEBUG
            print("Did tick:\n  - \(date)\n  - \(date.timeIntervalSince1970)")
            print("Time left (30s period): \(30 - (timeInterval % 30))")
        #endif
        
        // Cache progress for period to avoid recomputation
        var progressForPeriod = [TimeInterval: Float]()
        
        forEachVisibleCell { (cell, account) in
            // Skip cell if not time based
            guard account.timeBased else {
                return
            }
            guard let period = account.period else {
                fatalError("NO PERIOD SET")
            }
            
            // Compute progress
            let progress: Float
            
            if let cachedProgress = progressForPeriod[period] {
                progress = cachedProgress
            } else {
                let timeLeft = UInt64(period) - (timeInterval % UInt64(period))
                progress = Float(Double(timeLeft) / period)
                
                // Save progress to cache
                progressForPeriod[period] = progress
            }
            
            // Update cell
            cell.progressView.progress = progress
            
            // Password is now different
            if progress == 1 {
                cell.codeLabel.text = account.formattedPassword()
            }
        }
    }
    
    func didTick(timer: Timer) {
        updateProgressViews(for: timer.fireDate)
    }
    
    func incrementCounter(of account: OTPAccount) {
        guard let counter = account.counter else {
            fatalError("NO COUNTER SET")
        }
        
        do {
            try self.realm.write {
                account.counter = counter &+ 1
            }
        } catch let error {
            print("Failed to increment counter: \(error)")
        }
    }
    
    func accountsDidChange(change: RealmCollectionChange<List<OTPAccount>>) {
        switch change {
        case .initial(_):
            tableView.reloadData()
        case .update(_, deletions: let deletions, insertions: let insertions, modifications: let modifications):
            print("Deletions: \(deletions)")
            print("Insertions: \(insertions)")
            print("Modifications: \(modifications)")
            
            tableView.beginUpdates()
            
            tableView.deleteRows(at: deletions.map { IndexPath(row: $0, section: 0) }, with: .automatic)
            tableView.insertRows(at: insertions.map { IndexPath(row: $0, section: 0) }, with: .automatic)
            tableView.reloadRows(at: modifications.map { IndexPath(row: $0, section: 0) }, with: .automatic)
            
            tableView.endUpdates()
        case .error(let error):
            print("Error: \(error)")
        }
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        if editing {
            // Did start editing
            destroyTimer()
        } else {
            // Did end editing
            createTimer()
        }
        
        // Show/Hide controls based on editing and time based
        forEachVisibleCell { (cell, account) in
            cell.progressView.isHidden = editing ? true : !account.timeBased
            cell.incrementButton.isHidden = editing ? true : account.timeBased
            cell.codeLabel.text = account.formattedPassword(obfuscated: editing)
        }
        
        if !editing {
            // Update progress views if done editing
            updateProgressViews(for: Date())
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        // Make sure to reload the data whenever the trait collection changes
        tableView.reloadData()
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return store.accounts.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "accountCell", for: indexPath) as? AccountTableViewCell else {
            fatalError("Cell is not an AccountTableViewCell.")
        }
        
        // Get object
        let account = store.accounts[indexPath.row]
        
        // Configure the cell...
        cell.issuerLabel.text = account.issuer
        cell.accountLabel.text = account.account
        cell.codeLabel.text = account.formattedPassword(obfuscated: cell.isEditing)
        
        // Set progress
        if account.timeBased {
            guard let period = account.period else {
                fatalError("NO PERIOD SET")
            }
            
            let timeInterval = UInt64(round(Date().timeIntervalSince1970))
            let timeLeft = UInt64(period) - (timeInterval % UInt64(period))
            
            cell.progressView.progress = Float(Double(timeLeft) / period)
        } else {
            // Counter based
            cell.pressIncrementHandler = { [unowned self] in
                self.incrementCounter(of: account)
            }
            
            // Only enable the increment counter button after 1 second
            cell.incrementButton.isEnabled = false
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
                cell.incrementButton.isEnabled = true
            }
        }
        
        // Hide both when editing
        cell.progressView.isHidden = tableView.isEditing ? true : !account.timeBased
        cell.incrementButton.isHidden = tableView.isEditing ? true : account.timeBased
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return tableView.isEditing ? .delete : .none
    }
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete object
            do {
                try realm.write {
                    realm.delete(store.accounts[indexPath.row])
                }
            } catch let error {
                print("Failed to delete account: \(error)")
            }
        }
    }
    
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
        // Move Object
        do {
            realm.beginWrite()
            
            store.accounts.move(from: fromIndexPath.row, to: to.row)
            
            // Commit write transaction without notifying token
            let tokens = token.map { [$0] } ?? []
            try realm.commitWrite(withoutNotifying: tokens)
        } catch let error {
            print("Failed to move: \(error)")
            
            // Reload data in view when model failed to update
            tableView.reloadData()
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let account = store.accounts[indexPath.row]
        
        do {
            let password = try account.currentPassword()
            
            Pasteboard.general.string = password
        } catch let error {
            print("Failed to get password: \(error)")
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
