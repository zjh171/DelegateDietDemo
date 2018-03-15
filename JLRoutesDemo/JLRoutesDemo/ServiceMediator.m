//
//  ServiceMediator.m
//  JLRoutesDemo
//
//  Created by zhujinhui on 2018/3/14.
//  Copyright © 2018年 kyson. All rights reserved.
//

#import "ServiceMediator.h"
#import "RemoteNotificationService.h"
#import "ShareService.h"

@implementation ServiceMediator


+(void)startRoute
{
    [RemoteNotificationService startService];
    
    [ShareService startService];
}



@end
