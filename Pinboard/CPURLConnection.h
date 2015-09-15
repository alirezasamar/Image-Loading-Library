//
//  NSObject+CPURLConnection.h
//  Pinboard
//
//  Created by Alireza Samar on 9/15/15.
//  Copyright (c) 2015 Alireza Samar. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface CPURLConnection : NSObject <NSURLConnectionDelegate>

@property (nonatomic) NSInteger tag;
@property (nonatomic, strong) NSURLRequest *request;
@property (nonatomic, strong) NSOperationQueue *queue;
@property (nonatomic, copy) void(^completionHandler)(NSURLResponse *response, NSData *data, NSError *error);

- (void)start;
- (void)cancel;

+ (CPURLConnection *)sendAsynchronousRequestToURL:(NSString *)anURL completionHandler:(void (^)(NSURLResponse *response, NSData *data, NSError *error))completionHandler;
+ (CPURLConnection *)sendAsynchronousRequest:(NSURLRequest *)request queue:(NSOperationQueue *)queue completionHandler:(void(^)(NSURLResponse *response, NSData *data, NSError *error))completionHandler;

@end
