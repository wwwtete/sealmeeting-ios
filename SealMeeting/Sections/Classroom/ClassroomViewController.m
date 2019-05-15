//
//  ClassViewController.m
//  SealMeeting
//
//  Created by LiFei on 2019/2/27.
//  Copyright © 2019 RongCloud. All rights reserved.
//

#import "ClassroomViewController.h"
#import "ClassroomTitleView.h"
#import "ToolPanelView.h"
#import "RecentSharedView.h"
#import "PersonListView.h"
#import "VideoListView.h"
#import "MainContainerView.h"
#import "ChatAreaView.h"
#import "RTCService.h"
#import "UpgradeDidApplyView.h"
#import "UIView+MBProgressHUD.h"
#import "WhiteboardControl.h"
#import "Classroom.h"
#import "ClassroomService.h"
#import "NormalAlertView.h"
#import "LoginHelper.h"
#import "WhiteboardPopupView.h"
#import "InviteListView.h"
#import "InviteHelper.h"
#import <MBProgressHUD/MBProgressHUD.h>
#import "VideoMaskView.h"
#define ToolPanelViewWidth    49
#define TitleViewHeight  64
#define RecentSharedViewWidth  240
#define PersonListViewWidth    240
#define VideoListViewWidth    112
#define InviteViewWidth 240
@interface ClassroomViewController ()<ClassroomTitleViewDelegate, ToolPanelViewDelegate, RongRTCRoomDelegate, WhiteboardControlDelegate, ClassroomDelegate, RecentSharedViewDelegate, UpgradeDidApplyViewDelegate,MainContainerViewDelegate,VideoListViewDelegate,UIGestureRecognizerDelegate>
@property (nonatomic, strong) ClassroomTitleView *titleView;
@property (nonatomic, strong) ToolPanelView *toolPanelView;
@property (nonatomic, strong) RecentSharedView *recentSharedView;
@property (nonatomic, strong) PersonListView *personListView;
@property (nonatomic, strong) VideoListView *videoListView;
@property (nonatomic, strong) MainContainerView *containerView;
@property (nonatomic, strong) WhiteboardControl *wBoardCtrl;
@property (nonatomic, strong) ChatAreaView *chatAreaView;
@property (nonatomic, strong) InviteListView *inviteView;
@property (nonatomic, strong) WhiteboardPopupView *popupView;
@property (nonatomic, strong) VideoMaskView *maskView;
@end

@implementation ClassroomViewController

#pragma mark - Life cycle
- (void)viewDidLoad {
    self.view.backgroundColor = [UIColor colorWithHexString:@"1C272A" alpha:1];
    [super viewDidLoad];
    [self addSubviews];
    [self bindDelegates];
    [self publishStream];
    [self renderMainContainerView];
    UITapGestureRecognizer *tapGes = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGesture:)];
    [self.view addGestureRecognizer:tapGes];
    tapGes.delegate = self;
    [self showRoleHud];
    [self registerNotification];
    [[RTCService sharedInstance] useSpeaker:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self refreshWboardFrame];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self showInviteView:NO];
}

#pragma mark - UIGestureRecognizerDelegate
-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch{
    if ([touch.view isDescendantOfView:self.personListView] || [touch.view isDescendantOfView:self.recentSharedView] || [touch.view isDescendantOfView:self.inviteView] || [touch.view isDescendantOfView:self.videoListView] || [touch.view isDescendantOfView:self.popupView]) {
        return NO;
    }
    if ([touch.view isDescendantOfView:self.wBoardCtrl.wbView] || [touch.view isDescendantOfView:self.containerView] || [touch.view isDescendantOfView:self.popupView]) {
        [self tapGesture:(UITapGestureRecognizer *)gestureRecognizer];
    }
    return YES;
}

#pragma mark - RongRTCRoomDelegate
- (void)didPublishStreams:(NSArray <RongRTCAVInputStream *>*)streams {
    NSString *displayUserId = [ClassroomService sharedService].currentRoom.currentDisplayURI;
    for (RongRTCAVInputStream *stream in streams) {
        if ([stream.userId isEqualToString:displayUserId]) {
            [self renderMainContainerView];
        }
        [self.videoListView updateUserVideo:stream.userId];
    }
}
- (void)didConnectToStream:(RongRTCAVInputStream *)stream {
    NSLog(@"didConnectToStream userId:%@ streamID:%@",stream.userId,stream.userId);
}

- (void)didReportFirstKeyframe:(RongRTCAVInputStream *)stream {
    NSLog(@"didReportFirstKeyframe userId:%@ streamID:%@",stream.userId,stream.userId);
}

