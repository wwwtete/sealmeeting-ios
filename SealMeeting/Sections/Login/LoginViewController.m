//
//  LoginViewController.m
//  SealMeeting
//
//  Created by LiFei on 2019/2/26.
//  Copyright © 2019 RongCloud. All rights reserved.
//

#import "LoginViewController.h"
#import "ClassroomViewController.h"
#import <RongIMLib/RongIMLib.h>
#import "RTCService.h"
#import "SelectionButton.h"
#import "Masonry.h"
#import "InputTextField.h"
#import "SettingViewController.h"
#import "LoginHelper.h"
#import <MBProgressHUD/MBProgressHUD.h>
#import "ClassroomService.h"
#import "NormalAlertView.h"
#import "AppDelegate.h"
#define meetingIdTextFieldTag 3000
#define userNameTextFieldTag 3001
@interface LoginViewController ()<UITextFieldDelegate, ClassroomHelperDelegate>
@property (nonatomic, strong) UIButton *setButton;
@property (nonatomic, strong) UIImageView *logoView;
@property (nonatomic, strong) InputTextField *meetingIdTextField;
@property (nonatomic, strong) InputTextField *userNameTextField;
@property (nonatomic, strong) SelectionButton *openVisitorButton;
@property (nonatomic, strong) SelectionButton *closeVideoButton;
@property (nonatomic, strong) UIButton *joinButton;
@property (nonatomic, strong) MBProgressHUD *hud;
//加入失败的时候，会弹窗，此时如果通过 web 页面唤醒 APP，此弹窗还会存在
@property (nonatomic, strong) UIAlertView *alertView;
@end

@implementation LoginViewController

#pragma mark - Life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    [self.navigationController setNavigationBarHidden:YES];
    [self addSubViews];
    [self addGesture];
    [self registerNotification];
    [LoginHelper sharedInstance].delegate = self;
    NSString *openUrl = ((AppDelegate *)[UIApplication sharedApplication].delegate).openURL;
    NSNotification *n = [NSNotification notificationWithName:@"" object:openUrl];
    [self didOpenUrl:n];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self didResignFirstResponder];
}

#pragma mark - ClassroomHelperDelegate
- (void)classroomDidJoin:(Classroom *)classroom{
    if ([self.navigationController.topViewController isKindOfClass:[self class]]) {
        [self.hud hideAnimated:YES];
        [self pushToClassroom];
    }
}

- (void)classroomDidJoinFail{
    [self.hud hideAnimated:YES];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:NSLocalizedStringFromTable(@"LoginFail", @"SealMeeting", nil) delegate:nil cancelButtonTitle:NSLocalizedStringFromTable(@"Cancel", @"SealMeeting", nil) otherButtonTitles:nil];
    [alertView show];
    self.alertView = alertView;
}

- (void)classroomDidOverMaxUserCount{
    [self.hud hideAnimated:YES];
    [NormalAlertView showAlertWithTitle:NSLocalizedStringFromTable(@"OverMaxMessage", @"SealMeeting", nil) leftTitle:NSLocalizedStringFromTable(@"Cancel", @"SealMeeting", nil) rightTitle:NSLocalizedStringFromTable(@"Confirm", @"SealMeeting", nil) cancel:^{

    } confirm:^{
        [self login:YES];
    }];
}

#pragma mark - UITextFieldDelegate
- (void)textFieldDidBeginEditing:(UITextField *)textField{
    InputTextField *field = (InputTextField *)textField;
    [field setBorderState:(InputTextFieldBorderStateEditing)];
}

- (void)textFieldDidEndEditing:(UITextField *)textField{
    InputTextField *field = (InputTextField *)textField;
    if (textField.text.length > 0) {
        switch (field.tag) {
            case meetingIdTextFieldTag:
                [self checkClassIdValidity];
                break;
            case userNameTextFieldTag:
                [self checkUserNameValidity];
                break;
            default:
                break;
        }
    }else{
        [field setBorderState:(InputTextFieldBorderStateNormal)];
    }
    [self enableJoinButton];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];//取消第一响应者
    return YES;
}

