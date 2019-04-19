//
//  ShareTemplate.h
//  SealMeeting
//
//  Created by Sin on 2019/4/2.
//  Copyright © 2019年 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ShareTemplate : NSObject
//获取 url 模板
+ (NSString *)getURLTemplate:(NSString *)roomId;
//获取 完整 模板
+ (NSString *)getWholeTemplate:(NSString *)roomId invitorName:(NSString *)name;
@end

NS_ASSUME_NONNULL_END
