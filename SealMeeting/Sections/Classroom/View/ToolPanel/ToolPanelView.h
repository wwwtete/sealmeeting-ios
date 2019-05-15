//
//  ToolPanelView.h
//  SealMeeting
//
//  Created by Sin on 2019/2/28.
//  Copyright © 2019年 RongCloud. All rights reserved.
//

#import <UIKit/UIKit.h>

#define LLeftToolViewTop 82
#define LLeftButtonWidht     24
typedef enum : NSUInteger {
    ToolPanelViewActionTagWhiteboard,
    ToolPanelViewActionTagRecentlyShared,
    ToolPanelViewActionTagOnlinePerson,
    ToolPanelViewActionTagVideoList,
    ToolPanelViewActionTagClassNews,
} ToolPanelViewActionTag;

@class ToolPanelView;
@protocol ToolPanelViewDelegate <NSObject>

- (void)toolPanelView:(UIButton *)button didTapAtTag:(ToolPanelViewActionTag)tag;

@end

@interface ToolPanelView : UIView

@property (nonatomic, strong) NSMutableArray *buttonArray;

@property (nonatomic, weak) id<ToolPanelViewDelegate> delegate;

- (void)reloadToolPanelView;
- (void)foldToolPanelView;
@end


