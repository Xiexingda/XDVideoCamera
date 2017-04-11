//
//  SelectImageView.m
//  二级界面
//
//  Created by 谢兴达 on 16/9/19.
//  Copyright © 2016年 谢兴达. All rights reserved.
//  自定义可点击imageView

#import "SelectImageView.h"

@interface SelectImageView()

@property (nonatomic, copy) void (^action)(id obj);

@end

@implementation SelectImageView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = YES;
    }
    return self;
}

- (instancetype)init {
    return [self initWithFrame:CGRectZero];
}

- (void)tapGestureBlock:(void(^)(id obj))action {
    self.action = [action copy];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tap)];
    [self addGestureRecognizer:tap];
}

- (void)tap {
    if (self.action) {
        self.action(self);
    }
}

@end
