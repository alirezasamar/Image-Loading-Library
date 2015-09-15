//
//  UICustomTableViewCell.h
//  Pinboard
//
//  Created by Alireza Samar on 9/15/15.
//  Copyright (c) 2015 Alireza Samar. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UICustomTableViewCell : UITableViewCell

@property(nonatomic, weak) IBOutlet UIImageView* anImageView;
@property(nonatomic, weak) IBOutlet UILabel* aTextLabel;

@end
