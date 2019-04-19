//
//  QRCodeView.m
//  SealMeeting
//
//  Created by 张改红 on 2019/4/2.
//  Copyright © 2019 RongCloud. All rights reserved.
//

#import "QRCodeView.h"
#import <Masonry.h>
#import "ZXMultiFormatWriter.h"
#import "ZXImage.h"
#import "ShareTemplate.h"
#import "ClassroomService.h"
@interface QRCodeView ()
@property (nonatomic, strong) UIImageView *codeImageView;
@end

@implementation QRCodeView
#pragma mark - Life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = NSLocalizedStringFromTable(@"QRTitle", @"SealMeeting", nil);
    [self setNaviLeftBar];
    [self setupSubviews];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

//设置是否隐藏
- (BOOL)prefersStatusBarHidden {
    return NO;
}
#pragma mark - Helper
- (void)setNaviLeftBar{
    UIBarButtonItem *leftBar = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringFromTable(@"Cancel", @"SealMeeting", nil) style:(UIBarButtonItemStylePlain) target:self action:@selector(cancel)];
    self.navigationItem.leftBarButtonItem = leftBar;
}

- (void)cancel{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)setupSubviews{
    [self.view addSubview:self.codeImageView];
    [self.codeImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(125);
        make.centerX.equalTo(self.view);
        make.width.height.offset(158);
    }];
    
    UILabel *Label = [[UILabel alloc] init];
    Label.text = NSLocalizedStringFromTable(@"QRTip", @"SealMeeting", nil);
    Label.textAlignment = NSTextAlignmentCenter;
    Label.font = [UIFont systemFontOfSize:14];
    [self.view addSubview:Label];
    [Label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.codeImageView.mas_bottom).offset(18);
        make.left.offset(0);
        make.right.offset(0);
        make.height.offset(16);
    }];
}

- (UIImage *)createCode{
    ZXMultiFormatWriter *writer = [[ZXMultiFormatWriter alloc] init];
    ZXBitMatrix *result = [writer encode:[ShareTemplate getURLTemplate:[ClassroomService sharedService].currentRoom.roomId] format:kBarcodeFormatQRCode width:125 height:125 error:nil];
    ZXImage *image = [ZXImage imageWithMatrix:result];
    return [UIImage imageWithCGImage:image.cgimage];
}
#pragma mark - Getter and setter
- (UIImageView *)codeImageView{
    if (!_codeImageView) {
        _codeImageView = [[UIImageView alloc] init];
        _codeImageView.image = [self createCode];
    }
    return _codeImageView;
}
@end
