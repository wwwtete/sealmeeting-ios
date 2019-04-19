//
//  InviteHepler.h
//  SealMeeting
//
//  Created by 张改红 on 2019/4/2.
//  Copyright © 2019 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "InviteListView.h"
#import "WXApi.h"
@interface InviteHelper : NSObject <InviteListViewDelegate, WXApiDelegate>
+ (instancetype)sharedInstance;
@property (nonatomic, strong) UIViewController *baseVC;
@end

