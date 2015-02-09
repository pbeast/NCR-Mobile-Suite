//
//  ViewController.m
//  NCR Receipts
//
//  Created by Pavel Yankelevich on 12/12/14.
//  Copyright (c) 2014 Pavel Yankelevich. All rights reserved.
//

#import "SyncViewController.h"
#import <Parse/Parse.h>
#import "ZXingObjC.h"
#import "SVProgressHUD.h"
#import "UIViewController+ENPopUp.h"

@interface SyncViewController ()
{
    BOOL shouldCreateNewReceipt;
}
@property (weak, nonatomic) IBOutlet UILabel *pinCode;
@property (weak, nonatomic) IBOutlet UIImageView *qrCode;

@end

@implementation SyncViewController

- (void)registerReceipt {
    
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeNone];
    
    PFInstallation* installation = [PFInstallation currentInstallation];
    
    [PFCloud callFunctionInBackground:@"registerReceipt"
                       withParameters:@{@"installationId" : [installation installationId]}
                                block:^(NSString *result, NSError *error) {
                                    if (!error) {
                                        PFObject* object = (PFObject*)result;
                                        NSNumber* pinCode = object[@"pinCode"];
                                        
                                        NSError *error = nil;
                                        ZXMultiFormatWriter *writer = [ZXMultiFormatWriter writer];
                                        NSString* pinCodeStr = [NSString stringWithFormat:@"%ld", [pinCode longValue]];
                                        ZXBitMatrix* result = [writer encode:pinCodeStr
                                                                      format:kBarcodeFormatQRCode
                                                                       width:500
                                                                      height:500
                                                                       error:&error];
                                        if (result)
                                        {
                                            UIImage* uiImage = [[UIImage alloc] initWithCGImage:[[ZXImage imageWithMatrix:result] cgimage]];
                                            [self.qrCode setImage:uiImage];
                                            
                                            [self.pinCode setText:[NSString stringWithFormat:@"%05ld", [pinCode longValue]]];
                                        } else {
                                            NSString *errorMessage = [error localizedDescription];
                                            NSLog(@"%@", errorMessage);
                                        }
                                        
                                        [SVProgressHUD dismiss];
                                    }
                                }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    shouldCreateNewReceipt = YES;
    
    //[self.navigationController setToolbarHidden:NO];
    
//    UISwipeGestureRecognizer *swipeToTop = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(slideToTop:)];
//    swipeToTop.direction = UISwipeGestureRecognizerDirectionUp;
//    
//    [self.view addGestureRecognizer:swipeToTop];
}

-(void)slideToTop:(UISwipeGestureRecognizer *)gestureRecognizer{
    
//    [self dismissPopUpViewControllerWithcompletion:^{
//        
//    }];
//    
//    [UIView animateWithDuration:0.5 animations:^{
//        //self.view.frame = CGRectOffset(self.view.frame, 320.0, 0.0);
//    }];
}

-(void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    if (motion == UIEventSubtypeMotionShake){
        [self registerReceipt];
    }
}

-(IBAction)startRefresh:(id)sender{
    [self registerReceipt];
}

-(BOOL)canBecomeFirstResponder{
    return YES;
}

-(IBAction)actions:(id)sender
{
    [self registerReceipt];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated
{
//    self.navigationController.navigationBar.hidden = NO;

    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];

//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        [self becomeFirstResponder];
//    });
//    
//
//    self.parentViewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(actions:)];
//
    
    if (shouldCreateNewReceipt){
        shouldCreateNewReceipt = NO;
        [self registerReceipt];
    }
}

-(void)viewWillDisappear:(BOOL)animated
{
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    
    [self resignFirstResponder];
}

@end
