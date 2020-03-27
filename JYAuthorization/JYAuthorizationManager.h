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

extern NSString * const JYAuthErrorDomain;
extern NSString * const JYAuthOpenSettingKey;

typedef NS_ENUM(NSInteger, JYAuthorizationStatus) {
    JYAuthorizationStatusNone = 0,
    /** 已授权 */
    JYAuthorizationStatusGranted = 1,
    /** 未授权 */
    JYAuthorizationStatusNotDetermined = -100,
    /** 该应用无权使用该服务，且无法更改这一状态 */
    JYAuthorizationStatusRestricted = -101,
    /** 用户拒绝给该应用服务的权限，或在设置中全局将该服务禁用 */
    JYAuthorizationStatusDenied = -102,
    /** 手机尚未启用该服务 */
    JYAuthorizationStatusUnServiced = -1000,
    /** 版本过低，不提供该服务 */
    JYAuthorizationStatusLowVersion = -2000
};

typedef NS_ENUM(NSUInteger, JYServiceType) {
    JYServiceTypeNone,
    /** 定位（使用应用期间） */
    JYServiceTypeLocationWhenInUse,
    /** 定位(始终) */
    JYServiceTypeLocationAlways,
    /** 通讯录 */
    JYServiceTypeAddressBook,
    /** 日历 */
    JYServiceTypeCalendar,
    /** 提醒 */
    JYServiceTypeReminder,
    /** 相册 */
    JYServiceTypePhoto,
    /** 麦克风 */
    JYServiceTypeMicroPhone,
    /** 相机 */
    JYServiceTypeCamera,
    /** 语音识别 */
    JYServiceTypeSpeechRecognition,
    /** 健康 */
    JYServiceTypeHealth
};

@interface JYAuthorizationManager : NSObject

/**
 * 查询 app 是否能够使用某项服务
 *
 * @note 为了避免打包失败，比如你不需要使用语音识别这个服务，但因为 JYAuthorization 包含了访问了语音识别的代码，打包上传的时候会被拒绝掉
   为了避免出现这个问题，JYAuthorization 将所有的服务按块都注释掉了，如果你需要使用某个服务，请在 JYAuthorizationManager.m 文件中将该服务的代码取消注释掉
 
 * @param accessIfNotDetermined 如果尚未分配隐私的权限，是否直接去请求该权限。YES 表示直接获取
 * @param authType 服务类型
 * @param completion 查询得到结果后的下一步操作
 */
- (void)requestAccessToService:(JYServiceType)authType
         accessIfNotDetermined:(BOOL)accessIfNotDetermined
                    completion:(void(^)(BOOL granted, NSError *error))completion;

/**
 * 在指定的 UIViewController 显示提示信息
 *
 * @discuss 使用该方法显示提示信息，可以根据 NSError 的建议，跳转到 app 的设置界面，比较方便
 *
 * @param error 错误信息
 * @param viewController 指定的 UIViewController
 */
+ (void)showErrorDetail:(NSError *)error viewController:(UIViewController *)viewController;

@end

NS_ASSUME_NONNULL_END