#pragma mark - ClassroomTitleViewDelegate
- (void)classroomTitleView:(UIButton *)button didTapAtTag:(ClassroomTitleViewActionTag)tag {
    [self.chatAreaView.inputBarControl setInputBarStatus:InputBarControlStatusDefault];
    switch (tag) {
        case ClassroomTitleViewActionTagInviteUser:
            [self showInviteView:YES];
            break;
        case ClassroomTitleViewActionTagSwitchCamera:
            [[RTCService sharedInstance] switchCamera];
            
            break;
        case ClassroomTitleViewActionTagMicrophone:
            [[RTCService sharedInstance] setMicrophoneDisable:button.selected];
            [[ClassroomService sharedService] enableDevice:!button.selected withType:DeviceTypeMicrophone];
            break;
        case ClassroomTitleViewActionTagCamera:
            [[RTCService sharedInstance] setCameraDisable:button.selected];
            [[ClassroomService sharedService] enableDevice:!button.selected withType:DeviceTypeCamera];
            
            break;
        case ClassroomTitleViewActionTagMute:
            [[RTCService sharedInstance] useSpeaker:!button.selected];
            break;
        case ClassroomTitleViewActionTagHangup:
        {
            [NormalAlertView showAlertWithTitle:NSLocalizedStringFromTable(@"LeaveRoom", @"SealMeeting", nil) leftTitle:NSLocalizedStringFromTable(@"Cancel", @"SealMeeting", nil) rightTitle:NSLocalizedStringFromTable(@"Leave", @"SealMeeting", nil) cancel:^{
                
            } confirm:^{
                SealMeetingLog(@"ActionTagHangup");
                MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                [[LoginHelper sharedInstance] logout:^{
                    [hud hideAnimated:YES];
                    [self dismissMaskViewEvent];
                    [self dismissViewControllerAnimated:NO completion:^{
                        [self.titleView stopDurationTimer];
                    }];
                } error:^(RongRTCCode code) {
                    [hud hideAnimated:YES];
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:NSLocalizedStringFromTable(@"LeaveFail", @"SealMeeting", nil) delegate:nil cancelButtonTitle:NSLocalizedStringFromTable(@"Cancel", @"SealMeeting", nil) otherButtonTitles:nil];
                    [alertView show];
                }];
            }];
        }
            break;
            
        default:
            break;
    }
}

#pragma mark - MainContainerViewDelegate
- (void)mainContainerView:(MainContainerView *)view fullScreen:(BOOL)isFull {
    [self renderMainContainerView];
}

- (void)mainContainerView:(MainContainerView *)view scale:(CGFloat)scale {
    [[RTCService sharedInstance] clipVideoInView:self.containerView.videoView scale:scale];
    [self.view showHUDMessage:[NSString stringWithFormat:NSLocalizedStringFromTable(@"RecentSharedScale", @"SealMeeting", nil),(int)(scale*100)]];
}

#pragma mark - VideoListViewDelegate
- (void)videoListView:(VideoListView *)view didTap:(RoomMember *)member {
    [self removeMaskViewIfNeed];
    NSString *currentMaskUserId = member.userId;
    NSString *lastMaskUserId = [ClassroomService sharedService].currentRoom.currentMaskUserId;
    [ClassroomService sharedService].currentRoom.currentMaskUserId = currentMaskUserId;
    VideoMaskView *maskV = [[VideoMaskView alloc] initWithFrame:self.containerView.videoView.frame];
    [maskV addDismisTarget:self action:@selector(dismissMaskViewEvent)];
    
    Classroom *room = [ClassroomService sharedService].currentRoom;
    if([member.userId isEqualToString:room.currentDisplayURI]) {
        return;
    }
    if([[ClassroomService sharedService].currentRoom.currentMemberId isEqualToString:member.userId]) {
        [[RTCService sharedInstance] renderLocalVideoOnView:maskV.maskVideoView cameraEnable:room.currentMember.cameraEnable];
    }else {
        [[RTCService sharedInstance] renderRemoteVideoOnView:maskV.maskVideoView forUser:member.userId];
    }
    CGPoint center = [self.view convertPoint:self.containerView.videoView.center fromView:self.containerView];
    maskV.center = center;
    self.maskView = maskV;
    [self.view addSubview:maskV];
    [self.videoListView updateUserVideo:lastMaskUserId];
    [self.videoListView updateUserVideo:currentMaskUserId];
}

- (void)dismissMaskViewEvent {
    NSString *currentMaskUserId = [ClassroomService sharedService].currentRoom.currentMaskUserId ;
    if(currentMaskUserId) {
        [self.videoListView updateUserVideo:currentMaskUserId];
    }
    [ClassroomService sharedService].currentRoom.currentMaskUserId = nil;
    [self removeMaskViewIfNeed];
}

- (void)removeMaskViewIfNeed {
    [self.maskView removeFromSuperview];
}

- (void)cancelRenderMaskViewIfNeed {
    NSString *curDisplayUri = [ClassroomService sharedService].currentRoom.currentDisplayURI;
    NSString *curMaskUserId = [ClassroomService sharedService].currentRoom.currentMaskUserId;
    if([curMaskUserId isEqualToString:curDisplayUri]) {
        [self.maskView cancelRenderView];
    }
}


