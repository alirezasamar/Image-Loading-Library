//
//  NSObject+Network.h
//  Pinboard
//
//  Created by Alireza Samar on 9/15/15.
//  Copyright (c) 2015 Alireza Samar. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface Network : NSObject

+ (Network *)shared;

- (void)setBaseURL:(NSString *)anURL;
- (void)setNumberOfResultsPerPage:(NSInteger)aValue;
- (void)setNumberOfCachedResults:(NSInteger)aValue;

- (void)getDataFromURL:(NSString *)anURL
 withCompletionHandler:(void (^)(NSURLResponse *response, id responseObject))completionHandler
     andFailureHandler: (void (^)(NSURLResponse *response, NSError *error))failureHandler;

- (BOOL)cancelOperationForURL:(NSString *)anURL;

- (void)searchImagesWithString:(NSString *)aString
         withCompletionHandler:(void (^)(NSURLResponse *response, id responseObject))completionHandler
             andFailureHandler: (void (^)(NSURLResponse *response, NSError *error))failureHandler;

- (void)loadMoreDataStartingOffset:(int)anOffset
             withCompletionHandler:(void (^)(NSURLResponse *response, id responseObject))completionHandler
                 andFailureHandler: (void (^)(NSURLResponse *response, NSError *error))failureHandler;


@property(nonatomic, retain) NSMutableArray *cacheArray;

@end