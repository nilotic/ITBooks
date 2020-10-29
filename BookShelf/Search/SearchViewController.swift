//
//  SearchViewController.swift
//  BookShelf
//
//  Created by Den Jo on 2020/10/20.
//

import UIKit

final class SearchViewController: UIViewController {

    // MARK: - IBOutlet
    @IBOutlet private var tableView: UITableView!
    @IBOutlet private var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet private var tableViewBottomConstraint: NSLayoutConstraint!
    
    
    
    // MARK: - Value
    // MARK: Private
    private let dataManager = SearchDataManager()
    
    private lazy var searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater  = self
        searchController.delegate              = self
        searchController.searchBar.delegate    = self
        searchController.searchBar.placeholder = NSLocalizedString("Enter book name", comment: "")
        
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.sizeToFit()
        return searchController
    }()
    
    
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setSearchView()
        
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveAutocompletes(notification:)),    name: SearchNotificationName.autocompletes,     object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveUpdate(notification:)),           name: SearchNotificationName.update,            object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveKeyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveKeyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    
    // MARK: - Function
    // MARK: Private
    private func setSearchView() {
        definesPresentationContext       = true
        extendedLayoutIncludesOpaqueBars = true

        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        
        DispatchQueue.main.async {
            self.searchController.searchBar.becomeFirstResponder()
        }
    }
    
    
    
    // MARK: - Notification
    @objc private func didReceiveAutocompletes(notification: Notification) {
        DispatchQueue.main.async { self.activityIndicatorView.stopAnimating() }
        
        guard notification.object == nil else {
            Toast.show(message: (notification.object as? ResponseDetail)?.message ?? NSLocalizedString("Please check your network connection or try again.", comment: ""))
            return
        }
        
        DispatchQueue.main.async {
            self.tableView.contentOffset.y = 0
            self.tableView.reloadData()
        }
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
        if (dataManager.keyword == nil || dataManager.keyword == "") && dataManager.autocompletes.isEmpty == true {
            return .leastNormalMagnitude
        }
        
        return 35.0
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return .leastNormalMagnitude
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if (dataManager.keyword == nil || dataManager.keyword == "") && dataManager.autocompletes.isEmpty == true {
            return nil
        }
        
        let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 35.0))
        view.backgroundColor = UIColor(named: "titleBackground")
        
            
        var title: String {
            guard let data = dataManager.autocompletes.first else {
                return (dataManager.keyword != nil && dataManager.keyword != "") ? String(format: NSLocalizedString("Total %d results", comment: ""), dataManager.totalCount) : NSLocalizedString("Searched keywords", comment: "")
            }
                
            switch data {
            case is KeywordAutocomplete:    return NSLocalizedString("Searched keywords", comment: "")
            default:                        return String(format: NSLocalizedString("Total %d results", comment: ""), dataManager.totalCount)
            }
        }
        
        let label = UILabel(frame: CGRect(x: 20, y: 6.0, width: view.frame.width, height: 20.0))
        label.textColor = UIColor(named: "subtitle")
        label.font      = .systemFont(ofSize: 14.0)
        label.text      = title
        
        view.addSubview(label)
        
        let separatorView = UIView(frame: CGRect(x: 0, y: view.frame.height - 1.0, width: tableView.frame.width, height: 1.0))
        separatorView.backgroundColor = UIColor(named: "separator")
        view.addSubview(separatorView)
        
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
            searchController.searchBar.text = data.keyword
            searchController.searchBar.endEditing(true)
            
            dataManager.keyword = data.keyword
            activityIndicatorView.startAnimating()
            
            
        case let data as BookAutocomplete:
            searchController.searchBar.endEditing(true)
            DispatchQueue.main.async { self.performSegue(with: .detail, sender: data.isbn) }
            
        default:
            return
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        guard indexPath.row < dataManager.autocompletes.count else { return false }
        
        switch dataManager.autocompletes[indexPath.row] {
        case is KeywordAutocomplete:    return true
        default:                        return false
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        switch editingStyle {
        case .delete:
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                guard self.dataManager.delete(indexPath: indexPath) == true else {
                    Toast.show(message: NSLocalizedString("Sorry there has been a temporary error. Please refresh and try again.", comment: ""))
                    return
                }
            }
            
        default:
            break
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



// MARK: - UIScrollView Delegate
extension SearchViewController: UIScrollViewDelegate {
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        searchController.searchBar.endEditing(true)
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


// MARK: - UISearchResultsUpdating
extension SearchViewController: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        dataManager.keyword = searchController.searchBar.text
    }
}


// MARK: - UISearchControllerDelegate
extension SearchViewController: UISearchControllerDelegate {
    
    func willDismissSearchController(_ searchController: UISearchController) {
        searchController.searchBar.text = nil
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
        }
    }
}
