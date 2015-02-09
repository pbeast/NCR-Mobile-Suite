//
//  ReceiptsTableCell.m
//  NCR Receipts
//
//  Created by Pavel Yankelevich on 12/23/14.
//  Copyright (c) 2014 Pavel Yankelevich. All rights reserved.
//

#import "ReceiptsTableCell.h"

@implementation ReceiptsTableCell

- (void)awakeFromNib {
    // Initialization code
}

-(NSString *)reuseIdentifier{
    return @"ReceiptsTableCell";
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)buildFromReceipt:(PFObject *)receipt
{
    PFObject *retailer  = receipt[@"retailer"];
    
//    [retailer fetchIfNeeded];
    
    [[self retailer] setText:retailer[@"name"]];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString* addr = receipt[@"storeAddress"];
        
        //[[self address] setNumberOfLines:0];
        [[self address] setText:addr];
        [[self address] sizeToFit];
    });
    
    [[self logo] setFile:retailer[@"logo"]];
    [[self logo] loadInBackground];
    
    [[self logo] setBackgroundColor:[UIColor clearColor]];
    
    //  [[[self logo] layer] setBorderWidth:1];
    [[[self logo] layer] setBorderColor:[[UIColor lightGrayColor] CGColor]];
    [[[self logo] layer] setCornerRadius:8];
    [[[self logo] layer] setShadowOffset:CGSizeMake(10, 0)];
    [[[self logo] layer] setShadowOpacity:1];
    [[[self logo] layer] setShadowRadius:8];
    [[[self logo] layer] setShadowColor:[[UIColor lightGrayColor] CGColor]];
    
    [[self logo] setClipsToBounds:NO];
    
    self.total.text = receipt[@"total"];
    
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *components = [cal components:(NSCalendarUnitEra|NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay) fromDate:[NSDate date]];
    NSDate *today = [cal dateFromComponents:components];
    components = [cal components:(NSCalendarUnitEra|NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay) fromDate:receipt.updatedAt];
    NSDate *otherDate = [cal dateFromComponents:components];
    
    NSDateFormatter *dateFormatter=[[NSDateFormatter alloc] init];
    if([today isEqualToDate:otherDate])
        [dateFormatter setDateFormat:@"HH:mm"];
    else
        [dateFormatter setDateFormat:@"dd-MM-yyyy"];
    
    self.date.text = [dateFormatter stringFromDate:receipt.createdAt];
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
}

@end
