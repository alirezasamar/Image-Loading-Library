//
//  ViewController.m
//  Pinboard
//
//  Created by Alireza Samar on 9/15/15.
//  Copyright (c) 2015 Alireza Samar. All rights reserved.
//

#import "Network.h"
#import "ViewController.h"
#import "UICustomTableViewCell.h"

@interface ViewController () {
    NSMutableArray *dataSource;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    dataSource = [NSMutableArray new]; //setup a new and empty datasource for tableview
    
    //Network singleton initialization
    [[Network shared] setBaseURL:@"https://ajax.googleapis.com/ajax/services/search/images?v=1.0"];
    
    //setup max cache entries
    [[Network shared] setNumberOfCachedResults:50];
    
    //setup max number of entries per page. Note that Google APIs, used in this Proof-Of-Concept does not allow more than 8 results per page.
    [[Network shared] setNumberOfResultsPerPage:8];
    
    //search a dataset of images and populate the MVC pattern according
    [[Network shared] searchImagesWithString:@"mindvalley"
                       withCompletionHandler:^(NSURLResponse *response, id responseObject) {
                           [dataSource addObjectsFromArray:responseObject[@"responseData"][@"results"]];
                           [_aTableView reloadData];
                       }
                           andFailureHandler:^(NSURLResponse *response, NSError *error) {
                               [[[UIAlertView alloc] initWithTitle:@"Error" message:error.description delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                           }];
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark UITableViewDelegate & UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UICustomTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    NSDictionary *aRow = [dataSource objectAtIndex:indexPath.row];
    
    cell.aTextLabel.text = aRow[@"titleNoFormatting"];
    cell.anImageView.image = nil;
    
    // Requirement: "The purpose of the library is to abstract the downloading (images, pdf, zip, etc) and caching of
    // remote resources (images, JSON, XML, etc) so that client code can easily "swap" a URL for any kind of files ( JSON, XML, etc) without worrying about any of the details."
    //
    // The following methods, search the internal memory cache for a specified URL string. If present, the NSData will be dequeued and returned to the callback.
    // Otherwise it will be fetched from the Internet and stored appropriatelly on the Cache.
    
    [[Network shared] getDataFromURL:aRow[@"tbUrl"]
               withCompletionHandler:^(NSURLResponse *response, id responseObject) {
                   cell.anImageView.image = [UIImage imageWithData:responseObject];
               }
                   andFailureHandler:^(NSURLResponse *response, NSError *error) {
                       [[[UIAlertView alloc] initWithTitle:@"Error" message:error.description delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                   }];
    
    // Requirement: "Images and JSON should be cached efficiently (in-memory only, no need for caching to disk)"
    // NSData bytes are dequeued automatically from the cache (if present), otherwise it will be fetched from the Internet and stored appropriatelly on the Cache.
    
    // Requirement: "The cache should have a configurable max capacity and should evict images not recently used An image load may be cancelled"
    // Cells that are more recently viewed gain a more chances to stay on the cacheDictionary.
    
    // Requirement: "An image load may be cancelled"
    // To abort a download operation, you can use the following:
    //
    // [[Network shared] cancelOperationForURL:@"yourURLGoesHere"];

    return cell;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    float offset = (scrollView.contentOffset.y - (scrollView.contentSize.height - scrollView.frame.size.height));
    if (offset >= 0 && offset <= 5) { // This is the last cell so get more data, based on the received ones.

        // Requirement: "Think that the list of item returned by the API can reach 100 items or even more.
        // At a time, it loads 10 items, and load more from the API when user reach the end of the list."

        [[Network shared] loadMoreDataStartingOffset:(int)dataSource.count
                               withCompletionHandler:^(NSURLResponse *response, id responseObject) {
                                   NSDictionary *tmpDict = (NSDictionary *)responseObject;
                                   if([tmpDict.allKeys containsObject:@"responseStatus"] && [tmpDict[@"responseStatus"] intValue] == 400) {
                                       [[[UIAlertView alloc] initWithTitle:@"Warning"
                                                                   message:@"Congrats! you've reach the end!"
                                                                  delegate:nil
                                                         cancelButtonTitle:@"OK"
                                                         otherButtonTitles:nil] show];
                                   } else {
                                       [dataSource addObjectsFromArray:responseObject[@"responseData"][@"results"]];
                                       [_aTableView reloadData];
                                   }
                               }
                                   andFailureHandler:^(NSURLResponse *response, NSError *error) {
                                       [[[UIAlertView alloc] initWithTitle:@"Error" message:error.description delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                                   }];
    }
}

@end
