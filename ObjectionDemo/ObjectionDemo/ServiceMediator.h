//
//  ServiceMediator.h
//  ObjectionDemo
//
//  Created by zhujinhui on 2018/3/15.
//  Copyright © 2018年 kyson. All rights reserved.
//

#import <Foundation/Foundation.h>




@protocol ServiceMediatorProtocol<NSObject>

-(void)route;

@end


/**
 Service Mediator
 */
@interface ServiceMediator : NSObject<ServiceMediatorProtocol>




@end
