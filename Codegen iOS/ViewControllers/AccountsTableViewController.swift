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
    
    var _realm: Realm?
    var realm: Realm {
        guard let realm = self._realm else {
            fatalError("Realm has not yet been set up.")
        }
        
        return realm
    }
    
    var _store: OTPAccountStore?
    var store: OTPAccountStore {
        guard let store = self._store else {
            fatalError("There is no OTPAccountStore yet.")
        }
        
        return store
    }
    
    var token: NotificationToken?
    
    var timer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.leftBarButtonItem = self.editButtonItem
        
        do {
            let realm = try Realm()
            _realm = realm
            
            let store = try OTPAccountStore.defaultStore(in: realm)
            _store = store
            
            token = store.accounts.addNotificationBlock{ [weak self] in
                self?.accountsDidChange(change: $0)
            }
        } catch let error {
            fatalError("Failed to open to Realm file: \(error)")
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        createTimer()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        destroyTimer()
    }
    
    deinit {
        destroyTimer()
    }
    
    @IBAction func didPressAdd(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "presentAddManual", sender: nil)
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
            
            tableView.deleteRows(at: deletions.map { IndexPath(row: $0, section: 0) }, with: UITableViewRowAnimation.automatic)
            tableView.insertRows(at: insertions.map { IndexPath(row: $0, section: 0) }, with: UITableViewRowAnimation.automatic)
            tableView.reloadRows(at: modifications.map { IndexPath(row: $0, section: 0) }, with: UITableViewRowAnimation.automatic)
            
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
        
        if isEditing {
            // Editing - hide progress view and increment button
            forEachVisibleCell { (cell, account) in
                cell.progressView.isHidden = true
                cell.incrementButton.isHidden = true
                cell.codeLabel.text = account.formattedPassword(obfuscated: true)
            }
        } else {
            // Not editing - show controls and code
            forEachVisibleCell { (cell, account) in
                cell.progressView.isHidden = !account.timeBased
                cell.incrementButton.isHidden = account.timeBased
                cell.codeLabel.text = account.formattedPassword()
            }
            
            // Update progress views
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
        let fromRow = fromIndexPath.row
        let toRow = to.row
        
        // Move Object
        
        do {
            realm.beginWrite()
            
            store.accounts.move(from: fromRow, to: toRow)
            
            // Commit write transaction without notifying token
            let tokens = token.map { [$0] } ?? []
            try realm.commitWrite(withoutNotifying: tokens)
        } catch let error {
            print("Failed to move: \(error)")
            
            // Reload data in view when model failed to update
            tableView.reloadData()
        }
    }
}
