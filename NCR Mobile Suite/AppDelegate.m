//
//  AppDelegate.m
//  NCR Mobile Suite
//
//  Created by Pavel Yankelevich on 1/28/15.
//  Copyright (c) 2015 NCR. All rights reserved.
//

#import "AppDelegate.h"
#import "MenuViewController.h"
#import "UIColor_Utils.h"
#import "SyncViewController.h"
#import "Parse/Parse.h"
#import "ParseFacebookUtils/PFFacebookUtils.h"
#import <ParseUI/ParseUI.h>
#import "SVProgressHUD.h"
#import "PayPal.h"

@interface AppDelegate ()<PayPalPaymentDelegate, PFLogInViewControllerDelegate, PFSignUpViewControllerDelegate>
{
    MenuViewController *menuViewController;
}
@property (nonatomic, strong) UIImageView *windowBackground;

@end

@implementation AppDelegate


-(void)initParse:(NSDictionary *)launchOptions
{
    PFACL *defaultACL = [PFACL ACL];
    // If you would like all objects to be private by default, remove this line.
    [defaultACL setPublicReadAccess:YES];
    
    [PFACL setDefaultACL:defaultACL withAccessForCurrentUser:YES];
    
    [Parse enableLocalDatastore];
    
    //Prod
    [Parse setApplicationId:@"GI0onNPgipudQrPflEVJJBQz83Ms9GuuaUXzIawS" clientKey:@"r1ch0MW8clfboCMxFSIkZqsxv8wPTXiU8f1LWAVd"];
    
    //Dev
    //[Parse setApplicationId:@"SNGu8bRK5nxTwGTh3qrvDzFE8tRbIarDGaRsKxwr" clientKey:@"W3CAAQRO4Xq2TqtDtvRgZKtYaQLrGIZsPnbOKCwp"];
    
    [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
    
    [PFImageView class];
    
    [PFTwitterUtils initializeWithConsumerKey:@"mtRTM5d2lVViR2JJ9ZpC75hXg" consumerSecret:@"6HnMg8YC0b8IZbJdl7VvBDDclw86XbP1EZlPIQfDyovvk0tTmn"];
    
    [PFFacebookUtils initializeFacebook];
}

-(void)prepareForPush:(UIApplication *)application
{
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
    if ([application respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        UIUserNotificationType userNotificationTypes = (UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound);
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:userNotificationTypes categories:nil];
        [application registerUserNotificationSettings:settings];
        [application registerForRemoteNotifications];
    } else
#endif
    {
        [application registerForRemoteNotificationTypes: (UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound)];
    }
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    [PayPal initializeWithAppID:@"APP-80W284485P519543T" forEnvironment:ENV_NONE];

    [self initParse:launchOptions];
    
    self.dynamicsDrawerViewController = (MSDynamicsDrawerViewController *)self.window.rootViewController;
    self.dynamicsDrawerViewController.delegate = self;
    
    [self.dynamicsDrawerViewController setRevealWidth:220 forDirection:MSDynamicsDrawerDirectionLeft];

    [self.dynamicsDrawerViewController addStylersFromArray:@[[MSDynamicsDrawerShadowStyler styler], [MSDynamicsDrawerResizeStyler styler]] forDirection:MSDynamicsDrawerDirectionLeft];
    [self.dynamicsDrawerViewController addStylersFromArray:@[[MSDynamicsDrawerResizeStyler styler], [MSDynamicsDrawerShadowStyler styler]] forDirection:MSDynamicsDrawerDirectionRight];

    
    menuViewController = [self.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"Menu"];
    
    menuViewController.dynamicsDrawerViewController = self.dynamicsDrawerViewController;
    [self.dynamicsDrawerViewController setDrawerViewController:menuViewController forDirection:MSDynamicsDrawerDirectionLeft];
    
//    SyncViewController *syncViewController = [self.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"SyncViewController"];
//    
//    menuViewController.dynamicsDrawerViewController = self.dynamicsDrawerViewController;
//    [self.dynamicsDrawerViewController setDrawerViewController:syncViewController forDirection:MSDynamicsDrawerDirectionRight];
    
    self.dynamicsDrawerViewController.paneDragRequiresScreenEdgePan = YES;
    self.dynamicsDrawerViewController.screenEdgePanCancelsConflictingGestures = YES;
    
    // Transition to the first view controller
    [menuViewController transitionToViewController:PaneViewControllerTypeReceipts];

//    [self.dynamicsDrawerViewController setPaneState:MSDynamicsDrawerPaneStateOpen inDirection:MSDynamicsDrawerDirectionRight];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = self.dynamicsDrawerViewController;
    [self.window makeKeyAndVisible];
    [self.window addSubview:self.windowBackground];
    [self.window sendSubviewToBack:self.windowBackground];

    [self prepareForPush:application];
    
    if (launchOptions != nil)
    {
        NSDictionary* userInfo = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
        if (userInfo != nil)
        {
            NSLog(@"Launched from push notification: %@", userInfo);
            
            //            int *pinCode = [[userInfo objectForKey:@"pinCode"] intValue];
            
//            UINavigationController* navController = (UINavigationController*)  self.window.rootViewController;
//            HostViewController* hostViewController = (HostViewController*)  [navController.viewControllers firstObject];
//            [hostViewController setShouldStartFromReceiptView:YES];
        }
    }

    
    return YES;
}

- (UIImageView *)windowBackground
{
    if (!_windowBackground) {
        UIColor *backColor = [UIColor colorWithHexString:@"#067000"];
        UIImage* back = [UIColor imageWithColor:backColor andSize:[[UIScreen mainScreen] bounds].size];
        _windowBackground = [[UIImageView alloc] initWithImage:back];
    }
    return _windowBackground;
}

#pragma mark - MSDynamicsDrawerViewControllerDelegate

- (void)dynamicsDrawerViewController:(MSDynamicsDrawerViewController *)drawerViewController mayUpdateToPaneState:(MSDynamicsDrawerPaneState)paneState forDirection:(MSDynamicsDrawerDirection)direction
{
//    NSLog(@"Drawer view controller may update to state `%@` for direction `%@`", [self descriptionForPaneState:paneState], [self descriptionForDirection:direction]);
}

- (void)dynamicsDrawerViewController:(MSDynamicsDrawerViewController *)drawerViewController didUpdateToPaneState:(MSDynamicsDrawerPaneState)paneState forDirection:(MSDynamicsDrawerDirection)direction
{
//    NSLog(@"Drawer view controller did update to state `%@` for direction `%@`", [self descriptionForPaneState:paneState], [self descriptionForDirection:direction]);
}

- (void)showLogin
{
    PFLogInViewController *logInController = [[PFLogInViewController alloc] init];
    logInController.delegate = self;
    //    logInController.signUpController.delegate = self;
    //
    //    logInController.emailAsUsername = YES;
    //    logInController.signUpController.emailAsUsername = YES;
    
    logInController.fields = (
                              PFLogInFieldsUsernameAndPassword |
                              PFLogInFieldsLogInButton |
                              PFLogInFieldsSignUpButton |
                              PFLogInFieldsPasswordForgotten |
                              PFLogInFieldsTwitter
                              | PFLogInFieldsFacebook
                              | PFLogInFieldsDismissButton
                              );
    
    //    logInController.facebookPermissions = [[NSArray alloc] initWithObjects:@"basic_info", @"email", @"user_birthday", nil];
    logInController.facebookPermissions = [[NSArray alloc] initWithObjects:@"public_profile", @"user_about_me", @"email", nil];
    
    logInController.view.backgroundColor = [UIColor colorWithRed:78.0 / 255.0 green:151.0 / 255.0 blue:31.0 / 255.0 alpha:1];
    logInController.signUpController.view.backgroundColor = [UIColor colorWithRed:78.0 / 255.0 green:151.0 / 255.0 blue:31.0 / 255.0 alpha:1];
    
    UILabel* loginLogo = [[UILabel alloc] init];
    UILabel* signUplogo = [[UILabel alloc] init];
    
    [loginLogo setTextColor:[UIColor whiteColor]];
    [signUplogo setTextColor:[UIColor whiteColor]];
    
    [loginLogo setText:@"NCR Mobile"];
    [loginLogo setFont:[UIFont fontWithName:@"AmericanTypewriter" size:48]];
    
    [signUplogo setText:@"NCR Mobile"];
    [signUplogo setFont:[UIFont fontWithName:@"AmericanTypewriter" size:48]];
    
    logInController.logInView.logo = loginLogo;
    logInController.signUpController.signUpView.logo = signUplogo;
    
    [self.dynamicsDrawerViewController presentViewController:logInController animated:YES completion:nil];
    
    logInController.signUpController.emailAsUsername = YES;
    logInController.signUpController.delegate = self;
    logInController.emailAsUsername = YES;
}

#pragma mark - LoginViewController

- (void)twitterRequest:(NSString*)requestUrl completionHandler:(void (^)(NSURLResponse* response, NSDictionary * data, NSError* connectionError)) handler
{
    //self.navigationItem.title = @"Twitter User";
    NSURL *verify = [NSURL URLWithString:requestUrl];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:verify];
    
    [[PFTwitterUtils twitter] signRequest:request];
    [NSURLConnection sendAsynchronousRequest:request queue:[[NSOperationQueue alloc] init] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError)
    {
        
        NSError*error;
        NSDictionary* json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
        
        handler(response, json, connectionError);
    }];
}

