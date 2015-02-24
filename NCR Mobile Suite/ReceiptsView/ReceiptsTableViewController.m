//
//  ReceiptsTableViewController.m
//  NCR Receipts
//
//  Created by Pavel Yankelevich on 12/23/14.
//  Copyright (c) 2014 Pavel Yankelevich. All rights reserved.
//

#import "ReceiptsTableViewController.h"
#import "FullReceiptViewController.h"
#import "SVProgressHUD.h"
#import <Parse/Parse.h>
#import <ParseUI/ParseUI.h>
#import "ReceiptsTableCell.h"

@interface ReceiptsTableViewController ()
{
    NSMutableArray* receipts;
    UIRefreshControl *refreshControl;
}
@end

@implementation ReceiptsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    //self.clearsSelectionOnViewWillAppear = YES;
        
//    self.navigationItem.backBarButtonItem.title = @"Back";
//    self.navigationController.title = @"Back";

    self.tableView.allowsMultipleSelectionDuringEditing = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
  //   self.navigationItem.rightBarButtonItem = self.editButtonItem;

    _shouldLoadReceipts = YES;
    
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 90, 0);
    //self.tableView.rowHeight = 102;
    
    
    [self.refreshControl addTarget:self action:@selector(startRefresh:) forControlEvents:UIControlEventValueChanged];
}

- (void)fillTableFromLocalStorage
{
    PFQuery *query = [PFQuery queryWithClassName:@"Receipts"];
    [query fromLocalDatastore];
    [query orderByDescending:@"createdAt"];
    [query includeKey:@"retailer"];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
        receipts = [objects mutableCopy];
        
        [self.refreshControl endRefreshing];
        
        [SVProgressHUD dismiss];
        
        [self.tableView reloadData];
    }];
}

-(void) processReceiptsFetchData:(NSDictionary *)result error:(NSError *)error
{
    if (!error)
    {
        NSArray* fetchedReceipts = result[@"data"];
        if ([fetchedReceipts count] == 0){
            [self.refreshControl endRefreshing];
            return;
        }
        
        NSMutableArray *uniqueRetailers = [NSMutableArray new];
        
        for (PFObject* receipt in fetchedReceipts) {
            PFObject* retailer = receipt[@"retailer"];
            NSString* retailerId = [retailer objectId];
            if ([uniqueRetailers containsObject:retailerId])
                continue;
            
            [uniqueRetailers addObject:retailerId];
            [retailer pin];
        }
        
        [PFObject pinAllInBackground:fetchedReceipts block:^(BOOL succeeded, NSError *error) {
            if (succeeded){
                
                PFObject* lastReceipt = [fetchedReceipts firstObject];
                
                NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
                NSDate* lastReceiptCreatedAt = [lastReceipt createdAt];
                
                [defaults setObject:lastReceiptCreatedAt forKey:@"lastFetchTime"];
                [defaults synchronize];
                
                [self formatRefreshControlTitle];
            }

            [self fillTableFromLocalStorage];
            
            return;
        }];
    }
//    else{
//        receipts = nil;
//        [self fillTableFromLocalStorage];
//    }
}

-(IBAction)startRefresh:(id)sender
{
//    if (![sender isKindOfClass:[UIRefreshControl class]])
//        [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeNone];
    
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    NSDate* lastFetchTime = [defaults objectForKey:@"lastFetchTime"];

//    if ([PFUser currentUser])
//    {
//        [PFCloud callFunctionInBackground:@"fetchReceiptsByUser" withParameters:@{ @"lastFetchTime" : (lastFetchTime == nil ? @"" : lastFetchTime) } block:^(NSObject *result, NSError *error)
//         {
//             [self processReceiptsFetchData:result error:error];
//         }];
//        
//        return;
//    }
    
    [PFCloud callFunctionInBackground:@"fetchReceipts" withParameters:@{ @"installationId" : [[PFInstallation currentInstallation] installationId], @"lastFetchTime" : (lastFetchTime == nil ? @"" : lastFetchTime) } block:^(NSDictionary *result, NSError *error)
     {
         [self processReceiptsFetchData:result error:error];
     }];
}

- (void)formatRefreshControlTitle
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    NSDate* lastFetchTime = [defaults objectForKey:@"lastFetchTime"];
    if (lastFetchTime != nil){
        NSDateFormatter *dateFormatter=[[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"dd-MM-yyyy HH:mm"];
        
        NSString* title = [NSString stringWithFormat:@"last fetched at %@", [dateFormatter stringFromDate:lastFetchTime]];
        
        [[self refreshControl] setAttributedTitle:[[NSAttributedString alloc] initWithString:title]];
    }
    else
        [[self refreshControl] setAttributedTitle:[[NSAttributedString alloc] initWithString:@""]];
}

-(void)viewWillAppear:(BOOL)animated
{
    //    self.navigationController.navigationBar.hidden = NO;
    //    self.stackedLayout.layoutMargin = UIEdgeInsetsMake(60, 0.0, 0.0, 0.0);;
    //    self.exposedLayoutMargin = UIEdgeInsetsMake(60, 0.0, 0.0, 0.0);
    
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
    if (_shouldLoadReceipts == NO)
        return;
    
    _shouldLoadReceipts = NO;
    
    [self formatRefreshControlTitle];
    
    [self fillTableFromLocalStorage];

    [self startRefresh:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return receipts == nil ? 0 : [receipts count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ReceiptsTableCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ReceiptsTableCell" forIndexPath:indexPath];
    
    PFObject *receipt = [receipts objectAtIndex:indexPath.row];
    [cell buildFromReceipt:receipt];
    
    return cell;
}



// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}


// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView beginUpdates];
        [receipts removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [tableView endUpdates];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}


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

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue destinationViewController] isKindOfClass:[FullReceiptViewController class]])
    {
        FullReceiptViewController* frc = [segue destinationViewController];
        NSIndexPath *selectedRowIndex = [self.tableView indexPathForSelectedRow];
        PFObject *receipt = [receipts objectAtIndex:selectedRowIndex.row];
        [frc setReceiptToDisplay:receipt[@"receipt"]];

        frc.navigationItem.backBarButtonItem.title = @"Back";
        frc.navigationController.title = @"Back";
        
        self.navigationItem.backBarButtonItem.title = @"Back";
        self.navigationController.title = @"Back";
        
    }
}

@end
