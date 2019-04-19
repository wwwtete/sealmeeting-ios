//
//  ShareTemplate.m
//  SealMeeting
//
//  Created by Sin on 2019/4/2.
//  Copyright © 2019年 RongCloud. All rights reserved.
//

#import "ShareTemplate.h"

@implementation ShareTemplate
//获取 url 模板
+ (NSString *)getURLTemplate:(NSString *)roomId {
    return [NSString stringWithFormat:@"https://sealmeeting.rongcloud.cn/sealmeeting/?mId=%@&p=%@&encode=1&locale=zh_cn",roomId,roomId];
}
//获取 完整 模板
+ (NSString *)getWholeTemplate:(NSString *)roomId invitorName:(NSString *)name{
    NSString *url = [self getURLTemplate:roomId];
    return [NSString stringWithFormat:@"%@ 邀请你加入 SealMeeting 视频会议，点击 %@ 立即加入",name,url];
}

@end
