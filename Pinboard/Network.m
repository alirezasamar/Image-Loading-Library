//
//  NSObject+Network.m
//  Pinboard
//
//  Created by Alireza Samar on 9/15/15.
//  Copyright (c) 2015 Alireza Samar. All rights reserved.
//

#import "Network.h"
#import "NSData+MD5.h"
#import "NSString+MD5.h"
#import "CPURLConnection.h"

#define kNumberOfResultsPerPage 8
#define kNumberOfCachedResults 20

@implementation Network {
    NSInteger numberOfResultsPerPage;
    NSInteger numberOfCachedResults;
    NSMutableDictionary *operationsQueue;
    NSString *baseURL;
    NSString *queryString;
}

#pragma mark -
#pragma mark Singleton and init stuff
#pragma mark -

+ (Network *)shared
{
    static Network *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[Network alloc] init];
    });
    return shared;
}

- (id)init {
    if (self = [super init]) {
        baseURL = nil;
        queryString = nil;
        numberOfCachedResults = kNumberOfCachedResults;
        numberOfResultsPerPage = kNumberOfResultsPerPage;
        operationsQueue = [NSMutableDictionary new];
        _cacheArray = [NSMutableArray new];
    }
    return self;
}

#pragma mark -
#pragma mark Class Configuration methods
#pragma mark -

- (void)setNumberOfResultsPerPage:(NSInteger)aValue {
    numberOfResultsPerPage = aValue;
}

- (void)setNumberOfCachedResults:(NSInteger)aValue {
    numberOfCachedResults = aValue;
}

- (void)emptyCache {
    [_cacheArray removeAllObjects];
}

- (void)setBaseURL:(NSString *)anURL {
    baseURL = anURL;
}

#pragma mark -
#pragma mark Getter/Setter methods for Cache objects
#pragma mark -

- (void)addDatatoCache:(NSData *)aData withKey:(NSString *)aKey {
    if(_cacheArray.count > numberOfCachedResults-1) {
        [_cacheArray removeObject:[_cacheArray firstObject]];
    }
    [_cacheArray addObject:@{@"key":aKey, @"data":aData}];
}

- (BOOL)cacheContainsObjectWithKey:(NSString *)aKey {
    for(NSDictionary *anObject in _cacheArray) {
        if([anObject[@"key"] isEqualToString:aKey])
            return TRUE;
    }
    return FALSE;
}

- (id)cachedObjectForKey:(NSString *)aKey {
    for(NSDictionary *anObject in _cacheArray) {
        if([anObject[@"key"] isEqualToString:aKey])
            return anObject[@"data"];
    }
    return nil;
}

- (void)refreshCacheValidityForKey:(NSString *)aKey {
    NSDictionary *tmpObject;
    for(NSDictionary *anObject in _cacheArray) {
        if([anObject[@"key"] isEqualToString:aKey]) {
            tmpObject = anObject;
            break;
        }
    }
    [_cacheArray removeObject:tmpObject];
    [_cacheArray addObject:tmpObject];
}

#pragma mark -
#pragma mark Webservice dialog methods
#pragma mark -

- (void)getDataFromURL:(NSString *)anURL
 withCompletionHandler:(void (^)(NSURLResponse *response, id responseObject))completionHandler
     andFailureHandler: (void (^)(NSURLResponse *response, NSError *error))failureHandler
{
    if([self cacheContainsObjectWithKey:[anURL MD5]]) {
        
        
        if(completionHandler) completionHandler(nil,  [self cachedObjectForKey:[anURL MD5]]);
    } else {
        CPURLConnection *aConnection = [CPURLConnection sendAsynchronousRequestToURL:anURL
                                                                   completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                                                                       [operationsQueue removeObjectForKey:anURL];
                                                                       [self addDatatoCache:data withKey:[anURL MD5]];
                                                                       if(completionHandler) completionHandler(response, data);
                                                                   }];
        [operationsQueue setObject:aConnection forKey:anURL];
    }
}

- (BOOL)cancelOperationForURL:(NSString *)anURL {
    if(![operationsQueue.allKeys containsObject:anURL]) return FALSE;
    
    CPURLConnection *anOperation = operationsQueue[anURL];
    [anOperation cancel];
    [operationsQueue removeObjectForKey:anURL];
    return TRUE;
}

#pragma mark -
#pragma mark Optional methods to dial with Google Image Search APIs
#pragma mark -

- (void)searchImagesWithString:(NSString *)aString
         withCompletionHandler:(void (^)(NSURLResponse *response, id responseObject))completionHandler
             andFailureHandler: (void (^)(NSURLResponse *response, NSError *error))failureHandler
{
    NSAssert(baseURL, @"baseURL need to be set.");
    NSAssert(aString, @"query string need to be set.");
    
    
    queryString = [aString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSString *tmpURL = [NSString stringWithFormat:@"%@&q=%@&rsz=%d&start=0", baseURL, queryString, kNumberOfResultsPerPage];
    [CPURLConnection sendAsynchronousRequestToURL:tmpURL
                                completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                                    if(error) {
                                        if(failureHandler) failureHandler(response, error);
                                    } else {
                                        NSError *jsonError;
                                        id anObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&jsonError];
                                        if(jsonError) {
                                            if(failureHandler) failureHandler(response, jsonError);
                                        } else {
                                            if(completionHandler) completionHandler(response, anObject);
                                        }
                                    }
                                }];
}

- (void)loadMoreDataStartingOffset:(int)anOffset
             withCompletionHandler:(void (^)(NSURLResponse *response, id responseObject))completionHandler
                 andFailureHandler: (void (^)(NSURLResponse *response, NSError *error))failureHandler
{
    NSAssert(baseURL, @"baseURL need to be set.");
    NSAssert(queryString, @"query string need to be set.");
    
    NSString *tmpURL = [NSString stringWithFormat:@"%@&q=%@&rsz=%d&start=%d", baseURL, queryString, kNumberOfResultsPerPage, anOffset];
    
    [CPURLConnection sendAsynchronousRequestToURL:tmpURL
                                completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                                    if(error) {
                                        if(failureHandler) failureHandler(response, error);
                                    } else {
                                        NSError *jsonError;
                                        id anObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&jsonError];
                                        if(jsonError) {
                                            if(failureHandler) failureHandler(response, jsonError);
                                        } else {
                                            if(completionHandler) completionHandler(response, anObject);
                                        }
                                    }
                                }];
}



@end