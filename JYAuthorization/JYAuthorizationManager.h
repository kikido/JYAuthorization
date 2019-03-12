//
//  JYAuthorizationManager.h
//  pinlv
//
//  Created by dqh on 2019/3/7.
//  Copyright © 2019 dqh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *__nonnull const JYAuthErrorDomain;
extern NSString *__nonnull const JYAuthOpenSettingKey;

typedef NS_ENUM(NSInteger, JYAuthorizationStatus){
    JYAuthorizationErrorNone = 0,
    ///|< 已授权
    JYAuthorizationErrorGranted = 1,
    ///|< 未授权
    JYAuthorizationErrorNotDetermined = -100,
    ///|< 无授权，切用户无法改变这个状态。例如，家长控制
    JYAuthorizationErrorRestricted = -101,
    ///|< 授权被拒绝
    JYAuthorizationErrorDenied = -102,
    ///|< 尚未启用该服务
    JYAuthorizationErrorUnServiced = -1000,
    ///|< 版本过低，不支持该服务
    JYAuthorizationErrorLowVersion = -2000
};

typedef NS_ENUM(NSUInteger, JYServiceType){
    JYServiceTypeNone,
    ///|< 定位-使用应用期间
    JYServiceTypeLocationWhenInUse,
    ///|< 定位-使用使用
    JYServiceTypeLocationAlways,
    ///|< 通讯录
    JYServiceTypeAddressBook,
    ///|< 日历
    JYServiceTypeCalendar,
    ///|< 提醒
    JYServiceTypeReminder,
    ///|< 相册
    JYServiceTypePhoto,
    ///|< 蓝牙
//    JYServiceTypeBlueTooth,
    ///|< 麦克风
    JYServiceTypeMicroPhone,
    ///|< 相机
    JYServiceTypeCamera,
    ///|< 语音识别
    JYServiceTypeSpeechRecognition,
    ///|< 健康
    JYServiceTypeHealth
};

@interface JYAuthorizationManager : NSObject

///|< 如果还没有决定权限的话就直接获取权限，·default·是YES.当为yes时，也不会提示error
@property (nonatomic, assign) BOOL accessIfNotDetermined;
///|< 如果还没决定权限的话就不显示error，·default·是YES
@property (nonatomic, assign) BOOL dontAlertIfNotDetermined;

+ (instancetype)shareManager;

- (void)requestAccessToServiceType:(JYServiceType)authType completion:(void(^)(BOOL granted, NSError *error))completion;

- (void)jy_showErrorDetail:(NSError *)error viewController:(UIViewController *)viewController;

@end

NS_ASSUME_NONNULL_END




