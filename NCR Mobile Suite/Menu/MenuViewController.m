//
//  ManuViewController.m
//  NCR Mobile Suite
//
//  Created by Pavel Yankelevich on 1/31/15.
//  Copyright (c) 2015 NCR. All rights reserved.
//

#import "MenuViewController.h"
#import "MenuCell.h"
#import "AppDelegate.h"
#import "UIColor_Utils.h"
#import "UIViewController+ENPopUp.h"
#import "Parse/Parse.h"
#import "SVProgressHUD.h"

@interface MenuViewController ()<MenuHeaderViewDelegate>
{
    UIButton *startShoppingButton;
}
@property (nonatomic, strong) NSDictionary *paneViewControllerTitles;
@property (nonatomic, strong) NSDictionary *paneViewControllerIcons;

@property (nonatomic, strong) NSDictionary *paneViewControllerIdentifiers;
@property (nonatomic, strong) NSMutableDictionary *paneViewControllerInstances;
@property (nonatomic, strong) NSDictionary *sectionTitles;
@property (nonatomic, strong) NSArray *tableViewSectionBreaks;

@property (nonatomic, strong) UIBarButtonItem *paneStateBarButtonItem;
@property (nonatomic, strong) UIBarButtonItem *paneRevealLeftBarButtonItem;
@property (nonatomic, strong) UIBarButtonItem *paneRevealRightBarButtonItem;

@end

@implementation MenuViewController

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initialize];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorColor = [UIColor clearColor];;//[UIColor colorWithWhite:1.0 alpha:1];

    CGRect bounds = [self.view bounds];
    bounds.size.height = 100;
    
    _headerView = [[[[NSBundle mainBundle] loadNibNamed:@"MenuHeaderView" owner:self options:nil] lastObject] initWithFrame:bounds andParentView:self.view];
    _headerView.delegate = self;
    
    [self.tableView setTableHeaderView:_headerView];
    
    AppDelegate* delegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    [delegate checkRegistrationStatus];
}

-(void)menuHeaderTapped{
//    [self.dynamicsDrawerViewController setPaneState:MSDynamicsDrawerPaneStateClosed animated:YES allowUserInterruption:YES completion:nil];
    AppDelegate* delegate = (AppDelegate*)self.dynamicsDrawerViewController.delegate;
    [delegate loginOrLogout];
}

