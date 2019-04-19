//
//  ClassroomDefine.h
//  SealMeeting
//
//  Created by LiFei on 2019/3/19.
//  Copyright © 2019 RongCloud. All rights reserved.
//

#ifndef ClassroomDefine_h
#define ClassroomDefine_h

typedef NS_ENUM(NSUInteger, Role) {
    //主持人
    RoleAdmin = 1,
    //主讲人
    RoleSpeaker = 2,
    //参会人
    RoleParticipant = 3,
    //旁观者
    RoleObserver = 4,
};

typedef NS_ENUM(NSUInteger, DeviceType) {
    //麦克风
    DeviceTypeMicrophone = 0,
    //相机
    DeviceTypeCamera = 1,
};

#endif /* ClassroomDefine_h */
