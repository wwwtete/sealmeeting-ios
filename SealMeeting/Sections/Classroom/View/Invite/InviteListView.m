//
//  InviteListVIew.m
//  SealMeeting
//
//  Created by 张改红 on 2019/4/1.
//  Copyright © 2019 RongCloud. All rights reserved.
//

#import "InviteListView.h"
#import "WXApi.h"

#define InviteItemWidth 55
#define VerticalSpace 30
#define HorizontalSpace 51
#define ImageWidth 32
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
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 50)];
    titleLabel.text = NSLocalizedStringFromTable(@"InviteTitle", @"SealMeeting", nil);
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [UIFont systemFontOfSize:15];
    [self addSubview:titleLabel];
    NSArray *titles = @[@"WeChat",@"SMS",@"Email",@"QRCode",@"CopyInfo"];
    NSArray *images = @[@"wechat",@"sms",@"email",@"qrcode",@"copy"];
    CGFloat topSpace = 60;
    CGFloat leftSpace = (self.frame.size.width - InviteItemWidth*2-HorizontalSpace)/2;
    NSArray *tags = @[@(InviteListViewActionTagWechat),@(InviteListViewActionTagSMS),@(InviteListViewActionTagEmail),@(InviteListViewActionTagQRCode),@(InviteListViewActionTagCopyInfo)];
    for (int i = 0; i < titles.count; i ++) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.tag = [tags[i] intValue];
        button.frame = CGRectMake(leftSpace+(i%2)*(HorizontalSpace+InviteItemWidth),(i/2)*(InviteItemWidth+VerticalSpace)+topSpace,InviteItemWidth, InviteItemWidth);
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake((InviteItemWidth-ImageWidth)/2, 0, ImageWidth, ImageWidth)];
        imageView.image = [UIImage imageNamed:images[i]];
        [button addSubview:imageView];
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(-10, InviteItemWidth-15, button.frame.size.width+20, 15)];
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