- (void)viewDidLayoutSubviews
{
    [_headerView resizeView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)initialize
{
    self.paneViewControllerType = NSUIntegerMax;
    
    self.paneViewControllerTitles = @{
                                      @(PaneViewControllerTypeShoppingHistory) : @"Shopping History",
                                      @(PaneViewControllerTypeShoppingLists) : @"Shopping Lists",
                                      @(PaneViewControllerTypePayPal) : @"Connect to PayPal",
                                      @(PaneViewControllerTypeLoyalty) : @"Loyalty",
                                      };
    self.paneViewControllerIcons = @{
                                      @(PaneViewControllerTypeShoppingHistory) : @"receipt",
                                      @(PaneViewControllerTypeShoppingLists) : @"shopping_list",
                                      @(PaneViewControllerTypePayPal) : @"PayPalLogo",
                                      @(PaneViewControllerTypeLoyalty) : @"loyalty-cards"
                                      };
    
    self.paneViewControllerIdentifiers = @{
                                           @(PaneViewControllerTypeShoppingHistory) : @"ReceiptsTableViewController"
                                           };
    
    self.paneViewControllerInstances = [NSMutableDictionary new];
    
//    self.sectionTitles = @{
//                           @(MSMenuViewControllerTableViewSectionTypeOptions) : @"Options",
//                           @(MSMenuViewControllerTableViewSectionTypeExamples) : @"Examples",
//                           @(MSMenuViewControllerTableViewSectionTypeAbout) : @"About",
//                           };
    
//    self.tableViewSectionBreaks = @[
//                                    @(MSPaneViewControllerTypeControls),
//                                    @(MSPaneViewControllerTypeMonospace),
//                                    @(MSPaneViewControllerTypeCount)
//                                    ];
}

- (PaneViewControllerType)paneViewControllerTypeForIndexPath:(NSIndexPath *)indexPath
{
    PaneViewControllerType paneViewControllerType;
    if (indexPath.section == 0) {
        paneViewControllerType = indexPath.row;
    } else {
        paneViewControllerType = ([self.tableViewSectionBreaks[(indexPath.section - 1)] integerValue] + indexPath.row);
    }
    NSAssert(paneViewControllerType < PaneViewControllerTypeCount, @"Invalid Index Path");
    return paneViewControllerType;
}

-(void)updateViewController:(PaneViewControllerType)paneViewControllerType
{
    UIViewController *paneViewController = [self.paneViewControllerInstances objectForKey:@(paneViewControllerType)];
    if (paneViewController != nil){
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
        
        [paneViewController performSelector:@selector(startRefresh:) withObject:self];
        
#pragma clang diagnostic pop
    }
}

- (void)transitionToViewController:(PaneViewControllerType)paneViewControllerType
{
    // Close pane if already displaying the pane view controller
    if (paneViewControllerType == self.paneViewControllerType) {
        [self.dynamicsDrawerViewController setPaneState:MSDynamicsDrawerPaneStateClosed animated:YES allowUserInterruption:YES completion:nil];
        return;
    }
    
    BOOL animateTransition = self.dynamicsDrawerViewController.paneViewController != nil;
    
    UIViewController *paneViewController = [self.paneViewControllerInstances objectForKey:@(paneViewControllerType)];
    if (paneViewController == nil){
        if (self.paneViewControllerIdentifiers[@(paneViewControllerType)] != nil){
            paneViewController = [self.storyboard instantiateViewControllerWithIdentifier:self.paneViewControllerIdentifiers[@(paneViewControllerType)]];
            [self.paneViewControllerInstances setObject:paneViewController forKey:@(paneViewControllerType)];
        }
        else
        {
            [self.dynamicsDrawerViewController setPaneState:MSDynamicsDrawerPaneStateClosed animated:YES allowUserInterruption:YES completion:nil];
            return;
        }
    }
    else
        return;

    if (startShoppingButton == nil){
        startShoppingButton = [UIButton buttonWithType:UIButtonTypeCustom];
        
        CGRect f = self.dynamicsDrawerViewController.view.frame;
        startShoppingButton.frame = CGRectMake(CGRectGetMidX(f) - 40.0, CGRectGetMaxY(f) - 85, 80, 80);
        startShoppingButton.backgroundColor = [UIColor colorWithWhite:0 alpha:0.4];
        startShoppingButton.layer.borderColor = [[UIColor blackColor] CGColor];
        startShoppingButton.layer.borderWidth = 0;
        startShoppingButton.layer.cornerRadius = 40;
        
        [startShoppingButton setImage:[UIImage imageNamed:@"shoppingCard"] forState:UIControlStateNormal];
        [startShoppingButton addTarget:self action:@selector(startShopping:) forControlEvents:UIControlEventTouchDown];
        [self.dynamicsDrawerViewController.view addSubview:startShoppingButton];
        [self.dynamicsDrawerViewController.view bringSubviewToFront:startShoppingButton];
    }
    
    paneViewController.navigationItem.title = self.paneViewControllerTitles[@(paneViewControllerType)];
    
    self.paneRevealLeftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"menu"] style:UIBarButtonItemStylePlain target:self action:@selector(dynamicsDrawerRevealLeftBarButtonItemTapped:)];
    
    [self.paneRevealLeftBarButtonItem setTintColor:[UIColor colorWithHexString:@"#318902"]];
    
    paneViewController.navigationItem.leftBarButtonItem = self.paneRevealLeftBarButtonItem;
    
    self.paneRevealRightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"qr_code"] style:UIBarButtonItemStylePlain target:self action:@selector(dynamicsDrawerRevealRightBarButtonItemTapped:)];
    [self.paneRevealRightBarButtonItem setTintColor:[UIColor colorWithHexString:@"#318902"]];

    paneViewController.navigationItem.rightBarButtonItem = self.paneRevealRightBarButtonItem;
    
    UINavigationController *paneNavigationViewController = [[UINavigationController alloc] initWithRootViewController:paneViewController];
    [self.dynamicsDrawerViewController setPaneViewController:paneNavigationViewController animated:animateTransition completion:nil];
    
    self.paneViewControllerType = paneViewControllerType;
}

- (void)dynamicsDrawerRevealLeftBarButtonItemTapped:(id)sender
{
    [self.dynamicsDrawerViewController setPaneState:MSDynamicsDrawerPaneStateOpen inDirection:MSDynamicsDrawerDirectionLeft animated:YES allowUserInterruption:YES completion:nil];
}

