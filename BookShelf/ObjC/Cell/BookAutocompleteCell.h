//
//  BookAutocompleteCell.h
//  Bookshelf
//
//  Created by Den Jo on 2020/10/19.
//

#import <UIKit/UIKit.h>
#import "BookAutocomplete.h"

#define BOOK_AUTOCOMPLETE_CELL_IDENTIFIER @"BookAutocompleteCell"

@interface BookAutocompleteCell: UITableViewCell

- (void)update: (BookAutocomplete *) data;

@end