#pragma mark - ToolPanelViewDelegate
- (void)toolPanelView:(UIButton *)button didTapAtTag:(ToolPanelViewActionTag)tag {
    [self hideAllSubviewsOfToolPanelView];
    switch (tag) {
        case ToolPanelViewActionTagWhiteboard:
            if (button.selected) {
                self.popupView = [[WhiteboardPopupView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.toolPanelView.frame)+6, LLeftToolViewTop-(44-LLeftButtonWidht)/2, 97, 44) shapePointY:44/2 items:@[@"新建白板"] inView:self.view didSelectItem:^(NSInteger index, NSString *item) {
                    switch (index) {
                        case 0:
                            [self.toolPanelView foldToolPanelView];
                            [[ClassroomService sharedService] createWhiteboard];
                            break;
                        default:
                            break;
                    }
                }];
            }
            break;
        case ToolPanelViewActionTagRecentlyShared: {
            if(button.selected) {
                [[RTCService sharedInstance] refreshCurrentImage];
                [self showRecentSharedView];
                [self.recentSharedView reloadDataSource];
            }else {
                [self hideRecentSharedView];
            }
        }
            break;
        case ToolPanelViewActionTagOnlinePerson:
            button.selected ? [self showPersonListView] : [self hidePersonListView];
            break;
        case ToolPanelViewActionTagVideoList:
            break;
        case ToolPanelViewActionTagClassNews:
            button.selected ? [self showChatAreaView] : [self hideChatAreaView];
            break;
        default:
            
            break;
    }
    [self refreshWboardFrame];
}

- (void)hideAllSubviewsOfToolPanelView {
    [self hideRecentSharedView];
    [self hidePersonListView];
    [self hideChatAreaView];
    [self showInviteView:NO];
    [self.popupView destroy];
}

#pragma mark - RecentSharedViewDelegate
- (void)recentSharedViewCellTap:(id)recentShared {
    if ([recentShared isKindOfClass:[Whiteboard class]]) {
        [[RTCService sharedInstance] cancelRenderVideoInView:self.containerView.videoView];
        Whiteboard *whiteBoard = (Whiteboard *)recentShared;
        [self displayWhiteboard:whiteBoard.boardId];
        [[ClassroomService sharedService] displayWhiteboard:whiteBoard.boardId];
        [self.videoListView showAdminPrompt:NO showSpeakerPrompt:NO];
        
    } else if ([recentShared isKindOfClass:[RoomMember class]]) {
        RoomMember *member = (RoomMember *)recentShared;
        [self.wBoardCtrl hideBoard];
        [self.containerView containerViewRenderView:member];
        switch (member.role) {
            case RoleAdmin:
                [[ClassroomService sharedService] displayAdmin];
                break;
            case RoleSpeaker:
                [[ClassroomService sharedService] displaySpeaker];
                break;
            default:
                break;
        }
    }
}

#pragma mark - UpgradeDidApplyViewDelegate
- (void)upgradeDidApplyView:(UpgradeDidApplyView *)topView didTapAtTag:(UpgradeDidApplyViewActionTag)tag {
    if (tag == UpgradeDidApplyViewAccept) {
        [[ClassroomService sharedService] approveUpgrade:topView.ticket];
    }else {
        [[ClassroomService sharedService] rejectUpgrade:topView.ticket];
    }
    [self dismissTopAlertView:topView];
}

#pragma mark - WhiteboardControlDelegate

- (void)didTurnPage:(NSInteger)pageNum {
    
}

- (void)whiteboardViewDidChangeZoomScale:(float)scale{
    [self.view showHUDMessage:[NSString stringWithFormat:NSLocalizedStringFromTable(@"RecentSharedScale", @"SealMeeting", nil),(int)(scale*100)]];
}
#pragma mark - ClassroomDelegate
- (void)roomDidLeave {
    NSLog(@"roomDidLeave");
    if ([RTCService sharedInstance].rtcRoom) {
        [[RTCService sharedInstance] leaveRongRTCRoom:[ClassroomService sharedService].currentRoom.roomId success:^{
            
        } error:^(RongRTCCode code) {
            
        }];
        [[RCIMClient sharedRCIMClient] disconnect];
    }
    [self dismissMaskViewEvent];
    [self dismissViewControllerAnimated:NO completion:^{
        [self.titleView stopDurationTimer];
    }];
}

- (void)memberDidJoin:(RoomMember *)member {
    NSLog(@"memberDidJoin %@",member);
    [self.videoListView reloadVideoList];
    [self.personListView reloadPersonList];
    if (member.role == RoleSpeaker || member.role == RoleAdmin) {
        [self.recentSharedView reloadDataSource];
    }
}

- (void)memberDidLeave:(RoomMember *)member {
    NSLog(@"memberDidLeave %@",member);
    [self.videoListView reloadVideoList];
    [self.personListView reloadPersonList:member tag:RefreshPersonListTagRemove];
    if (member.role == RoleSpeaker || member.role == RoleAdmin) {
        [self.recentSharedView reloadDataSource];
    }
}

- (void)memberDidKick:(RoomMember *)member {
    NSLog(@"memberDidKick %@",member);
    if ([ClassroomService sharedService].currentRoom.currentMember.role == RoleAdmin) {
        [self.view showHUDMessage:[NSString stringWithFormat:NSLocalizedStringFromTable(@"YouDeletePersonSuccess", @"SealMeeting", nil),member.name]];
    }
    [self.videoListView reloadVideoList];
    [self.personListView reloadPersonList:member tag:RefreshPersonListTagRemove];
    if (member.role == RoleSpeaker || member.role == RoleAdmin) {
        [self.recentSharedView reloadDataSource];
    }
    if (self.containerView.member.role == member.role) {
        [self.containerView cancelRenderView];
    }
}

