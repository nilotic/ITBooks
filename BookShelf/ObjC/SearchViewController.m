//
//  SearchViewController.m
//  Bookshelf
//
//  Created by Den Jo on 2020/10/19.
//

#import "SearchViewController.h"
#import "Bookshelf-Swift.h"
#import "BookAutocompleteCell.h"

// MARK: - Define
#define DETAIL_SEGUE_IDENTIFIER     @"DetailSegue"
#define AUTUCOMPLETES_NOTIFICATION  @"AutocompletesNotification"


@interface SearchViewController () <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate>

// MARK: - IBOutlet
@property (strong, nonatomic) IBOutlet UISearchBar *searchBar;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicatorView;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *tableViewBottomConstraint;


// MARK: - Value
@property (strong, nonatomic) SearchDataManager *dataManager;

@end



@implementation SearchViewController


// MARK: - View Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"SearchViewController");
    
    self.dataManager = [[SearchDataManager alloc] init];
    [self setSearchBar];
    
    // Notification
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(didReceiveAutocompletesNotification:)    name: AUTUCOMPLETES_NOTIFICATION     object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(didReceiveKeyboardWillShowNotification:) name: UIKeyboardWillShowNotification object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(didReceiveKeyboardWillHideNotification:) name: UIKeyboardWillHideNotification object: nil];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.searchBar becomeFirstResponder];
    });
}



// MARK: - Function
- (void)setSearchBar {
    self.searchBar.placeholder = NSLocalizedString(@"Enter book name", comment: "");
    self.searchBar.alpha       = 0;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.38 animations:^{
            self.searchBar.alpha = 1.0;
        }];
    });
}



// MARK: - Notification
- (void)didReceiveAutocompletesNotification: (NSNotification*) notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.activityIndicatorView stopAnimating];
    });
    
    if (notification.object != nil) {
        [Toast showWithMessage: notification.object];
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

- (void)didReceiveKeyboardWillShowNotification: (NSNotification*) notification {
    CGFloat height = [[[notification userInfo] objectForKey: UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;
    self.tableViewBottomConstraint.constant = height;

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.view layoutIfNeeded];
    });
}

- (void)didReceiveKeyboardWillHideNotification: (NSNotification*) notification {
    self.tableViewBottomConstraint.constant = 0;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.view layoutIfNeeded];
    });
}



// MARK: - TableView DataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection: (NSInteger)section {
    return self.dataManager.autocompletes.count;
}

- (nonnull UITableViewCell *)tableView: (nonnull UITableView *)tableView cellForRowAtIndexPath: (nonnull NSIndexPath *)indexPath {
    BookAutocompleteCell *cell = [tableView dequeueReusableCellWithIdentifier: BOOK_AUTOCOMPLETE_CELL_IDENTIFIER forIndexPath: indexPath];
     
    if (indexPath.row < self.dataManager.autocompletes.count) {
        [cell update: self.dataManager.autocompletes[indexPath.row]];
    
    } else {
        NSLog(@"Error: Failed to get data.");
    }
    
    return cell;
}



// MARK: - TableView Delegate
- (void)tableView: (UITableView *)tableView didSelectRowAtIndexPath: (NSIndexPath *)indexPath {
    if ((indexPath == nil) || (self.dataManager.autocompletes.count <= indexPath.row)) {
        NSLog(@"Error: Invalid indexPath.");
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self performSegueWithIdentifier: DETAIL_SEGUE_IDENTIFIER sender: self.dataManager.autocompletes[indexPath.row]];
    });
}



// MARK: - UISearchBar Delegate
- (void)searchBar:(UISearchBar *)searchBar textDidChange: (NSString *)searchText {
    [self.dataManager requestWithKeyword: searchText];
    [self.activityIndicatorView startAnimating];
    
}

- (void)searchBarCancelButtonClicked: (UISearchBar *)searchBar {
    [self.view endEditing: true];
}

@end
