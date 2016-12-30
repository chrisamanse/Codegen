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
    @IBOutlet var moreBarButtonItem: UIBarButtonItem!
    @IBOutlet var flexibleBarButtonItem: UIBarButtonItem!
    @IBOutlet var addBarButtonItem: UIBarButtonItem!
    @IBOutlet var exportBarButtonItem: UIBarButtonItem!
    @IBOutlet var exportAllBarButtonItem: UIBarButtonItem!
    @IBOutlet var trashBarButtonItem: UIBarButtonItem!
    @IBOutlet var trashAllBarButtonItem: UIBarButtonItem!
    
    var realm: Realm!
    var store: OTPAccountStore!
    var token: NotificationToken?
    
    var timer: Timer?
    
    var editingWithNoneSelectedButtons: [UIBarButtonItem] {
        return [exportAllBarButtonItem, flexibleBarButtonItem, trashAllBarButtonItem]
    }
    var editingWithSelectedButtons: [UIBarButtonItem] {
        return [exportBarButtonItem, flexibleBarButtonItem, trashBarButtonItem]
    }
    var notEditingButtons: [UIBarButtonItem] {
        return [moreBarButtonItem, flexibleBarButtonItem, addBarButtonItem]
    }
    
    var exportAccounts: [OTPAccount] = []
    
    var selectedAccounts: [OTPAccount] {
        let indexPaths = tableView.indexPathsForSelectedRows ?? []
        
        return indexPaths.map { store.accounts[$0.row] }
    }
    
    var allAccounts: [OTPAccount] {
        return store.accounts.map { $0 }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = editButtonItem
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive(_:)), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground(_:)), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        
        do {
            realm = try Realm()
            store = try OTPAccountStore.defaultStore(in: realm)
            
            token = store.accounts.addNotificationBlock{ [weak self] in
                self?.accountsDidChange(change: $0)
            }
        } catch let error {
            fatalError("Failed to open to Realm file: \(error)")
        }
        
        createTimer()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.isToolbarHidden = false
    }
    
    func applicationDidBecomeActive(_ notification: NSNotification) {
        tableView.reloadData()
        
        if !isEditing {
            createTimer()
        }
    }
    
    func applicationDidEnterBackground(_ notification: NSNotification) {
        destroyTimer()
    }
    
    deinit {
        destroyTimer()
    }
    
    @IBAction func didPressAdd(_ sender: UIBarButtonItem) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let scanAction = UIAlertAction(title: AppStrings.scan, style: .default) { [unowned self] _ in
            self.performSegue(withIdentifier: "presentAddScan", sender: nil)
        }
        let manualAction = UIAlertAction(title: AppStrings.manual, style: .default) { [unowned self] _ in
            self.performSegue(withIdentifier: "presentAddManual", sender: nil)
        }
        let cancelAction = UIAlertAction(title: AppStrings.cancel, style: .cancel)
        
        actionSheet.addAction(scanAction)
        actionSheet.addAction(manualAction)
        actionSheet.addAction(cancelAction)
        
        present(actionSheet, animated: true)
    }
    
    @IBAction func didPressTrash(_ sender: UIBarButtonItem) {
        delete(accounts: selectedAccounts)
        
        updateToolbarItems()
    }
    
    @IBAction func didPressTrashAll(_ sender: UIBarButtonItem) {
        let confirmAlert = UIAlertController(title: AppStrings.Alerts.DeleteAll.title, message: AppStrings.Alerts.DeleteAll.message, preferredStyle: .alert)
        
        let cancel = UIAlertAction(title: AppStrings.cancel, style: .cancel)
        let delete = UIAlertAction(title: AppStrings.delete, style: .destructive) { [unowned self] _ in
            self.delete(accounts: self.allAccounts)
            
            self.updateToolbarItems()
        }
        
        confirmAlert.addAction(cancel)
        confirmAlert.addAction(delete)
        
        present(confirmAlert, animated: true)
    }
    
    @IBAction func didPressExport(_ sender: UIBarButtonItem) {
        let accounts = sender == exportAllBarButtonItem ? allAccounts : selectedAccounts
        
        export(accounts: accounts)
    }
    
    func createTimer() {
        guard self.timer == nil else {
            return
        }
        
        // Get date for next second for precise tick
        let now = Date()
        let incremented = round(now.timeIntervalSince1970) + 1
        let next = Date(timeIntervalSince1970: incremented)
        
        let timer = Timer(fire: next, interval: 1.0, repeats: true, block: didTick(timer:))
        
        RunLoop.main.add(timer, forMode: .commonModes)
        
        self.timer = timer
    }
    
    func destroyTimer() {
        timer?.invalidate()
        
        timer = nil
    }
    
    func updateVisibleCells() {
        guard let indexPaths = tableView.indexPathsForVisibleRows else { return }
        
        for indexPath in indexPaths {
            guard (0 ..< store.accounts.count).contains(indexPath.row) else { continue }
            guard let cell = tableView.cellForRow(at: indexPath) as? AccountTableViewCell else { continue }
            
            configure(cell: cell, with: store.accounts[indexPath.row])
        }
    }
    
    func didTick(timer: Timer) {
        updateVisibleCells()
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
    
    func delete(accounts: [OTPAccount]) {
        guard accounts.count > 0 else { return }
        
        do {
            try realm.write {
                realm.delete(accounts)
            }
        } catch let error {
            print("Failed to delete account: \(error)")
            
            tableView.reloadData()
        }
    }
    
    func export(accounts: [OTPAccount]) {
        exportAccounts = accounts
        
        performSegue(withIdentifier: SegueIdentifiers.showExport, sender: nil)
    }
    
    func updateToolbarItems() {
        let buttons: [UIBarButtonItem]
        
        if tableView.isEditing {
            let noSelection = tableView.indexPathsForSelectedRows.map { $0.isEmpty } ?? true
            
            if noSelection {
                buttons = editingWithNoneSelectedButtons
            } else {
                buttons = editingWithSelectedButtons
            }
        } else {
            buttons = notEditingButtons
        }
        
        setToolbarItems(buttons, animated: true)
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
        
        updateToolbarItems()
        updateVisibleCells()
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
        configure(cell: cell, with: account)
        
        return cell
    }
    
    func configure(cell: AccountTableViewCell, with account: OTPAccount) {
        cell.issuerLabel.text = account.issuer
        cell.accountLabel.text = account.account
        cell.codeLabel.text = account.formattedPassword(obfuscated: cell.isEditing)
        
        // Set progress
        if account.timeBased {
            let timeInterval = UInt64(round(Date().timeIntervalSince1970))
            let timeLeft = UInt64(account.period) - (timeInterval % UInt64(account.period))
            
            cell.progressView.progress = Float(Double(timeLeft) / account.period)
        } else {
            // Counter based
            cell.pressIncrementHandler = { [unowned self] in
                do {
                    try self.realm.write {
                        account.counter = account.counter &+ 1
                    }
                } catch let error {
                    print("Failed to increment counter: \(error)")
                    
                    self.configure(cell: cell, with: account)
                }
            }
            
            // Only enable the increment counter button after 1 second
            cell.incrementButton.isEnabled = false
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [weak cell] _ in
                cell?.incrementButton.isEnabled = true
            }
        }
        
        // Hide both when editing
        cell.progressView.isHidden = tableView.isEditing ? true : !account.timeBased
        cell.incrementButton.isHidden = tableView.isEditing ? true : account.timeBased
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let account = store.accounts[indexPath.row]
            
            delete(accounts: [account])
        }
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
        do {
            realm.beginWrite()
            
            store.accounts.move(from: fromIndexPath.row, to: to.row)
            
            let tokens = token.map { [$0] } ?? []
            try realm.commitWrite(withoutNotifying: tokens)
        } catch let error {
            print("Failed to move: \(error)")
            
            tableView.reloadData()
        }
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        updateToolbarItems()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView.isEditing {
            updateToolbarItems()
        } else {
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
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == SegueIdentifiers.showExport {
            let exportVC = segue.destination as! ExportViewController
            
            exportVC.accounts = exportAccounts
            
            exportAccounts = []
        }
    }
}

extension AccountsTableViewController {
    enum SegueIdentifiers {
        static let showExport = "showExport"
    }
}