- (void)errorDidOccur:(ErrorCode)code {
    NSLog(@"errorDidOccur %@",@(code));
    if (code != ErrorCodeSuccess) {
        if (code == ErrorCodeOverMaxUserCount) {
            [self.view showHUDMessage:NSLocalizedStringFromTable(@"ErrorCodeOverMaxUserCount", @"SealMeeting", nil)];
        }else {
            [self.view showHUDMessage:NSLocalizedStringFromTable(@"Error", @"SealMeeting", nil)];
        }
    }
}

- (void)roleDidChange:(Role)role forUser:(RoomMember *)member {
    NSLog(@"roleDidChange:%@ member:%@",@(role),member);
    RoomMember *curMember = [ClassroomService sharedService].currentRoom.currentMember;
    switch (role) {
        case RoleAdmin:
            if ([curMember.userId isEqualToString:member.userId]) {
                [self.view showHUDMessage:NSLocalizedStringFromTable(@"YouTransfer", @"SealMeeting", nil)];
            }
            break;
        case RoleSpeaker:
            if (curMember.role == RoleAdmin) {
                [self.view showHUDMessage:[NSString stringWithFormat:NSLocalizedStringFromTable(@"YouSetSpeakerSuccess", @"SealMeeting", nil),member.name]];
            }else {
                if ([curMember.userId isEqualToString:member.userId]) {
                    [self.view showHUDMessage:NSLocalizedStringFromTable(@"YouSpeaker", @"SealMeeting", nil)];
                }
            }
            break;
        case RoleParticipant:
            //申请发言和邀请升级都会走.转让主持人，老主持人变成参会人不走这里
            if ([curMember.userId isEqualToString:member.userId]) {
                [self.view showHUDMessage:NSLocalizedStringFromTable(@"YouParticipant", @"SealMeeting", nil)];
                [[RTCService sharedInstance] setCameraDisable:NO];
                [[RTCService sharedInstance] setMicrophoneDisable:NO];
                [[RTCService sharedInstance] publishLocalUserDefaultAVStream];
                [self.titleView refreshTitleView];
            }else {
                [self.view showHUDMessage:[NSString stringWithFormat:NSLocalizedStringFromTable(@"PersonParticipant", @"SealMeeting", nil),member.name]];
            }
            break;
        case RoleObserver:
            if (curMember.role == RoleAdmin) {
                [self.view showHUDMessage:[NSString stringWithFormat:NSLocalizedStringFromTable(@"YouSetObserverSuccess", @"SealMeeting", nil),member.name]];
            } else {
                if ([curMember.userId isEqualToString:member.userId]) {
                    [self.titleView refreshTitleView];
                    [self hideRecentSharedView];
                    [self.view showHUDMessage:NSLocalizedStringFromTable(@"YouDowngraded", @"SealMeeting", nil)];
                    [[RTCService sharedInstance] setCameraDisable:YES];
                    [[RTCService sharedInstance] setMicrophoneDisable:YES];
                    [[RTCService sharedInstance] unpublishLocalUserDefaultAVStream];
                }
            }
            break;
    }
    [self.toolPanelView reloadToolPanelView];
    [self.personListView reloadPersonList];
    [self.videoListView reloadVideoList];
    if (role == RoleSpeaker || role == RoleAdmin) {
        [self.recentSharedView reloadDataSource];
    }
    if ([member.userId isEqualToString:[ClassroomService sharedService].currentRoom.currentMember.userId]) {
        [self.wBoardCtrl didChangeRole:role];
        [self.containerView didChangeRole:role];
    }
    if (member.userId) {
        [[NSNotificationCenter defaultCenter] postNotificationName:RoleDidChangeNotification object:@{@"role":@(role),@"userId":member.userId}];
    }
}

//转让主持人的回调
- (void)adminDidTransfer:(RoomMember *)oldAdmin newAdmin:(RoomMember *)newAdmin {
    NSLog(@"adminDidTransfer from:%@ to:%@",oldAdmin,newAdmin);
    RoomMember *curMember = [ClassroomService sharedService].currentRoom.currentMember;
    if ([curMember.userId isEqualToString:oldAdmin.userId]) {
        [self.view showHUDMessage:[NSString stringWithFormat:NSLocalizedStringFromTable(@"YouSetTransferSuccess", @"SealMeeting", nil),newAdmin.name]];
    }
    [self.personListView reloadPersonList];
    [self.videoListView reloadVideoList];
}