- (void)getSocialData:(PFUser *)user
{
    if ([PFFacebookUtils isLinkedWithUser:user])
    {
//        self.navigationItem.title = @"Facebook User";
        FBRequest *request = [FBRequest requestForMe];
        [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            if (!error) {
                // result is a dictionary with the user's Facebook data
                NSDictionary *userData = (NSDictionary *)result;
                
                NSString *facebookID = userData[@"id"];
                
                NSString *name = userData[@"name"];
                [menuViewController.headerView.name setText:name];

                //self.navigationItem.title = name;
                /*
                 NSString *location = userData[@"location"][@"name"];
                 NSString *gender = userData[@"gender"];
                 NSString *birthday = userData[@"birthday"];
                 NSString *relationship = userData[@"relationship_status"];
                 
                 NSURL *pictureURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large&return_ssl_resources=1", facebookID]];
                 
                 */
                
                NSURL *pictureURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large&return_ssl_resources=1", facebookID]];
                [menuViewController.headerView setAvatarImage:[UIImage imageWithData:[NSData dataWithContentsOfURL:pictureURL]]];
            }
        }];
    }
    else if ([PFTwitterUtils isLinkedWithUser:user])
    {
        [self twitterRequest:@"https://api.twitter.com/1.1/account/settings.json" completionHandler:^(NSURLResponse *response, NSDictionary *json, NSError *connectionError)
        {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [menuViewController.headerView.name setText:[NSString stringWithFormat:@"@%@", json[@"screen_name"]]];
            });
            
            NSString *url = [NSString stringWithFormat:@"https://api.twitter.com/1.1/users/show.json?screen_name=%@", json[@"screen_name"]];
            [self twitterRequest:url completionHandler:^(NSURLResponse *response, NSDictionary *data, NSError *connectionError) {
                NSString *normalSizePicture = data[@"profile_image_url"];
                normalSizePicture = [normalSizePicture stringByReplacingOccurrencesOfString:@"_normal.jpg" withString:@".jpg"];
                NSURL *pictureURL = [NSURL URLWithString:normalSizePicture];
                dispatch_queue_t backgroundQueue = dispatch_queue_create("com.mycompany.myqueue", 0);
                dispatch_async(backgroundQueue, ^{
                    NSData* imageData = [NSData dataWithContentsOfURL:pictureURL];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [menuViewController.headerView setAvatarImage:[UIImage imageWithData:imageData]];
                    });
                });
            }];
        }];
    }
    else{
        [menuViewController.headerView.name setText:user.username];
    }
}

