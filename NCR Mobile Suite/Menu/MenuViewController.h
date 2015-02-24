//
//  ManuViewController.h
//  NCR Mobile Suite
//
//  Created by Pavel Yankelevich on 1/31/15.
//  Copyright (c) 2015 NCR. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MSDynamicsDrawerViewController.h"
#import "MenuHeaderView.h"

typedef NS_ENUM(NSUInteger, PaneViewControllerType) {
    PaneViewControllerTypeShoppingHistory,
    PaneViewControllerTypeShoppingLists,
    PaneViewControllerTypePayPal,
    PaneViewControllerTypeLoyalty,
    PaneViewControllerTypePromotions,
    PaneViewControllerTypeCount
};

@interface MenuViewController : UITableViewController

@property (nonatomic, weak) MSDynamicsDrawerViewController *dynamicsDrawerViewController;
@property (nonatomic, assign) PaneViewControllerType paneViewControllerType;
@property (nonatomic) MenuHeaderView *headerView;

-(void)transitionToViewController:(PaneViewControllerType)paneViewControllerType;
-(void)updateViewController:(PaneViewControllerType)paneViewControllerType;
-(void)presentPaymentRequestWithId:(NSString*)paymentRequestId;
@end