//旁观者申请成为参会人，主持人收到的回调
- (void)upgradeDidApply:(RoomMember *)member ticket:(NSString *)ticket overMaxCount:(BOOL)isOver{
    NSLog(@"upgradeDidApply:%@ ticket:%@ overMaxCount:%@",member,ticket,@(isOver));
    if (isOver) {
        NSString * title = [NSString stringWithFormat:@"%@ %@",member.name ,NSLocalizedStringFromTable(@"ApplaySpeakerAbove", @"SealMeeting", nil)];
        [NormalAlertView showAlertWithTitle:title leftTitle:NSLocalizedStringFromTable(@"RefuseRequest", @"SealMeeting", nil) rightTitle:NSLocalizedStringFromTable(@"Close", @"SealMeeting", nil) cancel:^{
            [[ClassroomService sharedService] rejectUpgrade:ticket];
        } confirm:^{
            
        }];
    }else {
        UpgradeDidApplyView *alertView =  [[UpgradeDidApplyView alloc] initWithMember:member ticket:ticket];
        [self.view addSubview:alertView];
        alertView.delegate = self;
        [self performSelector:@selector(dismissTopAlertView:) withObject:alertView afterDelay:30.0];
    }
}

//旁观者申请成为参会人，主持人接受的回调
- (void)applyDidApprove {
    NSLog(@"applyDidApprove %@",[ClassroomService sharedService].currentRoom.currentMember);
    [[RTCService sharedInstance] setCameraDisable:NO];
    [[RTCService sharedInstance] setMicrophoneDisable:NO];
    [[RTCService sharedInstance] publishLocalUserDefaultAVStream];
    self.personListView.curMemberApplying = NO;
    [self.personListView reloadPersonList:[ClassroomService sharedService].currentRoom.currentMember tag:RefreshPersonListTagRefresh];
}

//旁观者申请成为参会人，主持人拒绝的回调
- (void)applyDidReject {
    NSLog(@"applyDidReject %@",[ClassroomService sharedService].currentRoom.currentMember);
    [self.view showHUDMessage:NSLocalizedStringFromTable(@"YouUpgradedReject", @"SealMeeting", nil)];
    self.personListView.curMemberApplying = NO;
    [self.personListView reloadPersonList:[ClassroomService sharedService].currentRoom.currentMember tag:RefreshPersonListTagRefresh];
    
}

//旁观者申请成为参会人失败的回调
- (void)applyDidFailed:(ErrorCode)code {
    NSLog(@"applyDidFailed %@",[ClassroomService sharedService].currentRoom.currentMember);
    [self.view showHUDMessage:NSLocalizedStringFromTable(@"Error", @"SealMeeting", nil)];
    self.personListView.curMemberApplying = NO;
    [self.personListView reloadPersonList:[ClassroomService sharedService].currentRoom.currentMember tag:RefreshPersonListTagRefresh];
}

//主持人邀请旁观者成为参会人,旁观者收到的回调
- (void)upgradeDidInvite:(NSString *)ticket {
    if ([NormalAlertView hasBeenDisplaying]) {
        return;
    }
    NSLog(@"upgradeDidInvite ticket:%@ member:%@",ticket,[ClassroomService sharedService].currentRoom.currentMember);
    [NormalAlertView showAlertWithTitle:NSLocalizedStringFromTable(@"InviteUpgrade", @"SealMeeting", nil) leftTitle:NSLocalizedStringFromTable(@"Refuse", @"SealMeeting", nil) rightTitle:NSLocalizedStringFromTable(@"Agreen", @"SealMeeting", nil) cancel:^{
        [[ClassroomService sharedService] rejectInvite:ticket];
        
    } confirm:^{
        [[ClassroomService sharedService] approveInvite:ticket];
    }];
}

//主持人邀请旁观者成为参会人，旁观者接受的回调
- (void)inviteDidApprove:(RoomMember *)member {
    NSLog(@"inviteDidApprove :%@",member);
    [self.view showHUDMessage:[NSString stringWithFormat:NSLocalizedStringFromTable(@"SetParticipantSuccess", @"SealMeeting", nil),member.name]];
    
}

//主持人邀请旁观者成为参会人，旁观者拒绝的回调
- (void)inviteDidReject:(RoomMember *)member {
    NSLog(@"inviteDidReject :%@",member);
    [self.view showHUDMessage:NSLocalizedStringFromTable(@"RefuseYourInvite", @"SealMeeting", nil)];
}

//旁观者申请成为参会人/主持人邀请旁观者成为参会人，超时没有回应的回调
- (void)ticketDidExpire:(NSString *)ticket {
    NSLog(@"ticketDidExpire ticket:%@",ticket);
    [self.view showHUDMessage:NSLocalizedStringFromTable(@"OverTime", @"SealMeeting", nil)];
    self.personListView.curMemberApplying = NO;
    [self.personListView reloadPersonList];
}

