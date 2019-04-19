//
//  VideoListView.h
//  SealMeeting
//
//  Created by liyan on 2019/3/5.
//  Copyright © 2019年 RongCloud. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface VideoListView : UIView

@property (nonatomic, assign) BOOL showAdminPrompt;

@property (nonatomic, assign) BOOL showSpeakerPrompt;


- (void)updateUserVideo:(NSString *)userId;

- (void)reloadVideoList;

- (void)showAdminPrompt:(BOOL)showAdminPrompt showSpeakerPrompt:(BOOL)showSpeakerPrompt;

@end

NS_ASSUME_NONNULL_END
