//
//  InviteListVIew.h
//  SealMeeting
//
//  Created by 张改红 on 2019/4/1.
//  Copyright © 2019 RongCloud. All rights reserved.
//

#import <UIKit/UIKit.h>
@class InviteListView;

typedef enum : NSUInteger {
    InviteListViewActionTagWechat,
    InviteListViewActionTagSMS,
    InviteListViewActionTagEmail,
    InviteListViewActionTagQRCode,
    InviteListViewActionTagCopyInfo,
} InviteListViewActionTag;
@protocol InviteListViewDelegate <NSObject>

- (void)inviteListView:(UIButton *)button didTapAtTag:(InviteListViewActionTag)tag;

@end
@interface InviteListView : UIView
@property (nonatomic, weak) id<InviteListViewDelegate> delegate;
@end