- (void)deviceDidEnable:(BOOL)enable type:(DeviceType)type forUser:(RoomMember *)member operator:(nonnull NSString *)operatorId{
    NSLog(@"deviceDidEnable devicetype:%@ enable:%@ memeber:%@",@(type),@(enable),member);
    RoomMember *curMember = [ClassroomService sharedService].currentRoom.currentMember;
    NSString *hudMessage = @"";
    //只有主持人和自己才有提示
    if (curMember.role == RoleAdmin && ![curMember.userId isEqualToString:operatorId]) {
        if (type == DeviceTypeCamera) {
            hudMessage = !enable ? [NSString stringWithFormat:NSLocalizedStringFromTable(@"SetCameraClose", @"SealMeeting", nil),member.name] : [NSString stringWithFormat:NSLocalizedStringFromTable(@"SetCameraOpen", @"SealMeeting", nil),member.name];
        } else {
            hudMessage = !enable ? [NSString stringWithFormat:NSLocalizedStringFromTable(@"SetMicorophoneClose", @"SealMeeting", nil),member.name] : [NSString stringWithFormat:NSLocalizedStringFromTable(@"SetMicorophoneOpen", @"SealMeeting", nil),member.name];
        }
        [self.view showHUDMessage:hudMessage];
    }else {
        if ([curMember.userId isEqualToString:member.userId]) {
            if (type == DeviceTypeCamera) {
                if(![curMember.userId isEqualToString:operatorId]){
                    hudMessage = !enable ? NSLocalizedStringFromTable(@"YourCameraClosed", @"SealMeeting", nil) : NSLocalizedStringFromTable(@"CameraOpend", @"SealMeeting", nil);
                    [self.view showHUDMessage:hudMessage];
                }
                self.titleView.cameraBtn.selected = enable;
                [[RTCService sharedInstance] setCameraDisable:!enable];
            } else {
                if(![curMember.userId isEqualToString:operatorId]){
                    hudMessage = !enable ? NSLocalizedStringFromTable(@"YourMicorophoneClosed", @"SealMeeting", nil) : NSLocalizedStringFromTable(@"MicorophoneOpend", @"SealMeeting", nil);
                    [self.view showHUDMessage:hudMessage];
                }
                self.titleView.microphoneBtn.selected = enable;
                [[RTCService sharedInstance] setMicrophoneDisable:!enable];
            }
        }
    }
    if ([ClassroomService sharedService].currentRoom.currentDisplayType != DisplayWhiteboard && type == DeviceTypeCamera) {
        [self renderMainContainerView];
    }
    [self.titleView refreshTitleView];
    [self.personListView reloadPersonList:member tag:RefreshPersonListTagRefresh];
}

//主持人请求用户打开设备，主持人关闭用户设备没有回调。
- (void)deviceDidInviteEnable:(DeviceType)type ticket:(NSString *)ticket{
    NSLog(@"deviceDidInviteEnable devicetype:%@ ticket:%@ ",@(type),ticket);
    if (type == DeviceTypeCamera) {
        [NormalAlertView showAlertWithTitle:NSLocalizedStringFromTable(@"AssitantInviteCamera", @"SealMeeting", nil) leftTitle:NSLocalizedStringFromTable(@"Refuse", @"SealMeeting", nil) rightTitle:NSLocalizedStringFromTable(@"Agreen", @"SealMeeting", nil) cancel:^{
            [[ClassroomService sharedService] rejectEnableDevice:ticket];
        } confirm:^{
            [[ClassroomService sharedService] approveEnableDevice:ticket];
        }];
    }else {
        [NormalAlertView showAlertWithTitle:NSLocalizedStringFromTable(@"AssitantInviteMicro", @"SealMeeting", nil) leftTitle:NSLocalizedStringFromTable(@"Refuse", @"SealMeeting", nil) rightTitle:NSLocalizedStringFromTable(@"Agreen", @"SealMeeting", nil) cancel:^{
            [[ClassroomService sharedService] rejectEnableDevice:ticket];
        } confirm:^{
            [[ClassroomService sharedService] approveEnableDevice:ticket];
        }];
    }
}

//只有主持人能收到这个回调,可以不在这里处理文字，因为设备的回调还会走
- (void)deviceInviteEnableDidApprove:(RoomMember *)member type:(DeviceType)type {
    NSLog(@"deviceInviteEnableDidApprove devicetype:%@ member:%@ ",@(type),member);
    //    if (type == DeviceTypeCamera) {
    //        [self.view showHUDMessage:[NSString stringWithFormat:NSLocalizedStringFromTable(@"SetCameraOpen", @"SealMeeting", nil),member.name]];
    //    }
    //    if (type == DeviceTypeMicrophone) {
    //        [self.view showHUDMessage:[NSString stringWithFormat:NSLocalizedStringFromTable(@"SetMicorophoneOpen", @"SealMeeting", nil),member.name]];
    //    }
}

//拒绝只有主持人能收到这个回调，且只走这个回调
- (void)deviceInviteEnableDidReject:(RoomMember *)member type:(DeviceType)type {
    NSLog(@"deviceInviteEnableDidReject devicetype:%@ member:%@ ",@(type),member);
    [self.view showHUDMessage:[NSString stringWithFormat:NSLocalizedStringFromTable(@"RefuseYourInvite", @"SealMeeting", nil),member.name]];
}

- (void)whiteboardDidCreate:(Whiteboard *)board {
    NSLog(@"whiteboardDidCreate %@ ",board);
    [self.recentSharedView reloadDataSource];
}

- (void)whiteboardDidDisplay:(NSString *)boardId {
    NSLog(@"whiteboardDidDisplay %@ ",boardId);
    [self renderMainContainerView];
}

