//
//  ServiceMediator.m
//  ObjectionDemo
//
//  Created by zhujinhui on 2018/3/15.
//  Copyright © 2018年 kyson. All rights reserved.
//

#import "ServiceMediator.h"
#import "ShareService.h"
#import "NotificationService.h"
#import <Objection/Objection.h>


@implementation ServiceMediator

-(void)route
{
    // 通知服务
    JSObjectionInjector *injector = [JSObjection defaultInjector];
    NSObject<NotificationServiceProtocol> *notificationService = [injector getObject:@protocol(NotificationServiceProtocol)];
    [notificationService start];
    // 分享服务
    NSObject<ShareServiceProtocol> *shareService = [injector getObject:@protocol(ShareServiceProtocol)];
    [shareService start];
}

@end
