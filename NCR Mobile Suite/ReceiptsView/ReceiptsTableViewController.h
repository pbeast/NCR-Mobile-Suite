//
//  ReceiptsTableViewController.h
//  NCR Receipts
//
//  Created by Pavel Yankelevich on 12/23/14.
//  Copyright (c) 2014 Pavel Yankelevich. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ReceiptsTableViewController : UITableViewController

@property (assign, nonatomic) BOOL shouldLoadReceipts;

-(IBAction)startRefresh:(id)sender;

@end
