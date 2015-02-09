//
//  ReceiptActivityItemProvider.m
//  NCR Receipts
//
//  Created by Pavel Yankelevich on 1/13/15.
//  Copyright (c) 2015 Pavel Yankelevich. All rights reserved.
//

#import "ReceiptActivityItemProvider.h"

@interface ReceiptActivityItemProvider()
{
    NSString* receipt;
}
@end

@implementation ReceiptActivityItemProvider

-(instancetype)initWithReceipt:(NSString*)_receipt
{
    receipt = [_receipt copy];
    
    return self;
}

- (id) activityViewController:(UIActivityViewController *)activityViewController itemForActivityType:(NSString *)activityType
{
    if ( [activityType isEqualToString:UIActivityTypeMail] )
        return receipt;

    if ( [activityType isEqualToString:UIActivityTypePrint] )
    {
        UIMarkupTextPrintFormatter *htmlFormatter = [[UIMarkupTextPrintFormatter alloc] initWithMarkupText:receipt];

        return htmlFormatter;
    }
    
    NSAttributedString* attrStr = [[NSAttributedString alloc] initWithData:[receipt dataUsingEncoding:NSUTF8StringEncoding] options:
                                   @{
                                     NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
                                     NSCharacterEncodingDocumentAttribute: [NSNumber numberWithInt:NSUTF8StringEncoding]
                                     } documentAttributes:nil error:nil];

    return attrStr;
}

- (id) activityViewControllerPlaceholderItem:(UIActivityViewController *)activityViewController {
    return @"";
}
@end
