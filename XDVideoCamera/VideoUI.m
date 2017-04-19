//
//  VideoUI.m
//  摄像
//
//  Created by 谢兴达 on 2017/3/3.
//  Copyright © 2017年 谢兴达. All rights reserved.
//

#import "VideoUI.h"

@interface VideoUI ()
@property (nonatomic, strong) SelectImageView *changeBt;
@property (nonatomic, strong) SelectImageView *videoBt;
@property (nonatomic, strong) SelectView *VideoLayerView;
@property (nonatomic, strong) UIView *focusView;
@property (nonatomic, strong) UIView *headerContent;
@property (nonatomic, strong) UIView *footerContent;
@property (nonatomic, strong) SelectImageView *cancel;

@property (nonatomic, strong) SelectImageView *combine;

@end

@implementation VideoUI
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self creatMainUI];
    }
    return self;
}

- (void)creatMainUI {
    [self creatHeader];
}

- (void)creatHeader {
    _headerContent = [[UIView alloc]initWithFrame:CGRectMake(0,
                                                             0,
                                                             self.frame.size.width,
                                                             60)];
    _headerContent.backgroundColor = [UIColor greenColor];
    [self addSubview:_headerContent];
    
    _cancel = [[SelectImageView alloc]initWithFrame:CGRectMake(CGRectGetMinX(_headerContent.frame) + 15,
                                                               20,
                                                               40,
                                                               40)];
    _cancel.backgroundColor = [UIColor grayColor];
    [_headerContent addSubview:_cancel];
    [_cancel tapGestureBlock:^(id obj) {
        [self.delegate cancelClick];
    }];
    
    _changeBt = [[SelectImageView alloc]initWithFrame:CGRectMake(CGRectGetMaxX(_headerContent.frame) - 55,
                                                                 20,
                                                                 40,
                                                                 40)];
    _changeBt.backgroundColor = [UIColor redColor];
    [_headerContent addSubview:_changeBt];
    
    [_changeBt tapGestureBlock:^(id obj) {
        if ([self.delegate changeBtClick]) {
            NSLog(@"后置摄像头");
            
        } else {
            NSLog(@"前置摄像头");
        }
    }];
    
    [self creatLayerView];
}

- (void)creatLayerView {
    _VideoLayerView = [[SelectView alloc]initWithFrame:CGRectMake(CGRectGetMinX(_headerContent.frame),
                                                                  CGRectGetMaxY(_headerContent.frame),
                                                                  CGRectGetWidth(_headerContent.frame),
                                                                  self.frame.size.height - 120)];
    _VideoLayerView.backgroundColor = [UIColor blackColor];
    [self addSubview:_VideoLayerView];
    [_VideoLayerView tapGestureBlock:^(UITapGestureRecognizer *gesture) {
        [self.delegate videoLayerClick:_VideoLayerView gesture:gesture];
    }];
    
    _focusView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 60, 60)];
    _focusView.backgroundColor = [UIColor clearColor];
    _focusView.layer.borderColor = [UIColor greenColor].CGColor;
    _focusView.layer.borderWidth = 1.5;
    _focusView.alpha = 0;
    [_VideoLayerView addSubview:_focusView];
    
    [self creatFooter];
}

- (void)creatFooter {
    _footerContent = [[UIView alloc]initWithFrame:CGRectMake(CGRectGetMinX(_VideoLayerView.frame),
                                                             CGRectGetMaxY(_VideoLayerView.frame),
                                                             CGRectGetWidth(_VideoLayerView.frame),
                                                             60)];
    _footerContent.backgroundColor = [UIColor greenColor];
    [self addSubview:_footerContent];
    
    _videoBt = [[SelectImageView alloc]initWithFrame:CGRectMake(CGRectGetMidX(_footerContent.frame) - 40,
                                                                10,
                                                                80,
                                                                40)];
    _videoBt.backgroundColor = [UIColor grayColor];
    [_footerContent addSubview:_videoBt];
    [_videoBt tapGestureBlock:^(id obj) {
        if ([self.delegate videoBtClick]) {
            NSLog(@"正在录制");
            _videoBt.backgroundColor = [UIColor redColor];
            
        } else {
            NSLog(@"录制停止");
            _videoBt.backgroundColor = [UIColor grayColor];
        }
        
    }];
    
    _combine = [[SelectImageView alloc]initWithFrame:CGRectMake(CGRectGetMaxX(_videoBt.frame)+30, 10, 80, 40)];
    _combine.backgroundColor = [UIColor redColor];
    [_footerContent addSubview:_combine];
    [_combine tapGestureBlock:^(id obj) {
        [self.delegate mergeClick];
    }];
}

- (void)viewsLinkBlock:(neededViewBlock)block {
    if (block) {
        block(_focusView,_VideoLayerView);
    }
}
@end