- (void)logInViewController:(PFLogInViewController *)controller didLogInUser:(PFUser *)user {
    [self.dynamicsDrawerViewController dismissViewControllerAnimated:YES completion:nil];
    
    [self getSocialData:user];
    
//    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"exit"] style:UIBarButtonItemStylePlain target:self action:@selector(login:)];
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"lastFetchTime"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [menuViewController updateViewController:PaneViewControllerTypeReceipts];
//    [syncViewController performSelector:@selector(startRefresh:) withObject:self];
//    [receiptsViewController setShouldLoadReceipts:YES];
    
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeGradient];
    
    PFInstallation* installation = [PFInstallation currentInstallation];
    
    [PFCloud callFunctionInBackground:@"associateInstallationWithUser" withParameters:@{@"installationId" : [installation installationId]} block:^(NSString *result, NSError *error)
     {
         if (!error) {
             NSLog(@"Installation was associated with user");
         }
         else
             NSLog(@"Failed associate instalation with user");
         
         [SVProgressHUD dismiss];
     }];
    
    
    //    PFInstallation *installation = [PFInstallation currentInstallation];
    //    installation[@"user"] = [PFUser currentUser];
    //    [installation saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
    //        NSLog(@"Installation was associated with user");
    //        [SVProgressHUD dismiss];
    //
    //    }];
}

-(void)logInViewController:(PFLogInViewController *)logInController didFailToLogInWithError:(NSError *)error{
    [SVProgressHUD dismiss];
}

- (void)signUpViewController:(PFSignUpViewController *)signUpController didSignUpUser:(PFUser *)user
{
    [self.dynamicsDrawerViewController dismissViewControllerAnimated:YES completion:nil];
    
//    self.navigationItem.title = user.username;
//    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"exit"] style:UIBarButtonItemStylePlain target:self action:@selector(login:)];
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"lastFetchTime"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
//    [syncViewController performSelector:@selector(startRefresh:) withObject:self];
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeGradient];
    