- (void)whiteboardDidDelete:(NSString *)boardId {
    NSLog(@"whiteboardDidDelete %@ ",boardId);
    [self.recentSharedView reloadDataSource];
}

- (void)speakerDidDisplay {
    NSLog(@"speakerDidDisplay %@ ",[ClassroomService sharedService].currentRoom.speaker);
    [self cancelRenderMaskViewIfNeed];
    [self renderMainContainerView];
}

- (void)adminDidDisplay {
    NSLog(@"adminDidDisplay %@ ",[ClassroomService sharedService].currentRoom.admin);
    [self cancelRenderMaskViewIfNeed];
    [self renderMainContainerView];
}

- (void)sharedScreenDidDisplay:(NSString *)userId {
    NSLog(@"sharedScreenDidDisplay %@ ",userId);
    [self renderMainContainerView];
}

- (void)noneDidDisplay {
    NSLog(@"noneDidDisplay");
    [self renderMainContainerView];
}

#pragma mark - private method
- (void)tapGesture: (UITapGestureRecognizer *)tapGesture{
    [self.toolPanelView foldToolPanelView];
    [self hidePersonListView];
    [self hideRecentSharedView];
    [self refreshWboardFrame];
    [self showInviteView:NO];
    [self.popupView destroy];
}

- (void)bindDelegates {
    self.titleView.delegate = self;
    self.toolPanelView.delegate = self;
    self.containerView.delegate = self;
    self.videoListView.delegate = self;
    [[RTCService sharedInstance] setRTCRoomDelegate:self];
    [ClassroomService sharedService].classroomDelegate = self;
}

- (void)addSubviews {
    [self.view addSubview:self.containerView];
    [self.view addSubview:self.titleView];
    [self.view addSubview:self.toolPanelView];
    [self wBoardCtrl];
    [self chatAreaView];
    [self.view addSubview:self.videoListView];
}

- (void)showRecentSharedView {
    [self.view addSubview:self.recentSharedView];;
}

- (void)showPersonListView {
    [self.view addSubview:self.personListView];
}

- (void)showChatAreaView{
    [self.view addSubview:self.chatAreaView];
}

- (void)hideRecentSharedView {
    [self.recentSharedView removeFromSuperview];
}

- (void)hidePersonListView {
    [self.personListView removeFromSuperview];
}

- (void)hideChatAreaView{
    [UIView animateWithDuration:0.2 animations:^{
        [self.chatAreaView removeFromSuperview];
    }];
}

- (void)showInviteView:(BOOL)show{
    [self.inviteView removeFromSuperview];
    if (show) {
        [UIView animateWithDuration:0.2 animations:^{
            [self.view addSubview:self.inviteView];
        }];
    }
}

- (CGRect)mainContainerFrame {
    CGFloat x = CGRectGetMinX(self.toolPanelView.frame);
    CGFloat y = CGRectGetMinY(self.titleView.frame);
    CGFloat width = UIScreenWidth - x;
    CGFloat height = UIScreenHeight - y;
    return CGRectMake(x, y, width, height);
}

- (void)dismissTopAlertView:(UpgradeDidApplyView*)topAlertView {
    [topAlertView removeFromSuperview];
    topAlertView = nil;
}

- (void)displayWhiteboard:(NSString *)boardId {
    NSString *urlStr = [[ClassroomService sharedService] generateWhiteboardURL:boardId];
    [self.wBoardCtrl loadWBoardWith:boardId wBoardURL:urlStr frame:CGRectZero];
    [self refreshWboardFrame];
    for (UIView * view in self.view.subviews) {
        if ([view isKindOfClass:[PersonListView class]] || [view isKindOfClass:[ChatAreaView class]]) {
            [self.view bringSubviewToFront:view];
        }
    }
}

- (void)refreshWboardFrame {
    CGRect mainVideoFrame = self.containerView.currentVideoFrame;
    mainVideoFrame.origin.x += self.toolPanelView.frame.origin.x;
    [self.wBoardCtrl setWBoardFrame:mainVideoFrame];
}

- (CGFloat)getIphoneXFitSpace{
    static CGFloat space;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (@available(iOS 11.0, *)) {
            UIWindow *mainWindow = [[[UIApplication sharedApplication] delegate] window];
            UIEdgeInsets safeAreaInsets = mainWindow.safeAreaInsets;
            if (!UIEdgeInsetsEqualToEdgeInsets(safeAreaInsets,UIEdgeInsetsZero)){
                space = 34;
            }
        }});
    return space;
}

- (void)publishStream {
    if ([ClassroomService sharedService].currentRoom.currentMember.role != RoleObserver) {
        [[RTCService sharedInstance] publishLocalUserDefaultAVStream];
    }
}