#pragma mark - Notification action
- (void)keyboardWillShow:(NSNotification*)notification {
    CGRect keyboardBounds = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    UIViewAnimationCurve curve = [[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    [UIView animateWithDuration:0.5 animations:^{
        [UIView setAnimationCurve:curve];
        CGRect originalFrame = [UIScreen mainScreen].bounds;
        if([self.meetingIdTextField isFirstResponder] && CGRectGetMaxY(self.meetingIdTextField.frame) > keyboardBounds.origin.y){
            originalFrame.origin.y = originalFrame.origin.y-(CGRectGetMaxY(self.meetingIdTextField.frame)-keyboardBounds.origin.y);
        }else if([self.userNameTextField isFirstResponder] && CGRectGetMaxY(self.userNameTextField.frame) > keyboardBounds.origin.y){
            originalFrame.origin.y = originalFrame.origin.y-(CGRectGetMaxY(self.userNameTextField.frame)-keyboardBounds.origin.y);
        }
        self.view.frame = originalFrame;
        [UIView commitAnimations];
    }];
}

- (void)keyboardWillHide:(NSNotification*)notification {
    [UIView animateWithDuration:0.5 animations:^{
        [UIView setAnimationCurve:0];
        CGRect originalFrame = self.view.frame;
        originalFrame.origin.y = 0;
        self.view.frame = originalFrame;
        [UIView commitAnimations];
    }];
}

- (void)didOpenUrl:(NSNotification *)notification{
    [self dismisAlertViewIfNeed];
    ((AppDelegate *)[UIApplication sharedApplication].delegate).openURL = nil;
    NSString *roomId = notification.object;
    if (roomId.length) {
        if ([ClassroomService sharedService].currentRoom.roomId.length > 0) {
            if ([roomId isEqualToString:[ClassroomService sharedService].currentRoom.roomId]) {
                return;
            }
            [NormalAlertView showAlertWithTitle:NSLocalizedStringFromTable(@"HasExitMeeting", @"SealMeeting", nil) leftTitle:NSLocalizedStringFromTable(@"Cancel", @"SealMeeting", nil) rightTitle:NSLocalizedStringFromTable(@"Confirm", @"SealMeeting", nil) cancel:^{
                
            } confirm:^{
                if ([[self getCurrentLastVC] isKindOfClass:NSClassFromString(@"ClassroomViewController")]) {
                    [[self getCurrentLastVC] dismissViewControllerAnimated:YES completion:nil];
                }
                [[LoginHelper sharedInstance] logout:^{
                    self.meetingIdTextField.text = roomId;
                    self.userNameTextField.text = [[UIDevice currentDevice].name stringByReplacingOccurrencesOfString:@"的 iPhone" withString:@""];
                    [self login:NO];
                } error:^(RongRTCCode code) {
                }];
            }];
        }else{
            self.meetingIdTextField.text = roomId;
            self.userNameTextField.text = [[UIDevice currentDevice].name stringByReplacingOccurrencesOfString:@"的 iPhone" withString:@""];
            [self login:NO];
        }
    }
}
#pragma mark - Target action
- (void)onJoin:(id)sender {
    [self login:self.openVisitorButton.selected];
}

- (void)onTapSetButton{
    SettingViewController *settingVC = [[SettingViewController alloc] init];
    [self.navigationController pushViewController:settingVC animated:YES];
}

#pragma mark - Helper
- (void)registerNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didOpenUrl:) name:ApplicationOpenURLNotification object:nil];
}

- (void)pushToClassroom {
    [[RCIMClient sharedRCIMClient] clearConversations:@[@(ConversationType_GROUP)]];
    ClassroomViewController *vc = [[ClassroomViewController alloc] init];
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)checkClassIdValidity{
    if (self.meetingIdTextField.text.length > 40 || ![self isTextValidity:self.meetingIdTextField.text enableChinese:NO]) {
        self.meetingIdTextField.warnLabel.text = NSLocalizedStringFromTable(@"MeetingIdWarn", @"SealMeeting", nil);
        self.meetingIdTextField.warnLabel.hidden = NO;
        [self.meetingIdTextField setBorderState:InputTextFieldBorderStateError];
    }else{
        self.meetingIdTextField.warnLabel.hidden = YES;
        [self.meetingIdTextField setBorderState:InputTextFieldBorderStateNormal];
    }
}

