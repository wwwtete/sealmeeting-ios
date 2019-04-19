//
//  AdminTransferMessage.h
//  SealMeeting
//
//  Created by Sin on 2019/3/14.
//  Copyright © 2019年 RongCloud. All rights reserved.
//

#import <RongIMLib/RongIMLib.h>

#define AdminTransferMessageIdentifier @"SC:ATMsg"
//主持人变更消息，当主持人变成功变更为另一个人时触发
@interface AdminTransferMessage : RCMessageContent
@property (nonatomic, copy) NSString *operatorId;
@property (nonatomic, copy) NSString *toUserId;
@end


