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
    
    var shouldIgnoreRealmNotification = false
    
    var timer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.leftBarButtonItem = self.editButtonItem
        
        do {
            let realm = try Realm()
            _realm = realm
            
            let store = try OTPAccountStore.defaultStore(in: realm)
            _store = store
            
            token = store.accounts.addNotificationBlock(accountsDidChange(change:))
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
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        destroyTimer()
    }
    
    @IBAction func didPressAdd(_ sender: UIBarButtonItem) {
        let account = OTPAccount()
        
        account.issuer = "Apple \(Date())"
        account.account = "chris@chrisamanse.xyz"
        account.timeBased = true
        account.period = 30
        
        do {
            try realm.write {
                store.accounts.insert(account, at: 0)
            }
        } catch let error {
            print("Failed to add account: \(error)")
        }
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
    
    func didTick(timer: Timer) {
        let now = timer.fireDate
        print("Did tick:\n  - \(now)\n  - \(now.timeIntervalSince1970)")
        
        let timeInterval = UInt64(round(now.timeIntervalSince1970))
        
        print("Time left (30s period): \(30 - (timeInterval % 30))")
        
        // Update progress views
        var progressForPeriod = [TimeInterval: Float]() // Cached progresses
        
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
            guard account.timeBased else {
                print("Not a time based, skip update")
                continue
            }
            guard let period = account.period else {
                fatalError("NO PERIOD SET")
                continue
            }
            guard let cell = cells[i] else {
                print("NO CELL IN VISIBLE INDEXPATH")
                continue
            }
            
            let progress: Float
            
            // Check cached progress for a period to skip recomputation
            if let cachedProgress = progressForPeriod[period] {
                progress = cachedProgress
            } else {
                let timeLeft = UInt64(period) - (timeInterval % UInt64(period))
                progress = Float(Double(timeLeft) / period)
                
                // Save to cache
                progressForPeriod[period] = progress
            }
            
            // Update progress view
            cell.progressView.progress = progress
            
            // If progress is 1, it means password has changed
            if progress == 1 {
                cell.codeLabel.text = account.formattedPassword()
            }
        }
    }
    
    func accountsDidChange(change: RealmCollectionChange<List<OTPAccount>>) {
        switch change {
        case .initial(_):
            tableView.reloadData()
        case .update(_, deletions: let deletions, insertions: let insertions, modifications: let modifications):
            if shouldIgnoreRealmNotification {
                print("Ignoring Realm notification")
                shouldIgnoreRealmNotification = false
                break
            }
            
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
        let timeInterval = UInt64(round(Date().timeIntervalSince1970))
        
        super.setEditing(editing, animated: animated)
        
        if editing {
            // Did start editing
            destroyTimer()
        } else {
            // Did end editing
            createTimer()
        }
        
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
        
        // Update progress views
        var progressForPeriod = [TimeInterval: Float]() // Cached progresses
        
        // Show/Hide progress view and increment counter button, and obfuscate code
        for i in 0 ..< indexPaths.count {
            guard let account = accounts[i] else {
                print("NO ACCOUNT IN VISIBLE INDEXPATH")
                continue
            }
            guard let cell = cells[i] else {
                print("NO CELL IN VISIBLE INDEXPATH")
                continue
            }
            
            let isHidden: (progressView: Bool, incrementButton: Bool)
            
            switch (editing, account.timeBased) {
            case (true, _):
                // Editing - hide
                isHidden.progressView = true
                isHidden.incrementButton = true
            case (false, true):
                // Ended editing AND time based - show progress view and hide increment button
                isHidden.progressView = false
                isHidden.incrementButton = true
                
                // Update progress views
                let progress: Float
                
                guard let period = account.period else {
                    fatalError("NO PERIOD SET")
                    continue
                }
                
                // Check cached progress for a period to skip recomputation
                if let cachedProgress = progressForPeriod[period] {
                    progress = cachedProgress
                } else {
                    let timeLeft = UInt64(period) - (timeInterval % UInt64(period))
                    progress = Float(Double(timeLeft) / period)
                    
                    // Save to cache
                    progressForPeriod[period] = progress
                }
                
                // Update progress view
                cell.progressView.progress = progress
            case (false, false):
                // Ended editing AND counter based - hide progress view and show increment button
                isHidden.progressView = true
                isHidden.incrementButton = false
            }
            
            cell.progressView.isHidden = isHidden.progressView
            cell.incrementButton.isHidden = isHidden.incrementButton
            cell.codeLabel.text = account.formattedPassword(obfuscated: editing)
        }
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
        let index = indexPath.row
        guard (0 ..< store.accounts.count).contains(index) else {
            fatalError("Unexpected cell!")
        }
        
        let account = store.accounts[index]
        
        // Configure the cell...
        cell.issuerLabel.text = account.issuer
        cell.accountLabel.text = account.account
        cell.codeLabel.text = account.formattedPassword(obfuscated: cell.isEditing)
        
        let isHidden: (progressView: Bool, incrementButton: Bool)
        // Set progress
        if account.timeBased {
            guard let period = account.period else {
                fatalError("NO PERIOD SET")
            }
            
            let timeInterval = UInt64(round(Date().timeIntervalSince1970))
            let timeLeft = UInt64(period) - (timeInterval % UInt64(period))
            
            cell.progressView.progress = Float(Double(timeLeft) / period)
            
            isHidden.progressView = false
            isHidden.incrementButton = true
        } else {
            // Counter based
            cell.pressIncrementHandler = {
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
            
            // Only enable the increment counter button after 1 second
            cell.incrementButton.isEnabled = false
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
                cell.incrementButton.isEnabled = true
            }
            
            isHidden.progressView = true
            isHidden.incrementButton = false
        }
        
        if isEditing {
            // Hide both when editing
            cell.progressView.isHidden = true
            cell.incrementButton.isHidden = true
        } else {
            cell.progressView.isHidden = isHidden.progressView
            cell.incrementButton.isHidden = isHidden.incrementButton
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        if tableView.isEditing {
            return .delete
        }
        
        return .none
    }
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Get object
            let index = indexPath.row
            guard (0 ..< store.accounts.count).contains(index) else {
                fatalError("Unexpected cell!")
            }
            
            let account = store.accounts[index]
            
            // Delete object
            do {
                try realm.write {
                    realm.delete(account)
                }
            } catch let error {
                print("Failed to delete account: \(error)")
            }
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
        let fromRow = fromIndexPath.row
        let toRow = to.row
        
        // Move Object
        
        shouldIgnoreRealmNotification = true // Ignore this Realm update
        
        do {
            try realm.write {
                store.accounts.move(from: fromRow, to: toRow)
            }
        } catch let error {
            print("Failed to move: \(error)")
        }
    }
}
