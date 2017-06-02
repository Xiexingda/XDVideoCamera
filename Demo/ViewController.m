//
//  ViewController.m
//  摄像
//  作者：谢兴达（XD）
//  Created by 谢兴达 on 2017/3/1.
//  Copyright © 2017年 谢兴达. All rights reserved.
//  github链接：https://github.com/Xiexingda/XDVideoCamera.git


#import "ViewController.h"
#import "SelectLabel.h"
#import "XDVideocamera.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor lightGrayColor];
    [self enterVideoCameraUI];
}

//进入摄像机
- (void)enterVideoCameraUI {
    SelectLabel *enterVideo = [[SelectLabel alloc]initWithFrame:CGRectMake(15, 128, self.view.bounds.size.width - 30, 44)];
    enterVideo.backgroundColor = [UIColor redColor];
    enterVideo.text = @"摄相机";
    enterVideo.clipsToBounds = YES;
    enterVideo.layer.cornerRadius = 5;
    enterVideo.textAlignment = NSTextAlignmentCenter;
    [enterVideo tapGestureBlock:^(id obj) {
        XDVideocamera *video = [[XDVideocamera alloc]init];
        [self presentViewController:video animated:YES completion:^{
            NSLog(@"进入照相机");
        }];
    }];
    [self.view addSubview:enterVideo];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
