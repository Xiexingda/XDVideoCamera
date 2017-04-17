//
//  VideoUI.h
//  摄像
//
//  Created by 谢兴达 on 2017/3/3.
//  Copyright © 2017年 谢兴达. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SelectView.h"
#import "SelectImageView.h"

typedef void (^neededViewBlock)(UIView *focusView, SelectView *previewView);

/**
 代理方法
 */
@protocol VideoUIDelegate <NSObject>
- (void)cancelClick;
- (BOOL)changeBtClick;
- (BOOL)videoBtClick;
- (void)mergeClick;
- (void)videoLayerClick:(SelectView *)view gesture:(UITapGestureRecognizer *)gesture;
@end

@interface VideoUI : UIView

@property (nonatomic, weak) id<VideoUIDelegate> delegate;

- (void)viewsLinkBlock:(neededViewBlock)block;

@end
