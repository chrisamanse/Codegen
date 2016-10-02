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
            
            tableView.reloadData()
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
        let timeLeft = 30 - (timeInterval % 30)
        let shouldUpdatePasswords = timeLeft == 30
        
        print("Time left: \(timeLeft)")
        
        if shouldUpdatePasswords {
            print("Updating passwords...")
            tableView.beginUpdates()
            
            tableView.reloadRows(at: tableView.indexPathsForVisibleRows ?? [], with: .automatic)
            
            tableView.endUpdates()
        }
    }
    
    func accountsDidChange(change: RealmCollectionChange<List<OTPAccount>>) {
        switch change {
        case .initial(_):
            print("Initial query")
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
        
        // Format password
        let password = (try? account.currentPassword()) ?? String(repeating: "•", count: account.digits)
        
        cell.codeLabel.text = password.split(by: 3).joined(separator: " ")
        
        return cell
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */
    
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
    
    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
