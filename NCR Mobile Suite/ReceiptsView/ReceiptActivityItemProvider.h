//
//  ReceiptActivityItemProvider.h
//  NCR Receipts
//
//  Created by Pavel Yankelevich on 1/13/15.
//  Copyright (c) 2015 Pavel Yankelevich. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ReceiptActivityItemProvider : UIActivityItemProvider<UIActivityItemSource>

-(instancetype)initWithReceipt:(NSString*)_receipt;

@end
