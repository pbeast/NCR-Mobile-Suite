//
//  ReceiptsTableCell.h
//  NCR Receipts
//
//  Created by Pavel Yankelevich on 12/23/14.
//  Copyright (c) 2014 Pavel Yankelevich. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ParseUI/ParseUI.h>
#import <Parse/Parse.h>

@interface ReceiptsTableCell : UITableViewCell

@property (weak, nonatomic) IBOutlet PFImageView *logo;
@property (weak, nonatomic) IBOutlet UILabel *retailer;
@property (weak, nonatomic) IBOutlet UILabel *address;
@property (weak, nonatomic) IBOutlet UILabel *total;
@property (weak, nonatomic) IBOutlet UILabel *date;

@property (assign, nonatomic, setter=buildFromReceipt:) PFObject *receipt;
@end
