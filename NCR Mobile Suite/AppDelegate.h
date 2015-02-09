//
//  AppDelegate.h
//  NCR Mobile Suite
//
//  Created by Pavel Yankelevich on 1/28/15.
//  Copyright (c) 2015 NCR. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MSDynamicsDrawerViewController.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate, MSDynamicsDrawerViewControllerDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, weak) MSDynamicsDrawerViewController *dynamicsDrawerViewController;

-(void)connectPayPal;
-(void)loginOrLogout;

-(void) checkRegistrationStatus;
@end

