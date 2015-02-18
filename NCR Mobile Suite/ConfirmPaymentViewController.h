//
//  ConfirmPaymentViewController.h
//  NCR Mobile Suite
//
//  Created by Pavel Yankelevich on 2/15/15.
//  Copyright (c) 2015 NCR. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ParseUI/ParseUI.h>
#import <Parse/Parse.h>

@protocol ConfirmPaymentViewControllerDelegate <NSObject>

-(void)paymentConfirmed;
-(void)paymentDeclined;

@end

@interface ConfirmPaymentViewController : UIViewController

@property (weak, nonatomic) id<ConfirmPaymentViewControllerDelegate> delegate;
@property (weak, nonatomic) IBOutlet PFImageView *logo;
@property (weak, nonatomic) IBOutlet UILabel *retailerName;
@property (weak, nonatomic) IBOutlet UILabel *retailerAddress;
@property (weak, nonatomic) IBOutlet UILabel *total;
@property (weak, nonatomic) IBOutlet UITextField *pinCode;

-(void)initWithData:(NSDictionary*)data andPaymentId:(NSString*)paymentId;

@end
