//
//  InviteListVIew.m
//  SealMeeting
//
//  Created by 张改红 on 2019/4/1.
//  Copyright © 2019 RongCloud. All rights reserved.
//

#import "InviteListView.h"
#import "WXApi.h"

#define InviteItemWidth 44
#define InviteItemSpace 25
@interface InviteListView()

@end
@implementation InviteListView
- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        [self setupSubviews];
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8];
    }
    return self;
}

- (void)setupSubviews{
    NSArray *titles = @[@"WeChat",@"SMS",@"Email",@"QRCode",@"CopyInfo"];
    NSArray *images = @[@"wechat",@"sms",@"email",@"qrcode",@"copy"];
    CGFloat topSpace = (UIScreenHeight - (InviteItemWidth*5+InviteItemSpace*4))/2;
    CGFloat leftSpace = (self.frame.size.width - InviteItemWidth)/2;
    NSArray *tags = @[@(InviteListViewActionTagWechat),@(InviteListViewActionTagSMS),@(InviteListViewActionTagEmail),@(InviteListViewActionTagQRCode),@(InviteListViewActionTagCopyInfo)];
    for (int i = 0; i < titles.count; i ++) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.tag = [tags[i] intValue];
        button.frame = CGRectMake(leftSpace,topSpace+InviteItemWidth*i+InviteItemSpace*i,InviteItemWidth, InviteItemWidth);
//        button.backgroundColor = [UIColor cyanColor];
        [button setImage:[UIImage imageNamed:images[i]] forState:UIControlStateNormal];
        button.imageEdgeInsets = UIEdgeInsetsMake(0,10,20,10);
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(-leftSpace, InviteItemWidth-13, self.frame.size.width, 13)];
        label.text = NSLocalizedStringFromTable(titles[i], @"SealMeeting", nil);
        label.textColor = [UIColor whiteColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont systemFontOfSize:11];
        [button addSubview:label];
        [button addTarget:self action:@selector(tap:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:button];
    }
}

- (void)tap:(UIButton *)btn{
    if (self.delegate && [self.delegate respondsToSelector:@selector(inviteListView:didTapAtTag:)]) {
        [self.delegate inviteListView:btn didTapAtTag:btn.tag];
    }
}
@end
