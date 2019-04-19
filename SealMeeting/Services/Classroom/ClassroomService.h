//
//  ClassroomService.h
//  SealMeeting
//
//  Created by LiFei on 2019/2/27.
//  Copyright © 2019 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RongIMLib/RongIMLib.h>
#import "Classroom.h"
#import "RoomMember.h"
#import "ErrorCode.h"
#import "ApplySpeechResultMessage.h"
#import "ClassroomDefine.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ClassroomDelegate <NSObject>
@optional
- (void)roomDidLeave;
- (void)memberDidJoin:(RoomMember *)member;
- (void)memberDidLeave:(RoomMember *)member;
- (void)memberDidKick:(RoomMember *)member;
//转让主持人，主持人收到的回调
- (void)adminDidTransfer:(RoomMember *)oldAdmin newAdmin:(RoomMember *)newAdmin;
//除降级外其它角色变化
- (void)roleDidChange:(Role)role
              forUser:(RoomMember *)member;
//设备打开/关闭回调
- (void)deviceDidEnable:(BOOL)enable
                   type:(DeviceType)type
                forUser:(RoomMember *)member operator:(NSString *)operatorId;
//主持人请求用户打开设备的回调，主持人关闭用户设备没有回调。
- (void)deviceDidInviteEnable:(DeviceType)type ticket:(NSString *)ticket;
- (void)deviceInviteEnableDidApprove:(RoomMember *)member
                          type:(DeviceType)type;
- (void)deviceInviteEnableDidReject:(RoomMember *)member
                         type:(DeviceType)type;
//旁观者申请成为参会人的回调
- (void)upgradeDidApply:(RoomMember *)member ticket:(NSString *)ticket overMaxCount:(BOOL)isOver;
//旁观者申请成为参会人，主持人接受或者拒绝的回调
- (void)applyDidApprove;
- (void)applyDidReject;
- (void)applyDidFailed:(ErrorCode)code;
//主持人邀请旁观者成为参会人的回调
- (void)upgradeDidInvite:(NSString *)ticket;
//主持人邀请旁观者成为参会人，旁观者接受或者拒绝的回调
- (void)inviteDidApprove:(RoomMember *)member;
- (void)inviteDidReject:(RoomMember *)member;
//旁观者申请成为参会人/主持人邀请旁观者成为参会人，超时没有回应的回调
- (void)ticketDidExpire:(NSString *)ticket;
//只有创建者才能收到
- (void)whiteboardDidCreate:(Whiteboard *)board;
- (void)whiteboardDidDelete:(Whiteboard *)boardId;
//显示白板的回调
- (void)whiteboardDidDisplay:(NSString *)boardId;
//显示主讲人的回调
- (void)speakerDidDisplay;
//显示主持人的回调
- (void)adminDidDisplay;
//显示共享屏幕的回调
- (void)sharedScreenDidDisplay:(NSString *)userId;
//显示空白
- (void)noneDidDisplay;
//
- (void)errorDidOccur:(ErrorCode)code;
@end

@interface ClassroomService : NSObject
@property (nonatomic, strong, nullable) Classroom *currentRoom;
@property (nonatomic, weak) id<ClassroomDelegate> classroomDelegate;

+ (instancetype)sharedService;

#pragma mark - IM
- (void)registerCommandMessages;
- (BOOL)isHoldMessage:(RCMessage *)message;

#pragma mark - HTTP
- (void)joinClassroom:(NSString *)roomId
             userName:(NSString *)userName
           isObserver:(BOOL)observer
        disableCamera:(BOOL)disableCamera
              success:(void (^)(Classroom *classroom))successBlock
                error:(void (^)(ErrorCode errorCode))errorBlock;
- (void)leaveClassroom:(void (^)(void))successBlock
                 error:(void (^)(ErrorCode errorCode))errorBlock;;
- (void)getWhiteboardList:(void (^)( NSArray <Whiteboard *> * _Nullable boardList))completeBlock;

#pragma mark 角色权限相关，仅主持人有权限
//将参会人降级为旁观者
- (void)downgradeMembers:(NSArray <NSString *> *)members;
//邀请旁观者升级为参会人
- (void)inviteUpgrade:(NSString *)userId;
//指定参会人为主讲人
- (void)assignSpeaker:(NSString *)userId;
//转让主持人
- (void)transferAdmin:(NSString *)userId;
//同意旁观者升级为参会人（对应 applyUpgrade）
- (void)approveUpgrade:(NSString *)ticket;
//拒绝旁观者升级为参会人（对应 applyUpgrade）
- (void)rejectUpgrade:(NSString *)ticket;
- (void)kickMember:(NSString *)userId;
- (void)enableDevice:(BOOL)enable
                type:(DeviceType)type
             forUser:(NSString *)userId;
#pragma mark 教室显示相关，仅主持人/主讲人有权限
- (void)createWhiteboard;
- (void)deleteWhiteboard:(NSString *)boardId;
- (void)displayWhiteboard:(NSString *)boardId;
- (void)displaySpeaker;
- (void)displayAdmin;
#pragma mark 操作当前用户设备状态，仅主持人/主讲人/参会人有权限
- (void)enableDevice:(BOOL)enable
            withType:(DeviceType)type;
//用户同意主持人打开设备
- (void)approveEnableDevice:(NSString *)ticket;
//用户拒绝主持人打开设备
- (void)rejectEnableDevice:(NSString *)ticket;
#pragma mark 旁观者升级相关，仅旁观者有权限
//申请成为参会人
- (void)applyUpgrade;
//同意主持人邀请自己成为参会人（对应 inviteUpgrade）
- (void)approveInvite:(NSString *)ticket;
//拒绝主持人邀请自己成为参会人（对应 inviteUpgrade）
- (void)rejectInvite:(NSString *)ticket;
#pragma mark - Util
- (NSString *)generateWhiteboardURL:(NSString *)boardId;
@end

NS_ASSUME_NONNULL_END
