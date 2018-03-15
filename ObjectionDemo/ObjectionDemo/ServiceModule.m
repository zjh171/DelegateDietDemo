//
//  ServiceModule.m
//  ObjectionDemo
//
//  Created by zhujinhui on 2018/3/15.
//  Copyright © 2018年 kyson. All rights reserved.
//

#import "ServiceModule.h"
#import "ServiceProtocol.h"
#import "NotificationService.h"
#import "ShareService.h"
#import "ServiceMediator.h"

@implementation ServiceModule


+(void)load
{
    JSObjectionInjector *injector = [JSObjection defaultInjector];
    injector = injector ? : [JSObjection createInjector];
    injector = [injector withModule:[[self alloc] init]];
    [JSObjection setDefaultInjector:injector];
}

-(void)configure
{
    
    [self bindClass:[ServiceMediator class] toProtocol:@protocol(ServiceMediatorProtocol)];

    [self bindClass:[NotificationService class] toProtocol:@protocol(NotificationServiceProtocol)];
    [self bindClass:[ShareService class] toProtocol:@protocol(ShareServiceProtocol)];
}

@end
