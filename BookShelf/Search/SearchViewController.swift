//
//  SearchViewController.swift
//  BookShelf
//
//  Created by Den Jo on 2020/10/20.
//

import UIKit

final class SearchViewController: UIViewController {

    // MARK: - IBOutlet
    @IBOutlet private var searchBar: UISearchBar!
    @IBOutlet private var tableView: UITableView!
    @IBOutlet private var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet private var tableViewBottomConstraint: NSLayoutConstraint!
    
    
    
    // MARK: - Value
    // MARK: Private
    private let dataManager = SearchDataManager()
    
    
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setSearchBar()
        
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveAutocompletes(notification:)),    name: SearchNotificationName.autocompletes,     object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveUpdate(notification:)),           name: SearchNotificationName.update,            object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveKeyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveKeyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        DispatchQueue.main.async {
            self.searchBar.becomeFirstResponder()
            self.dataManager.keyword = nil
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    

    // MARK: - Function
    // MARK: Private
    private func setSearchBar() {
        searchBar.placeholder  = NSLocalizedString("Enter book name", comment: "")
        searchBar.alpha = 0
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            UIView.animate(withDuration: 0.38) { self.searchBar.alpha = 1.0 }
        }
    }
    
    
    
    // MARK: - Notification
    @objc private func didReceiveAutocompletes(notification: Notification) {
        DispatchQueue.main.async { self.activityIndicatorView.stopAnimating() }
        
        guard notification.object == nil else {
            Toast.show(message: (notification.object as? ResponseDetail)?.message ?? NSLocalizedString("Please check your network connection or try again.", comment: ""))
            return
        }
        
        DispatchQueue.main.async { self.tableView.reloadData() }
    }
    
    @objc private func didReceiveUpdate(notification: Notification) {
        activityIndicatorView.stopAnimating()
        
        guard let tableViewAnimations = notification.object as? [UITableViewAnimationSet] else {
            Toast.show(message: (notification.object as? ResponseDetail)?.message ?? NSLocalizedString("Please check your network connection or try again.", comment: ""))
            return
        }
        
        tableView.beginUpdates()
        for tableViewAnimation in tableViewAnimations {
            switch tableViewAnimation.animation {
            case .insertRows:           tableView.insertRows(at: tableViewAnimation.rows,     with: tableViewAnimation.rowAnimation)
            case .insertSections:       tableView.insertSections(tableViewAnimation.sections, with: tableViewAnimation.rowAnimation)
            case .deleteRows:           tableView.deleteRows(at: tableViewAnimation.rows,     with: tableViewAnimation.rowAnimation)
            case .deleteSections:       tableView.deleteSections(tableViewAnimation.sections, with: tableViewAnimation.rowAnimation)
            case .reloadRows:           tableView.reloadRows(at: tableViewAnimation.rows,     with: tableViewAnimation.rowAnimation)
            case .reloadSections:       tableView.reloadSections(tableViewAnimation.sections, with: tableViewAnimation.rowAnimation)
            }
        }
        tableView.endUpdates()
    }
    
    @objc private func didReceiveKeyboardWillShow(notification: Notification) {
        tableViewBottomConstraint.constant = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect ?? .zero).height
        DispatchQueue.main.async { self.view.layoutIfNeeded() }
    }
    
    @objc private func didReceiveKeyboardWillHide(notification: Notification) {
        tableViewBottomConstraint.constant = 0
        DispatchQueue.main.async { self.view.layoutIfNeeded() }
    }
}
    
    

// MARK: - UITableView
// MARK: DataSource
extension SearchViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataManager.autocompletes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row < dataManager.autocompletes.count else { return UITableViewCell() }
        
        switch dataManager.autocompletes[indexPath.row] {
        case let data as KeywordAutocomplete:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: KeywordAutocompleteCell.identifier) as? KeywordAutocompleteCell else { return UITableViewCell() }
            cell.update(data: data)
            return cell
            
        case let data as BookAutocomplete:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: BookAutocompleteCell.identifier) as? BookAutocompleteCell else { return UITableViewCell() }
            cell.update(data: data)
            return cell
            
        case is LoadingAutocomplete:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: LoadingAutocompleteCell.identifier) as? LoadingAutocompleteCell else { return UITableViewCell() }
            cell.update()
            return cell
            
        default:
            return UITableViewCell()
        }
    }
}

// MARK: Delegate
extension SearchViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return dataManager.autocompletes.isEmpty == false ? 35.0 : .leastNormalMagnitude
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return .leastNormalMagnitude
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard dataManager.autocompletes.isEmpty == false else { return nil }
        
        let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 35.0))
        view.backgroundColor = UIColor(named: "titleBackground")
        
        let label = UILabel(frame: CGRect(x: 20, y: 6.0, width: view.frame.width, height: 20.0))
        label.textColor = UIColor(named: "subtitle")
        label.font      = .systemFont(ofSize: 14.0)
        label.text      = dataManager.autocompletes.first is KeywordAutocomplete ? NSLocalizedString("Searched keywords", comment: "") : String(format: NSLocalizedString("Total %d results", comment: ""), dataManager.totalCount)
        
        view.addSubview(label)
        return view
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard cell is LoadingAutocompleteCell else { return }
        dataManager.requestNextPage()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row < dataManager.autocompletes.count else { return }
        
        switch dataManager.autocompletes[indexPath.row] {
        case let data as KeywordAutocomplete:
            searchBar.text = data.keyword
            searchBar.endEditing(true)
            
            dataManager.keyword = data.keyword
            activityIndicatorView.startAnimating()
            
            
        case let data as BookAutocomplete:
            DispatchQueue.main.async { self.performSegue(with: .detail, sender: data.isbn) }
            
        default:
            return
        }
    }
}


// MARK: Prefetching
extension SearchViewController: UITableViewDataSourcePrefetching {
    
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            guard indexPath.row < dataManager.autocompletes.count else { continue }
            
            switch dataManager.autocompletes[indexPath.row] {
            case let data as BookAutocomplete:  ImageDataManager.shared.download(url: ImageURL(url: data.imageURL, hash: hash))
            case is LoadingAutocomplete:        dataManager.requestNextPage()
            default:                            continue
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            guard indexPath.row < dataManager.autocompletes.count else { continue }
            
            switch dataManager.autocompletes[indexPath.row] {
            case let data as BookAutocomplete:  ImageDataManager.shared.cancelDownload(url: ImageURL(url: data.imageURL, hash: hash))
            default:                            continue
            }
        }
    }
}



// MARK: - UISearchBarDelegate
extension SearchViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        dataManager.keyword = searchBar.text
        activityIndicatorView.startAnimating()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.endEditing(true)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.endEditing(true)
    }
}



// MARK: - Segue
extension SearchViewController: SegueHandlerType {
    
    // MARK: Enum
    enum SegueIdentifier: String {
        case detail = "DetailSegue"
    }
    
    
    // MARK: Prepare for segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let segueIdentifier = segueIdentifier(with: segue) else {
            log(.error, "Failed to get a segueIdentifier.")
            return
        }
        
        switch segueIdentifier {
        case .detail:
            guard let viewController = segue.destination as? DetailViewController else {
                log(.error, "Failed to get the DetailViewController.")
                return
            }
            
            viewController.dataManager.isbn = sender as? String
            
            // Cache
            dataManager.cache()
        }
    }
}