- (void)dynamicsDrawerRevealRightBarButtonItemTapped:(id)sender
{
//    [self.dynamicsDrawerViewController setPaneState:MSDynamicsDrawerPaneStateOpen inDirection:MSDynamicsDrawerDirectionRight animated:YES allowUserInterruption:YES completion:nil];
    
    UIViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"SyncViewController"];
    
    CGRect f = self.dynamicsDrawerViewController.view.frame;
    f = CGRectInset(f, f.size.width * 0.1, f.size.height * 0.1);
    
    vc.view.frame = f;//CGRectMake(0, 0, 270.0f, 380.0f);
    [self.dynamicsDrawerViewController presentPopUpViewController:vc completion:^{
        
    }];
}

-(IBAction)startShopping:(id)sender{
    [self.dynamicsDrawerViewController setPaneState:MSDynamicsDrawerPaneStateClosed animated:YES allowUserInterruption:YES completion:nil];
    
    [[[UIAlertView alloc] initWithTitle:@"And now shopping begin" message:@"" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.paneViewControllerTitles count];
}

//- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
//{
//    UITableViewHeaderFooterView *headerView = [self.tableView dequeueReusableHeaderFooterViewWithIdentifier:MSDrawerHeaderReuseIdentifier];
//    headerView.textLabel.text = @"";
//    return headerView;
//}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 3.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return FLT_EPSILON;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MenuCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MenuLine" forIndexPath:indexPath];
    
    PaneViewControllerType controllerType = [self paneViewControllerTypeForIndexPath:indexPath];
    
    if (controllerType == PaneViewControllerTypePayPal){
        if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"PayPalConnected"] isEqual: @(YES)]){
            [[cell title] setText:@"PayPal Connected"];
        }
        else
            [[cell title] setText:self.paneViewControllerTitles[@(controllerType)]];
    }
    else
        [[cell title] setText:self.paneViewControllerTitles[@(controllerType)]];
    [[cell image] setImage:[UIImage imageNamed:self.paneViewControllerIcons[@(controllerType)]]];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    PaneViewControllerType paneViewControllerType = [self paneViewControllerTypeForIndexPath:indexPath];
    
    if (paneViewControllerType == PaneViewControllerTypePayPal){
        [self.dynamicsDrawerViewController setPaneState:MSDynamicsDrawerPaneStateClosed animated:YES allowUserInterruption:YES completion:nil];
        AppDelegate* delegate = (AppDelegate*)self.dynamicsDrawerViewController.delegate;
        if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"PayPalConnected"] isEqual: @(YES)]){
            UIAlertController* ac = [UIAlertController alertControllerWithTitle:@"NCR Mobile Suite" message:@"PayPal already connected. Disconnect?" preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Disconnect" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeGradient];

                [PFCloud callFunctionInBackground:@"removePayPalConnection" withParameters:@{} block:^(NSDictionary *result, NSError *error)
                 {
                     [SVProgressHUD dismiss];
                     
                     [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"PayPalConnected"];
                     [[NSUserDefaults standardUserDefaults] synchronize];
                     
                     [[self tableView] reloadData];
                 }];
            }];
            
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
            
            [ac addAction:okAction];
            [ac addAction:cancelAction];
            
            [self.dynamicsDrawerViewController presentViewController:ac animated:YES completion:^{
                
            }];
        }
        else{
            PFUser *currentUser = [PFUser currentUser];
            if (currentUser == nil)
            {
                UIAlertView* av = [[UIAlertView alloc] initWithTitle:@"NCR Mobile Suite" message:@"You have to login first" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [av show];
            }
            else
                [delegate connectPayPal];
        }
    }
//    else if (paneViewControllerType == PaneViewControllerTypeLoginLogout){
//        [self.dynamicsDrawerViewController setPaneState:MSDynamicsDrawerPaneStateClosed animated:YES allowUserInterruption:YES completion:nil];
//        AppDelegate* delegate = (AppDelegate*)self.dynamicsDrawerViewController.delegate;
//        [delegate loginOrLogout];
//    }
    else
        [self transitionToViewController:paneViewControllerType];
    
    // Prevent visual display bug with cell dividers
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    double delayInSeconds = 0.3;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self.tableView reloadData];
    });
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
