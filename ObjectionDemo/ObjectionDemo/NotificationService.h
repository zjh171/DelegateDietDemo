//
//  NotificationService.h
//  ObjectionDemo
//
//  Created by zhujinhui on 2018/3/15.
//  Copyright © 2018年 kyson. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ServiceProtocol.h"


@protocol NotificationServiceProtocol<ServiceProtocol>

@end


/**
 Notification Service
 */
@interface NotificationService : NSObject<NotificationServiceProtocol>


@end