- (void)checkUserNameValidity{
    if (self.userNameTextField.text.length > 10 || ![self isTextValidity:self.userNameTextField.text enableChinese:YES]) {
        self.userNameTextField.warnLabel.text = NSLocalizedStringFromTable(@"UserNameWarn", @"SealMeeting", nil);
        self.userNameTextField.warnLabel.hidden = NO;
        [self.userNameTextField setBorderState:InputTextFieldBorderStateError];
    }else{
        self.userNameTextField.warnLabel.hidden = YES;
        [self.userNameTextField setBorderState:InputTextFieldBorderStateNormal];
    }
}

- (BOOL)isTextValidity:(NSString *)text enableChinese:(BOOL)enableChinese{
    text = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString *regex =@"^[a-zA-Z0-9]+$";
    if (enableChinese) {
        regex =@"^[\u4e00-\u9fa5a-zA-Z0-9]+$";
    }
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",regex];
    if ([pred evaluateWithObject:text]) {
        return YES;
    }
    return NO;
}

- (void)enableJoinButton{
    if (self.userNameTextField.text.length > 0 && self.meetingIdTextField.text.length > 0 && self.meetingIdTextField.warnLabel.hidden && self.userNameTextField.warnLabel.hidden) {
        self.joinButton.enabled = YES;
        self.joinButton.alpha = 1;
    }else{
        self.joinButton.enabled = NO;
        self.joinButton.alpha = 0.5;
    }
}

- (void)didResignFirstResponder{
    if ([self.meetingIdTextField isFirstResponder]) {
        [self.meetingIdTextField resignFirstResponder];
    }else if ([self.userNameTextField isFirstResponder]){
        [self.userNameTextField resignFirstResponder];
    }
}

- (void)login:(BOOL)isObserver{
    self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    NSString *roomId = [self.meetingIdTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString *userName = [self.userNameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    [[LoginHelper sharedInstance] login:roomId user:userName isObserver:isObserver disableCamera:self.closeVideoButton.selected];
}

- (UIViewController *)getCurrentLastVC {
    UIViewController *appRootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
    UIViewController *topVC = appRootVC;
    if (topVC.presentedViewController){
        topVC = topVC.presentedViewController;
    }
    return topVC;
}
#pragma mark - SubViews
- (void)addSubViews{
    [self.view addSubview:self.setButton];
    [self.view addSubview:self.logoView];
    [self.view addSubview:self.meetingIdTextField];
    [self.view addSubview:self.userNameTextField];
    [self.view addSubview:self.openVisitorButton];
    [self.view addSubview:self.closeVideoButton];
    [self.view addSubview:self.joinButton];
    [self.setButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.view).offset(-35);
        make.top.equalTo(self.view).offset(24);
        make.height.width.offset(36);
    }];
    
    [self.logoView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(25);
        make.height.offset(116);
        make.width.offset(127);
        make.centerX.equalTo(self.view);
    }];
    
    [self.meetingIdTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.logoView.mas_bottom).offset(10);
        make.height.offset(40);
        make.width.offset(300);
        make.centerX.equalTo(self.view);
    }];
    
    [self.userNameTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.meetingIdTextField.mas_bottom).offset(20);
        make.height.offset(40);
        make.width.offset(300);
        make.centerX.equalTo(self.view);
    }];
    
    [self.joinButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.userNameTextField.mas_bottom).offset(25);
        make.height.offset(44);
        make.width.offset(300);
        make.centerX.equalTo(self.view);
    }];
    
    [self.openVisitorButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.joinButton.mas_bottom).offset(20);
        make.height.offset(20);
        make.width.offset(100);
        make.left.equalTo(self.userNameTextField.mas_left);
    }];
    
    [self.closeVideoButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.openVisitorButton.mas_top);
        make.height.offset(20);
        make.width.offset(140);
        make.right.equalTo(self.joinButton.mas_right).offset(0);
    }];
    [self.view layoutIfNeeded];
}

