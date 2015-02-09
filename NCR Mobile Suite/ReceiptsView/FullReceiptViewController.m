//
//  FullReceiptViewController.m
//  NCR Receipts
//
//  Created by Pavel Yankelevich on 12/16/14.
//  Copyright (c) 2014 Pavel Yankelevich. All rights reserved.
//

#import "FullReceiptViewController.h"
#import "ReceiptActivityItemProvider.h"

@interface FullReceiptViewController ()<UIPrintInteractionControllerDelegate>

@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (strong, nonatomic) UIActivityViewController *activityViewController;

@end

@implementation FullReceiptViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    UIBarButtonItem* shareButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(share:)];
    
//    UIBarButtonItem* printButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(printContent:)];
    
    self.navigationItem.rightBarButtonItems = @[shareButton];
    
//    self.webView.scrollView.contentInset = UIEdgeInsetsMake(64, 0, 0, 0);
}

-(IBAction)share:(id)sender
{
    UIMarkupTextPrintFormatter *htmlFormatter = [[UIMarkupTextPrintFormatter alloc] initWithMarkupText:self.receiptToDisplay];
    
    NSAttributedString* attrStr = [[NSAttributedString alloc] initWithData:[self.receiptToDisplay dataUsingEncoding:NSUTF8StringEncoding] options:
                                   @{
                                        NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
                                        NSCharacterEncodingDocumentAttribute: [NSNumber numberWithInt:NSUTF8StringEncoding]
                                    } documentAttributes:nil error:nil];
    
    ReceiptActivityItemProvider* r = [[ReceiptActivityItemProvider alloc] initWithReceipt:self.receiptToDisplay];
    
    self.activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[self.receiptToDisplay, htmlFormatter] applicationActivities:nil];
    self.activityViewController.excludedActivityTypes = @[UIActivityTypePostToFacebook,
                                                          UIActivityTypePostToTwitter,
                                                          UIActivityTypePostToWeibo,
                                                          UIActivityTypeMessage,
                                                          UIActivityTypeCopyToPasteboard,
                                                          UIActivityTypeAssignToContact,
                                                          UIActivityTypeSaveToCameraRoll,
                                                          UIActivityTypeAddToReadingList,
                                                          UIActivityTypePostToFlickr,
                                                          UIActivityTypePostToVimeo,
                                                          UIActivityTypePostToTencentWeibo,
                                                          UIActivityTypeAirDrop           ];
    
    [self presentViewController:self.activityViewController animated:YES completion:nil];
}

- (IBAction)printContent:(id)sender {
    UIPrintInteractionController *pic = [UIPrintInteractionController sharedPrintController];
    pic.delegate = self;
    
    UIPrintInfo *printInfo = [UIPrintInfo printInfo];
    printInfo.outputType = UIPrintInfoOutputGeneral;
    printInfo.jobName = @"NCR Digital Receipt";
    pic.printInfo = printInfo;
    
    UIMarkupTextPrintFormatter *htmlFormatter = [[UIMarkupTextPrintFormatter alloc]
                                                 initWithMarkupText:self.receiptToDisplay];
    htmlFormatter.startPage = 0;
    htmlFormatter.contentInsets = UIEdgeInsetsMake(72.0, 72.0, 72.0, 72.0); // 1 inch margins
    pic.printFormatter = htmlFormatter;
    pic.showsPageRange = YES;
    
    void (^completionHandler)(UIPrintInteractionController *, BOOL, NSError *) =
    ^(UIPrintInteractionController *printController, BOOL completed, NSError *error) {
        if (!completed && error) {
            NSLog(@"Printing could not complete because of error: %@", error);
        }
    };
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [pic presentFromBarButtonItem:sender animated:YES completionHandler:completionHandler];
    } else {
        [pic presentAnimated:YES completionHandler:completionHandler];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated
{
    self.navigationController.navigationBar.hidden = NO;
    
    [self.webView loadHTMLString:self.receiptToDisplay baseURL:nil];
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
