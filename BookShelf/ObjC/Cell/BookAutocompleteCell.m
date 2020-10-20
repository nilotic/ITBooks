//
//  BookAutocompleteCell.m
//  Bookshelf
//
//  Created by Den Jo on 2020/10/19.
//

#import "BookAutocompleteCell.h"
#import "Bookshelf-Swift.h"

@interface BookAutocompleteCell()

// MARK: - IBOutlet
@property (strong, nonatomic) IBOutlet UIImageView *bookImageView;
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UILabel *subtitleLabel;
@property (strong, nonatomic) IBOutlet UILabel *isbnLabel;
@property (strong, nonatomic) IBOutlet UILabel *price;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicatorView;


// MARK: - Value
@property (strong, nonatomic, nullable) NSURL *imageURLCache;

@end


@implementation BookAutocompleteCell

// MARK: - View Life Cycle
- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.imageView.image = nil;
    [[ImageDataManager shared] cancelDownloadWithUrl: self.imageURLCache];
}



// MARK: - Function
- (void)update: (BookAutocomplete *) data {
    // Image
    self.imageURLCache = data.imageURL;  // Cache

    [self.activityIndicatorView startAnimating];
    [[ImageDataManager shared] downloadWithUrl: data.imageURL completion:^(NSURL * _Nullable url, UIImage * _Nullable image) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self == nil) {
                return;
            }
        
            [self.activityIndicatorView stopAnimating];
            
            if (url == nil) {
                return;
            }
            
            if (self.imageURLCache.hash == url.hash) {
                self.imageView.image = image;
                
            } else {
                self.imageView.image = nil;
            }
        });
    }];
    
    
    // Info
    self.titleLabel.text    = data.title;
    self.subtitleLabel.text = data.subtitle;
    self.isbnLabel.text     = data.isbn;
    self.price.text         = data.price;
}

@end