- (void)dismisAlertViewIfNeed {
    if(self.alertView) {
        [self.alertView dismissWithClickedButtonIndex:0 animated:NO];
    }
}

- (void)addGesture{
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] init];
    [tap addTarget:self action:@selector(didResignFirstResponder)];
    [self.view addGestureRecognizer:tap];
}
#pragma mark - Getters & setters
- (UIButton *)setButton{
    if (!_setButton) {
        _setButton = [[UIButton alloc] init];
        [_setButton setImage:[UIImage imageNamed:@"set"] forState:(UIControlStateNormal)];
        [_setButton addTarget:self action:@selector(onTapSetButton) forControlEvents:(UIControlEventTouchUpInside)];
    }
    return _setButton;
}

- (UIImageView *)logoView{
    if (!_logoView) {
        _logoView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"meeting_logo"]];
    }
    return _logoView;
}

- (UITextField *)meetingIdTextField{
    if (!_meetingIdTextField) {
        _meetingIdTextField = [[InputTextField alloc] init];
        _meetingIdTextField.placeholder = NSLocalizedStringFromTable(@"MeetingId", @"SealMeeting", nil);
        _meetingIdTextField.delegate = self;
        _meetingIdTextField.tag = meetingIdTextFieldTag;
        _meetingIdTextField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
    }
    return _meetingIdTextField;
}

- (UITextField *)userNameTextField{
    if (!_userNameTextField) {
        _userNameTextField = [[InputTextField alloc] init];
        _userNameTextField.placeholder = NSLocalizedStringFromTable(@"UserName", @"SealMeeting", nil);
        _userNameTextField.delegate = self;
        _userNameTextField.tag = userNameTextFieldTag;
    }
    return _userNameTextField;
}

- (SelectionButton *)openVisitorButton{
    if (!_openVisitorButton) {
        _openVisitorButton = [[SelectionButton alloc] init];
        [_openVisitorButton setTitle:NSLocalizedStringFromTable(@"OpenVisitor", @"SealMeeting", nil) forState:UIControlStateNormal];
        [_openVisitorButton setSelected:NO];
    }
    return _openVisitorButton;
}

- (SelectionButton *)closeVideoButton{
    if (!_closeVideoButton) {
        _closeVideoButton = [[SelectionButton alloc] init];
        [_closeVideoButton setTitle:NSLocalizedStringFromTable(@"OpenVideo", @"SealMeeting", nil) forState:UIControlStateNormal];
        [_closeVideoButton setSelected:NO];
    }
    return _closeVideoButton;
}


- (UIButton *)joinButton{
    if (!_joinButton) {
        _joinButton = [[UIButton alloc] init];
        [_joinButton addTarget:self action:@selector(onJoin:) forControlEvents:(UIControlEventTouchUpInside)];
        [_joinButton setTitle:NSLocalizedStringFromTable(@"JoinMeeting", @"SealMeeting", nil) forState:(UIControlStateNormal)];
        _joinButton.layer.masksToBounds = YES;
        _joinButton.layer.cornerRadius = 22;
        CAGradientLayer *gradientLayer =  [CAGradientLayer layer];
        gradientLayer.frame = CGRectMake(0, 0, 300, 44);
        gradientLayer.startPoint = CGPointMake(0, 0);
        gradientLayer.endPoint = CGPointMake(1, 0);
        gradientLayer.locations = @[@(0),@(1.0)];//渐变点
        UIColor *startColor = HEXCOLOR(0xffcc00);
        UIColor *endColor = HEXCOLOR(0xe1621b);
        [gradientLayer setColors:@[(id)(startColor.CGColor),(id)(endColor.CGColor)]];//渐变数组
        [_joinButton.layer addSublayer:gradientLayer];
        _joinButton.enabled = NO;
        _joinButton.alpha = 0.5;
    }
    return _joinButton;
}
@end