//    [receiptsViewController setShouldLoadReceipts:YES];
    
    PFInstallation *installation = [PFInstallation currentInstallation];
    [PFCloud callFunctionInBackground:@"associateInstallationWithUser" withParameters:@{@"installationId" : [installation installationId]} block:^(NSString *result, NSError *error)
     {
         if (!error) {
             NSLog(@"Installation was associated with user");
         }
         else
             NSLog(@"Failed associate instalation with user");
         
         [SVProgressHUD dismiss];
     }];
    
    //    installation[@"user"] = [PFUser currentUser];
    //    [installation saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
    //        NSLog(@"Installation was associated with user");
    //
    //        [SVProgressHUD dismiss];
    //    }];
}

- (void)logInViewControllerDidCancelLogIn:(PFLogInViewController *)logInController {
    [SVProgressHUD dismiss];
    [self.dynamicsDrawerViewController dismissViewControllerAnimated:YES completion:nil];
}

-(BOOL)logInViewController:(PFLogInViewController *)logInController shouldBeginLogInWithUsername:(NSString *)username password:(NSString *)password
{
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeGradient];
    
    return YES;
}

-(void) checkRegistrationStatus
{
    PFUser *currentUser = [PFUser currentUser];
    if (currentUser == nil)
        return;
    
    [self getSocialData:currentUser];
}

-(void)loginOrLogout
{
    PFUser *currentUser = [PFUser currentUser];
    if (currentUser == nil)
    {
        [self showLogin];
    }
    else
    {
        [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeGradient];
        
        [PFUser logOut];
        
        [menuViewController.headerView reset];
        [menuViewController updateViewController:PaneViewControllerTypeReceipts];

//        [receiptsViewController setShouldLoadReceipts:YES];
//        
//        self.navigationItem.title = @"Anonymous";
//        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"enter"] style:UIBarButtonItemStylePlain target:self action:@selector(login:)];
        
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"lastFetchTime"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        PFQuery *query = [PFQuery queryWithClassName:@"Receipts"];
        [query fromLocalDatastore];
        [query includeKey:@"retailer"];
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
         {
             [PFObject unpinAllInBackground:objects block:^(BOOL succeeded, NSError *error) {
                 
                 PFInstallation *installation = [PFInstallation currentInstallation];
                 [installation removeObjectForKey:@"user"];
                 [installation saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                     NSLog(@"User unassociated with installation");
                     
                     [SVProgressHUD dismiss];
                     
//                     [syncViewController performSelector:@selector(startRefresh:) withObject:self];
//                     [receiptsViewController performSelector:@selector(startRefresh:) withObject:self];
                 }];
             }];
         }];
    }
}

#pragma mark - PayPal Delegate

- (void)paymentSuccessWithKey:(NSString *)payKey andStatus:(PayPalPaymentStatus)paymentStatus
{
    
}
- (void)paymentFailedWithCorrelationID:(NSString *)correlationID
{
}
- (void)paymentCanceled
{
}
- (void)paymentLibraryExit
{
}

-(void)connectPayPal{
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeGradient];
    [PFCloud callFunctionInBackground:@"getPayPalPreapprovalKey"
                       withParameters:@{}
                                block:^(NSString *result, NSError *error) {
                                    [SVProgressHUD dismiss];
                                    if (!error) {
                                        NSDictionary* response = (NSDictionary*)result;
                                        NSString *ack = response[@"responseEnvelope"][@"ack"];
                                        if ([ack compare:@"Success" options:NSCaseInsensitiveSearch] == NSOrderedSame){
                                            NSString* preapprovalKey = response[@"preapprovalKey"];
                                            [[PayPal getPayPalInst] setDelegate:self];
                                            [[PayPal getPayPalInst] preapprovalWithKey:preapprovalKey andMerchantName:@"NCR Corp."];
                                        }
                                        else{
                                            NSString* message = response[@"error"][0][@"message"];
                                            UIAlertView* av = [[UIAlertView alloc] initWithTitle:@"NCR Mobile Suite" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                                            [av show];
                                        }
                                    }
                                }];
}


#pragma mark - UIApplicationDelegate

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    return [FBAppCall handleOpenURL:url sourceApplication:sourceApplication withSession:[PFFacebookUtils session]];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [FBAppCall handleDidBecomeActiveWithSession:[PFFacebookUtils session]];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:deviceToken];
    [currentInstallation saveInBackground];
}


- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
//    UINavigationController* navController = (UINavigationController*)  self.window.rootViewController;
//    HostViewController* hostViewController = (HostViewController*)  [navController.viewControllers firstObject];
//    
//    [hostViewController newTicketWithPinCode:[[userInfo objectForKey:@"pinCode"] intValue]];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    
    [[PFFacebookUtils session] close];
}

@end
