//
//  ConfirmPaymentViewController.m
//  NCR Mobile Suite
//
//  Created by Pavel Yankelevich on 2/15/15.
//  Copyright (c) 2015 NCR. All rights reserved.
//

#import "ConfirmPaymentViewController.h"
#import <SVProgressHUD.h>
#import <Parse/Parse.h>

@interface ConfirmPaymentViewController ()
{
    NSDictionary* displayData;
    NSString* paymentRequestId;
}

- (IBAction)confirmPayment:(id)sender;
@end

@implementation ConfirmPaymentViewController

-(void)initWithData:(NSDictionary*)data andPaymentId:(NSString*)paymentId;
{
    displayData = [data copy];
    paymentRequestId = [paymentId copy];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

-(void)viewWillAppear:(BOOL)animated{
    [[self logo] setFile:displayData[@"logo"]];
    [[self logo] loadInBackground];
    
    [[self retailerName] setText:displayData[@"retailerName"]];
    [[self retailerAddress] setText:displayData[@"storeAddress"]];
    [[self total] setText:[NSString stringWithFormat:@"%@%.2f", displayData[@"currencySymbol"], [displayData[@"total"] doubleValue]]];
    
    [[self pinCode] becomeFirstResponder];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)declinePayment:(id)sender {
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeGradient];
    
    [PFCloud callFunctionInBackground:@"rejectPayment" withParameters:@{ @"paymentId" : paymentRequestId } block:^(NSDictionary *result, NSError *error)
     {
         [SVProgressHUD dismiss];
         if (!error){
         }
         
         if (_delegate != nil)
             [_delegate paymentDeclined];
     }];
     
}

- (IBAction)confirmPayment:(id)sender {
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeGradient];
    
    [PFCloud callFunctionInBackground:@"payWithPayPal" withParameters:@{ @"paymentId" : paymentRequestId, @"pinCode" : [[self pinCode] text] } block:^(NSDictionary *result, NSError *error)
     {
         [SVProgressHUD dismiss];
         
         NSLog(@"%@", [result description]);
         
         UIAlertController* ac;
         
         if (!error){
             ac = [UIAlertController alertControllerWithTitle:@"NCR Mobile Suite" message:result[@"message"] preferredStyle:UIAlertControllerStyleAlert];
             UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                 if (_delegate != nil)
                     [_delegate paymentConfirmed];
             }];
             [ac addAction:okAction];
         }
         else{
             NSData *data = [[error userInfo][@"error"] dataUsingEncoding:NSUTF8StringEncoding];
             id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
             
             ac = [UIAlertController alertControllerWithTitle:@"NCR Mobile Suite" message:json[@"message"]    preferredStyle:UIAlertControllerStyleAlert];
             UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                 if ([json[@"data"][@"isFatalError"] isEqual:@(YES)])
                     if (_delegate != nil)
                         [_delegate paymentDeclined];
             }];
             [ac addAction:okAction];
         }

         [self presentViewController:ac animated:YES completion:nil];
     }];
}
@end