- (void)renderMainContainerView{
    RoomMember *admin = [ClassroomService sharedService].currentRoom.admin;
    RoomMember *speaker = [ClassroomService sharedService].currentRoom.speaker;
    if (([ClassroomService sharedService].currentRoom.currentDisplayType == DisplayAdmin) && admin.cameraEnable) {
        [self.wBoardCtrl hideBoard];
        [self.containerView containerViewRenderView:[ClassroomService sharedService].currentRoom.admin];
        [self.videoListView showAdminPrompt:YES showSpeakerPrompt:NO];
    } else if (([ClassroomService sharedService].currentRoom.currentDisplayType == DisplaySpeaker && speaker.cameraEnable)) {
        [self.wBoardCtrl hideBoard];
        [self.containerView containerViewRenderView:[ClassroomService sharedService].currentRoom.speaker];
        [self.videoListView showAdminPrompt:NO showSpeakerPrompt:YES];
    } else if ([ClassroomService sharedService].currentRoom.currentDisplayType == DisplayWhiteboard) {
        [self.containerView cancelRenderView];
        [self displayWhiteboard:[ClassroomService sharedService].currentRoom.currentDisplayURI];
        [self.videoListView showAdminPrompt:NO showSpeakerPrompt:NO];
    } else if (([ClassroomService sharedService].currentRoom.currentDisplayType == DisplaySharedScreen)) {
        [self.wBoardCtrl hideBoard];
        [[RTCService sharedInstance] renderUserSharedScreenOnView:self.containerView.videoView forUser:[ClassroomService sharedService].currentRoom.currentDisplayURI];
        [self.videoListView showAdminPrompt:NO showSpeakerPrompt:NO];
    } else {
        [self.wBoardCtrl hideBoard];
        [self.containerView cancelRenderView];
    }
}

- (void)registerNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationEnterBackground) name: UIApplicationDidEnterBackgroundNotification object:nil];
}

- (void)applicationEnterBackground{
    [self showInviteView:NO];
}

- (void)showRoleHud {
    Role role =  [ClassroomService sharedService].currentRoom.currentMember.role;
    if(role == RoleObserver) {
        [self.view showHUDMessage:NSLocalizedStringFromTable(@"Observer", @"SealMeeting", nil)];
        [self performSelector:@selector(showOnlyYouHUD) withObject:nil afterDelay:5.0f];
    }else{
        [self showOnlyYouHUD];
    }
}

- (void)showOnlyYouHUD {
    if ([ClassroomService sharedService].currentRoom.memberList.count == 1) {
        [self.view showHUDMessage:NSLocalizedStringFromTable(@"OnlyYou", @"SealMeeting", nil)];
    }
}
#pragma mark - Getters & setters
- (ClassroomTitleView *)titleView {
    if(!_titleView) {
        _titleView = [[ClassroomTitleView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.toolPanelView.frame), 0, UIScreenWidth - CGRectGetMaxX(self.toolPanelView.frame), TitleViewHeight)];
    }
    return _titleView;
}

- (ToolPanelView *)toolPanelView {
    if(!_toolPanelView) {
        _toolPanelView = [[ToolPanelView alloc] initWithFrame:CGRectMake([self getIphoneXFitSpace], 0, ToolPanelViewWidth, UIScreenHeight)];
    }
    return _toolPanelView;
}

- (RecentSharedView *)recentSharedView {
    if(!_recentSharedView) {
        _recentSharedView = [[RecentSharedView alloc] initWithFrame:CGRectMake(UIScreenWidth - RecentSharedViewWidth, 0, RecentSharedViewWidth, UIScreenHeight)];
        _recentSharedView.delegate = self;
    }
    return _recentSharedView;
}

- (PersonListView *)personListView {
    if(!_personListView) {
        _personListView = [[PersonListView alloc] initWithFrame:CGRectMake(UIScreenWidth - PersonListViewWidth, 0, PersonListViewWidth, UIScreenHeight)];
    }
    return _personListView;
}

- (VideoListView *)videoListView {
    if(!_videoListView) {
        _videoListView = [[VideoListView alloc] initWithFrame:CGRectMake(UIScreenWidth - VideoListViewWidth - 20, TitleViewHeight, VideoListViewWidth, UIScreenHeight - TitleViewHeight)];
    }
    return _videoListView;
}

- (MainContainerView *)containerView {
    if(!_containerView) {
        _containerView = [[MainContainerView alloc] initWithFrame:[self mainContainerFrame]];
    }
    return _containerView;
}

- (ChatAreaView *)chatAreaView {
    if(!_chatAreaView) {
        _chatAreaView = [[ChatAreaView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.toolPanelView.frame),TitleViewHeight, UIScreenWidth - CGRectGetMaxX(self.toolPanelView.frame), UIScreenHeight-TitleViewHeight) conversationType:ConversationType_GROUP targetId:[ClassroomService sharedService].currentRoom.roomId];
    }
    return _chatAreaView;
}

- (WhiteboardControl *)wBoardCtrl {
    if (!_wBoardCtrl) {
        _wBoardCtrl = [[WhiteboardControl alloc] initWithDelegate:self];
        [_wBoardCtrl moveToSuperView:self.view];
    }
    return _wBoardCtrl;
}

- (InviteListView *)inviteView{
    if(!_inviteView) {
        _inviteView = [[InviteListView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.view.frame)-InviteViewWidth,0, InviteViewWidth,UIScreenHeight)];
        [InviteHelper sharedInstance].baseVC = self;
        _inviteView.delegate = [InviteHelper sharedInstance];
    }
    return _inviteView;
}
@end
