//
//  XDVideoManager.h
//  摄像
//
//  Created by 谢兴达 on 2017/3/23.
//  Copyright © 2017年 谢兴达. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface XDVideoManager : NSObject

+ (XDVideoManager *)defaultManager;

/**
 视频资源管理

 @param tArray 视频地址数组
 @param storePath 存储路径
 @param storeName 存储名称
 @param task 后台任务用于确保突发事件在后台完成视频存储
 @param successBlock 视频拼接完成回调
 @param failureBlcok 视频拼接、存储失败回调
 */
- (void)mergeVideosToOneVideo:(NSArray *)tArray toStorePath:(NSString *)storePath WithStoreName:(NSString *)storeName backGroundTask:(UIBackgroundTaskIdentifier)task success:(void (^)(NSString *info))successBlock failure:(void (^)(NSString *error))failureBlcok;

@end
