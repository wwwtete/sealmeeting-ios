//
//  LoginHelper.m
//  SealMeeting
//
//  Created by 张改红 on 2019/3/12.
//  Copyright © 2019年 RongCloud. All rights reserved.
//

#import "LoginHelper.h"
@interface LoginHelper()<RongRTCRoomDelegate, RCConnectionStatusChangeDelegate>
@property (nonatomic, strong) Classroom *classroom;
@end

@implementation LoginHelper
+ (instancetype)sharedInstance {
    static LoginHelper *service = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        service = [[self alloc] init];
        [IMClient setRCConnectionStatusChangeDelegate:service];
    });
    return service;
}

#pragma mark - Api
- (void)login:(NSString *)roomId user:(NSString *)userName isObserver:(BOOL)observer disableCamera:(BOOL)disableCamera{
    NSLog(@"login start");
    [[ClassroomService sharedService] joinClassroom:roomId userName:userName isObserver:observer disableCamera:disableCamera  success:^(Classroom * _Nonnull classroom) {
        NSLog(@"login classroom success");
        self.classroom = classroom;
        __weak typeof(self) weakSelf = self;
        NSLog(@"connect im start");
        [IMClient connectWithToken:classroom.imToken success:^(NSString *userId) {
        } error:^(RCConnectErrorCode status) {
            NSLog(@"connect im error:%@",@(status));
            if (status != RC_CONN_REDIRECTED) {
                dispatch_main_async_safe(^{
                    NSLog(@"IM connect error");
                    if(weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(classroomDidJoinFail)]){
                        [weakSelf.delegate classroomDidJoinFail];
                    }
                });
            }
        } tokenIncorrect:^{
            NSLog(@"connect im token incorrect");
            dispatch_main_async_safe(^{
                if(weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(classroomDidJoinFail)]){
                    [weakSelf.delegate classroomDidJoinFail];
                }
            });
        }];
    } error:^(ErrorCode errorCode){
        NSLog(@"login classroom error:%@",@(errorCode));
            if (errorCode == ErrorCodeOverMaxUserCount) {
                if(self.delegate && [self.delegate respondsToSelector:@selector(classroomDidOverMaxUserCount)]){
                    [self.delegate classroomDidOverMaxUserCount];
                }
            }else{
                if(self.delegate && [self.delegate respondsToSelector:@selector(classroomDidJoinFail)]){
                    [self.delegate classroomDidJoinFail];
                }
            }
    }];
}

- (void)logout:(void (^)(void))success error:(void (^)(RongRTCCode code))error {
    NSLog(@"logout start");
    [[RTCService sharedInstance] leaveRongRTCRoom:[ClassroomService sharedService].currentRoom.roomId success:^{
        NSLog(@"leave rtc room success");
        [self leave:success error:error];
    } error:^(RongRTCCode code) {//todo
        NSLog(@"leave rtc room error:%@",@(code));
        //用户离开 RTC 成功，离开 classroom 失败，再次调用离开时，RTC会报 RongRTCCodeNotInRoom 错误
        if (code == RongRTCCodeNotInRoom) {
            [self leave:success error:error];
        }else{
            dispatch_main_async_safe(^{
                if (error) {
                    error(code);
                }
            });
        }
    }];
}

- (void)leave:(void (^)(void))success error:(void (^)(RongRTCCode code))error{
    [[ClassroomService sharedService] leaveClassroom:^{
        [[RCIMClient sharedRCIMClient] disconnect];
        dispatch_main_async_safe(^{
            if (success) {
                success();
            }
        });
    } error:^(ErrorCode errorCode) {
        dispatch_main_async_safe(^{
            [[RCIMClient sharedRCIMClient] disconnect];
            //当前用户不在房间或者房间不存在，直接告诉上层退出房间成功
            if(ErrorCodeUserNotExistInRoom == errorCode || ErrorCodeRoomNotExist == errorCode) {
                if(success) {
                    success();
                }
            }else {//否则就是正常返回失败
                if (error) {
                    error(errorCode);
                }
            }
        });
    }];
}
#pragma mark - RCConnectionStatusChangeDelegate
- (void)onConnectionStatusChanged:(RCConnectionStatus)status{
    if (status == ConnectionStatus_Connected) {
        NSLog(@"connect im success");
        [self joinRongRTCRoom];
    }
}

#pragma mark - Helper
- (void)joinRongRTCRoom{
    NSLog(@"join rtc room start");
    [[RTCService sharedInstance] joinRongRTCRoom:self.classroom.roomId success:^(RongRTCRoom * _Nonnull room) {
        NSLog(@"join rtc room success");
        dispatch_main_async_safe(^{
            if(self.delegate && [self.delegate respondsToSelector:@selector(classroomDidJoin:)]){
                [self.delegate classroomDidJoin:self.classroom];
            }
        });
    } error:^(RongRTCCode code) {
        NSLog(@"join rtc room error:%@",@(code));
        dispatch_main_async_safe(^{
            if (code == RongRTCCodeJoinRepeatedRoom || code == RongRTCCodeJoinToSameRoom) {
                if(self.delegate && [self.delegate respondsToSelector:@selector(classroomDidJoin:)]){
                    [self.delegate classroomDidJoin:self.classroom];
                }
            }else{
                if(self.delegate && [self.delegate respondsToSelector:@selector(classroomDidJoinFail)]){
                    [self.delegate classroomDidJoinFail];
                }
            }
        });
    }];
}
@end
