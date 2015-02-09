//
//  MenuHeaderView.h
//  NCR Mobile Suite
//
//  Created by Pavel Yankelevich on 2/9/15.
//  Copyright (c) 2015 NCR. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "THLabel.h"

@protocol MenuHeaderViewDelegate <NSObject>

-(void)menuHeaderTapped;

@end

@interface MenuHeaderView : UIView

@property (weak, nonatomic) IBOutlet UIImageView *avatar;
@property (weak, nonatomic) IBOutlet THLabel *name;

@property (nonatomic) id<MenuHeaderViewDelegate> delegate;

-(void)resizeView;

-(instancetype)initWithFrame:(CGRect)frame andParentView:(UIView*)view;

- (IBAction)tapOnAvatar:(id)sender;

-(void)reset;

-(void)setAvatarImage:(UIImage *)avatarImage;

@end
