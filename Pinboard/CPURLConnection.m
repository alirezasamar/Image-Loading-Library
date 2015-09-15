//
//  NSObject+CPURLConnection.m
//  Pinboard
//
//  Created by Alireza Samar on 9/15/15.
//  Copyright (c) 2015 Alireza Samar. All rights reserved.
//

#import "Network.h"
#import "CPURLConnection.h"

#define kUserAgent @"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_5) AppleWebKit/600.8.9 (KHTML, like Gecko) Version/8.0.8 Safari/600.8.9"

@implementation CPURLConnection {
    NSURLConnection *connection;
    NSHTTPURLResponse *response;
    NSMutableData *responseData;
}

@synthesize request, queue, completionHandler;




#pragma mark Low Level calls

+ (CPURLConnection *)sendAsynchronousRequestToURL:(NSString *)anURL completionHandler:(void (^)(NSURLResponse *response, NSData *data, NSError *error))completionHandler {
    NSMutableURLRequest *aRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:anURL] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:60];
    [aRequest setValue:kUserAgent forHTTPHeaderField:@"User-Agent"];
    CPURLConnection *aConnection = [[CPURLConnection alloc] init];
    aConnection.request = aRequest;
    aConnection.queue = [NSOperationQueue mainQueue];
    aConnection.completionHandler = completionHandler;
    [aConnection start];
    return aConnection;
}

+ (CPURLConnection *)sendAsynchronousRequest:(NSURLRequest *)request queue:(NSOperationQueue *)queue completionHandler:(void(^)(NSURLResponse *response, NSData *data, NSError *error))completionHandler
{
    CPURLConnection *result = [[CPURLConnection alloc] init];
    result.request = request;
    result.queue = queue;
    result.completionHandler = completionHandler;
    [result start];
    return result;
}

- (void)dealloc
{
    [self cancel];
}

- (void)start
{
    connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
    [connection scheduleInRunLoop:NSRunLoop.mainRunLoop forMode:NSDefaultRunLoopMode];
    if (connection) {
        [connection start];
    } else {
        if (completionHandler) completionHandler(nil, nil, nil); completionHandler = nil;
    }
}

- (void)cancel
{
    [connection cancel]; connection = nil;
    completionHandler = nil;
}

- (void)connection:(NSURLConnection *)_connection didReceiveResponse:(NSHTTPURLResponse *)_response
{
    response = _response;
}

- (void)connection:(NSURLConnection *)_connection didReceiveData:(NSData *)data
{
    if (!responseData) {
        responseData = [NSMutableData dataWithData:data];
    } else {
        [responseData appendData:data];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)_connection
{
    connection = nil;
    if (completionHandler) {
        void(^b)(NSURLResponse *response, NSData *data, NSError *error) = completionHandler;
        completionHandler = nil;
        [queue addOperationWithBlock:^{b(response, responseData, nil);}];
    }
}

- (void)connection:(NSURLConnection *)_connection didFailWithError:(NSError *)error
{
    connection = nil;
    if (completionHandler) {
        void(^b)(NSURLResponse *response, NSData *data, NSError *error) = completionHandler;
        completionHandler = nil;
        [queue addOperationWithBlock:^{b(response, responseData, error);}];
    }
}

#if TARGET_IPHONE_SIMULATOR
- (BOOL)connection:(NSURLConnection *)_connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
    return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}

- (void)connection:(NSURLConnection *)_connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
}
#endif

@end