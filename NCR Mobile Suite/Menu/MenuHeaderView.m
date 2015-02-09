//
//  MenuHeaderView.m
//  NCR Mobile Suite
//
//  Created by Pavel Yankelevich on 2/9/15.
//  Copyright (c) 2015 NCR. All rights reserved.
//

#import "MenuHeaderView.h"

#define kShadowColor1		[UIColor blackColor]
#define kShadowColor2		[UIColor colorWithWhite:0.0 alpha:0.75]
#define kShadowOffset		CGSizeMake(0.0, UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 4.0 : 2.0)
#define kShadowBlur			(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 10.0 : 5.0)

@interface MenuHeaderView()
{
    UIView* parentView;
}

@end

@implementation MenuHeaderView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

-(instancetype)initWithFrame:(CGRect)frame andParentView:(UIView*)view
{
    self = [super initWithFrame:frame];
    
    self.name.shadowColor = kShadowColor1;
    self.name.shadowOffset = kShadowOffset;
    self.name.shadowBlur = kShadowBlur;
    
    parentView = view;
    
    return self;
}

-(void)reset
{
    [[self avatar] setImage:[UIImage imageNamed:@"anonymous-user"]];
    [[self avatar] setContentMode:UIViewContentModeScaleAspectFit];
    [[self name] setText:@"Tap here to login..."];
}

-(void)setAvatarImage:(UIImage *)avatarImage
{
    [[self avatar] setContentMode:UIViewContentModeScaleAspectFill];
    [[self avatar] setImage:avatarImage];
}


- (IBAction)tapOnAvatar:(id)sender {
    if ([self delegate])
         [[self delegate] menuHeaderTapped];
}

-(void)resizeView
{
    CGRect pf = [parentView frame];
    CGRect sf = [self frame];
    
    sf.size.width = pf.size.width;
    
    self.frame = sf;
}


@end
