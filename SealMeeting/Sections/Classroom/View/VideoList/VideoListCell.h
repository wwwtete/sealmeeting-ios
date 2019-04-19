//
//  VideoListCell.h
//  SealMeeting
//
//  Created by liyan on 2019/3/5.
//  Copyright © 2019年 RongCloud. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RoomMember.h"

NS_ASSUME_NONNULL_BEGIN

@interface VideoListCell : UITableViewCell

@property (nonatomic, strong) UIView *videoView;

@property (nonatomic, strong) UILabel *WaitLable;

- (void)setModel:(RoomMember *)member showAdminPrompt:(BOOL)adminPrompt showSpeakerPrompt:(BOOL)speakerPrompt;

- (void)renderVideo:(RoomMember *)member;

- (void)cancelVideo;

@end

NS_ASSUME_NONNULL_END
