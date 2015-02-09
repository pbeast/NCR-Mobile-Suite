//
//  ViewController.h
//  NCR Receipts
//
//  Created by Pavel Yankelevich on 12/12/14.
//  Copyright (c) 2014 Pavel Yankelevich. All rights reserved.
//

#import <UIKit/UIKit.h>

@implementation UIViewController (RecursiveDescription)

-(NSString*)recursiveDescription
{
    NSMutableString *description = [NSMutableString stringWithFormat:@"\n"];
    [self addDescriptionToString:description indentLevel:0];
    return description;
}

-(void)addDescriptionToString:(NSMutableString*)string indentLevel:(NSInteger)indentLevel
{
    NSString *padding = [@"" stringByPaddingToLength:indentLevel withString:@" " startingAtIndex:0];
    [string appendString:padding];
    [string appendFormat:@"%@, %@",[self debugDescription],NSStringFromCGRect(self.view.frame)];
    
    for (UIViewController *childController in self.childViewControllers)
    {
        [string appendFormat:@"\n%@>",padding];
        [childController addDescriptionToString:string indentLevel:indentLevel + 1];
    }
}

@end

@interface SyncViewController : UIViewController


@end

