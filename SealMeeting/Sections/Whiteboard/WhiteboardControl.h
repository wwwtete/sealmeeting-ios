//
//  WhiteboardControl.h
//  SealMeeting
//
//  Created by Zhaoqianyu on 2019/3/12.
//  Copyright © 2019 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RoomMember.h"
@class WhiteboardView;
@protocol WhiteboardControlDelegate<NSObject>
- (void)didTurnPage:(NSInteger)pageNum;
- (void)whiteboardViewDidChangeZoomScale:(float)scale;
@end



@interface WhiteboardControl : NSObject
@property(nonatomic, strong) WhiteboardView *wbView;
@property(nonatomic, copy, readonly) NSString *currentWhiteboardId;
@property(nonatomic, copy, readonly) NSString *currentWhiteboardURL;
@property(nonatomic, assign, readonly) BOOL wBoardDisplayed;

- (instancetype)init __attribute__((unavailable("init not available, call initWithDelegate instead")));
+ (instancetype)new __attribute__((unavailable("new not available, call initWithDelegate instead")));

- (instancetype)initWithDelegate:(id<WhiteboardControlDelegate>)delegate;
- (void)loadWBoardWith:(NSString *)wBoardID
             wBoardURL:(NSString *)wBoardURL
                 frame:(CGRect)frame;
- (void)moveToSuperView:(UIView *)superView;
- (void)hideBoard;
- (void)destroyBoard;
- (void)turnPage:(NSInteger)pageNum;
- (void)setWBoardFrame:(CGRect)newFrame;
- (void)moveWBoard:(CGFloat)offset;
- (void)didChangeRole:(Role)role;

@end

