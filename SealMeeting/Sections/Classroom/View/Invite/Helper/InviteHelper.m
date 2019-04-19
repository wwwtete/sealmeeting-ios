//
//  InviteHepler.m
//  SealMeeting
//
//  Created by 张改红 on 2019/4/2.
//  Copyright © 2019 RongCloud. All rights reserved.
//

#import "InviteHelper.h"
#import <MessageUI/MessageUI.h>
#import "ClassroomService.h"
#import "MBProgressHUD.h"
#import "QRCodeView.h"
#import "ShareTemplate.h"
@interface InviteHelper ()<MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate>
@end
@implementation InviteHelper
+ (instancetype)sharedInstance {
    static InviteHelper *helper = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        helper = [[self alloc] init];
    });
    return helper;
}

#pragma mark - InviteListViewDelegate
- (void)inviteListView:(UIButton *)button didTapAtTag:(InviteListViewActionTag)tag{
    switch (tag) {
        case InviteListViewActionTagWechat:
            [self sendWeChatInvitation];
            break;
        case InviteListViewActionTagSMS:
            [self sendSMSInvitation];
            break;
        case InviteListViewActionTagEmail:
            [self sendEmailInvitation];
            break;
        case InviteListViewActionTagQRCode:
            [self showQRcode];
            break;
        case InviteListViewActionTagCopyInfo:
            [self copyInviteInfo];
            break;
        default:
            break;
    }
}

#pragma mark - WXApiDelegate
- (void)onReq:(BaseReq *)req{
    
}

- (void)onResp:(BaseResp *)resp{
    
}

#pragma mark - MFMessageComposeViewControllerDelegate
-(void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
    [controller dismissViewControllerAnimated:YES completion:nil];
    switch (result) {
        case MessageComposeResultSent://信息传送成功
            
            break;
        case MessageComposeResultFailed://信息传送失败
            
            break;
        case MessageComposeResultCancelled://信息被用户取消传送
            
            break;
        default:
            break;
    }
}

#pragma mark - MFMailComposeViewControllerDelegate
- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError *)error{
    switch (result){
        case MFMailComposeResultCancelled: // 用户取消编辑
            NSLog(@"Mail send canceled...");
            break;
        case MFMailComposeResultSaved: // 用户保存邮件
            NSLog(@"Mail saved...");
            break;
        case MFMailComposeResultSent: // 用户点击发送
            NSLog(@"Mail sent...");
            break;
        case MFMailComposeResultFailed: // 用户尝试保存或发送邮件失败
            NSLog(@"Mail send errored: %@...", [error localizedDescription]);
            break;
    }
    // 关闭邮件发送视图
    [controller dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Helper
- (void)sendWeChatInvitation{
    if ([WXApi isWXAppInstalled]) {
        WXMediaMessage * message = [WXMediaMessage message];
        message.title = NSLocalizedStringFromTable(@"EmailTheme", @"SealMeeting", nil);
        message.description = [NSString stringWithFormat:NSLocalizedStringFromTable(@"InviteMeetingId", @"SealMeeting", nil),[ClassroomService sharedService].currentRoom.roomId];
        [message setThumbImage:[UIImage imageNamed:@"wechat_thumb"]];
        
        WXWebpageObject * webPageObject = [WXWebpageObject object];
        webPageObject.webpageUrl = [ShareTemplate getURLTemplate:[ClassroomService sharedService].currentRoom.roomId];
        message.mediaObject = webPageObject;
        
        SendMessageToWXReq * req1 = [[SendMessageToWXReq alloc]init];
        req1.bText = NO;
        req1.message = message;
        //设置分享到朋友圈(WXSceneTimeline)、好友回话(WXSceneSession)、收藏(WXSceneFavorite)
        req1.scene = WXSceneSession;
        [WXApi sendReq:req1];
    }else{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTable(@"InviteFailed", @"SealMeeting", nil)
                                                        message:NSLocalizedStringFromTable(@"WeChatUninstall", @"SealMeeting", nil)
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedStringFromTable(@"OK", @"SealMeeting", nil)
                                              otherButtonTitles:nil, nil];
        [alert show];
    }
}

- (void)sendSMSInvitation{
    if([MFMessageComposeViewController canSendText]) {
        MFMessageComposeViewController * controller = [[MFMessageComposeViewController alloc] init];
        controller.navigationBar.tintColor = [UIColor redColor];
        RoomMember *currentMember = [ClassroomService sharedService].currentRoom.currentMember;
        controller.body = [NSString stringWithFormat:NSLocalizedStringFromTable(@"SMSInviteInfo", @"SealMeeting", nil),currentMember.name,[ShareTemplate getURLTemplate:[ClassroomService sharedService].currentRoom.roomId]]; //此处的body就是短信将要发送的内容
        controller.messageComposeDelegate = self;
        [self.baseVC presentViewController:controller animated:YES completion:nil];
        [[[[controller viewControllers] lastObject] navigationItem] setTitle:@"title"];//修改短信界面标题
    }
}

- (void)sendEmailInvitation{
    if ([MFMailComposeViewController canSendMail]) {
        // 用户已设置邮件账户
        MFMailComposeViewController *mailCompose = [[MFMailComposeViewController alloc] init];
        mailCompose.title = NSLocalizedStringFromTable(@"EmailTitle", @"SealMeeting", nil);
        [mailCompose setMailComposeDelegate:self];
        // 设置邮件主题
        [mailCompose setSubject:NSLocalizedStringFromTable(@"EmailTheme", @"SealMeeting", nil)];
        /**
         *  设置邮件的正文内容
         */
        RoomMember *currentMember = [ClassroomService sharedService].currentRoom.currentMember;
        NSString *emailContent = [NSString stringWithFormat:NSLocalizedStringFromTable(@"EmailContent", @"SealMeeting", nil),currentMember.name,[ClassroomService sharedService].currentRoom.roomId,[ShareTemplate getURLTemplate:[ClassroomService sharedService].currentRoom.roomId]];
        // 是否为HTML格式
        [mailCompose setMessageBody:emailContent isHTML:YES];
        // 弹出邮件发送视图
        [self.baseVC presentViewController:mailCompose animated:YES completion:nil];
    }else{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTable(@"EmailNotLoginTitle", @"SealMeeting", nil)
                                                        message:NSLocalizedStringFromTable(@"EmailNotLogin", @"SealMeeting", nil)
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedStringFromTable(@"OK", @"SealMeeting", nil)
                                              otherButtonTitles:nil, nil];
        [alert show];
    }
}

- (void)showQRcode{
    QRCodeView *view = [[QRCodeView alloc] init];
    UINavigationController *navi = [[UINavigationController alloc] initWithRootViewController:view];
    [self.baseVC presentViewController:navi animated:YES completion:nil];
}

- (void)copyInviteInfo{
    UIPasteboard *pab = [UIPasteboard generalPasteboard];
    RoomMember *currentMember = [ClassroomService sharedService].currentRoom.currentMember;
    NSString *string = [NSString stringWithFormat:NSLocalizedStringFromTable(@"SMSInviteInfo", @"SealMeeting", nil),currentMember.name,[ShareTemplate getURLTemplate:[ClassroomService sharedService].currentRoom.roomId]];
    [pab setString:string];
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.baseVC.view animated:YES];
    hud.mode = MBProgressHUDModeText;
    if (pab) {
       hud.label.text = NSLocalizedStringFromTable(@"HasCopy", @"SealMeeting", nil);
    }
    [hud hideAnimated:YES afterDelay:1];
}
@end
