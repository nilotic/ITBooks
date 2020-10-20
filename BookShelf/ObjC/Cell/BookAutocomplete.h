//
//  BookAutocomplete.h
//  Bookshelf
//
//  Created by Den Jo on 2020/10/19.
//

#import <Foundation/Foundation.h>

@interface BookAutocomplete: NSObject

@property (strong, nonatomic, nonnull)  NSString *title;
@property (strong, nonatomic, nullable) NSString *subtitle;
@property (strong, nonatomic, nonnull)  NSString *price;
@property (strong, nonatomic, nonnull)  NSString *isbn;
@property (strong, nonatomic, nullable) NSURL *imageURL;
@property (strong, nonatomic, nullable) NSURL *url;

@end
