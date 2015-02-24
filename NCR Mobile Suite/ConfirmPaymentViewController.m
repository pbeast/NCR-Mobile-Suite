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
    
    [PFCloud callFunctionInBackground:@"payWithPayPal" withParameters:@{ } block:^(NSDictionary *result, NSError *error)
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
             if ([result[@"responseEnvelope"][@"ack"] isEqualToString:@"Failure"]){
                 NSDictionary* payPalError = result[@"error"][0];
                 NSString* errorId = payPalError[@"errorId"];
                 if ([errorId isEqualToString:@"580022"]){
                     ac = [UIAlertController alertControllerWithTitle:@"NCR Mobile Suite" message:@"Have you typed your pin correctly?" preferredStyle:UIAlertControllerStyleAlert];
                     
                     [ac addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
                 }
                 else{
                     ac = [UIAlertController alertControllerWithTitle:@"NCR Mobile Suite" message:@"Failed to process payment" preferredStyle:UIAlertControllerStyleAlert];
                     UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                         if (_delegate != nil)
                             [_delegate paymentDeclined];
                     }];
                     [ac addAction:okAction];
                 }
             }
             else
             {
                 ac = [UIAlertController alertControllerWithTitle:@"NCR Mobile Suite" message:@"Payment Succeeded" preferredStyle:UIAlertControllerStyleAlert];
                 UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                     if (_delegate != nil)
                         [_delegate paymentConfirmed];
                 }];
                 [ac addAction:okAction];
             }
         }
         else{
             
             ac = [UIAlertController alertControllerWithTitle:@"NCR Mobile Suite" message:[error userInfo][@"error"]    preferredStyle:UIAlertControllerStyleAlert];
             UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                 if (_delegate != nil)
                     [_delegate paymentDeclined];
             }];
             [ac addAction:okAction];
         }

         [self presentViewController:ac animated:YES completion:nil];
     }];
}
@end
