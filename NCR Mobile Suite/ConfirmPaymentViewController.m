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
    if (_delegate != nil)
        [_delegate paymentDeclined];
}

- (IBAction)confirmPayment:(id)sender {
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeGradient];
    
    [PFCloud callFunctionInBackground:@"payWithPayPal" withParameters:@{ @"paymentId" : paymentRequestId, @"pinCode" : [[self pinCode] text] } block:^(NSDictionary *result, NSError *error)
     {
         [SVProgressHUD dismiss];
         
         NSLog(@"%@", [result description]);
         
         UIAlertController* ac;
         
         UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
             if (_delegate != nil)
                 [_delegate paymentDeclined];
         }];
         

         if (!error){
             if ([result[@"responseEnvelope"][@"ack"] isEqualToString:@"Failure"]){
                 NSDictionary* error = result[@"error"][0];
                 NSNumber* errorId = error[@"errorId"];
                 if ([errorId isEqual:@(580022)]){
                     ac = [UIAlertController alertControllerWithTitle:@"NCR Mobile Suite" message:error[@"message"] preferredStyle:UIAlertControllerStyleAlert];
                     
                     [ac addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
                 }
                 else{
                    ac = [UIAlertController alertControllerWithTitle:@"NCR Mobile Suite" message:error[@"message"] preferredStyle:UIAlertControllerStyleAlert];
                     [ac addAction:okAction];
                 }
             }
         }
         else{
             [[[UIAlertView alloc] initWithTitle:@"NCR Mobile Suite" message:@"Hurray!!!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
             ac = [UIAlertController alertControllerWithTitle:@"NCR Mobile Suite" message:@"Hurray!!!" preferredStyle:UIAlertControllerStyleAlert];
             [ac addAction:okAction];
         }

         [self presentViewController:ac animated:YES completion:nil];
     }];
}
@end
