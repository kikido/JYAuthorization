### 综述

在iOS开发中，我们会用到手机的隐私服务，例如`定位`，`相机`，`麦克风`。在使用这些服务之前，我们要先判断该服务是否可用，用户在该 app 是否可以使用这项服务，然后根据结果执行不同的代码，功能一多的话就会显得繁琐。

为了解决这个问题，写了[JYAuthorization](https://github.com/kikido/JYAuthorization)这个框架，旨在快速获取以及查询iOS的功能权限，将更多的精力放在业务上。

![快速的获取及查询功能权限](https://ws1.sinaimg.cn/large/006tKfTcly1g10wx1k625g30a00dcb29.gif)

### 支持的类型及要求

- ARC
- iOS 8.0+
- OC

目前支持的隐私类型(如果有需要，后面会继续添加)：

```
JYServiceTypeLocationWhenInUse, // 定位（使用应用期间）
JYServiceTypeLocationAlways, // 定位(始终)
JYServiceTypeAddressBook, // 通讯录
JYServiceTypeCalendar, // 日历
JYServiceTypeReminder, // 提醒
JYServiceTypePhoto, // 相册
JYServiceTypeMicroPhone, // 麦克风
JYServiceTypeCamera, // 相机
JYServiceTypeSpeechRecognition, // 语音识别
JYServiceTypeHealth // 健康
```

> 因为 iOS 保护用户隐私的问题，可能在使用 JYAuthorization 之后会出现打包上传后被退回的情况。举个例子，你的项目中不需要使用语音识别这个服务，但因为 JYAuthorization 包含了访问了语音识别的代码，打包上传后还是会被拒绝掉。
> 
> 为了避免出现这个问题，JYAuthorization 将所有的服务按块都注释掉了。如果你需要使用某个服务，请在 JYAuthorizationManager.m 文件中将该服务的代码取消注释掉

### 如何使用

假设我们有一个需求：调用iOS的定位服务。
那么我们可以像下面这样做：

```
- (void)startLocationService
{
    JYAuthorizationManager *authManager = [JYAuthorizationManager shareManager];
    [authManager requestAccessToServiceType:JYServiceTypeLocationWhenInUse completion:^(BOOL granted, NSError * _Nonnull error) {
        if (granted) {
            // 有权限的话
            self.locationManager = [[CLLocationManager alloc] init];
            self.locationManager.delegate = self;
            self.locationManager.distanceFilter = 50;
            self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
            [self.locationManager startUpdatingLocation];
        } else {
            // 没有权限
            [JYAuthorizationManager jy_showErrorDetail:error viewController:self];
        }
    }];
}
```

使用`JYAuthorization`，你只需要考虑两种情况：1.可用 2.不可用。在上面的例子中，如果定位的状态是 not determined，那么 JYAuthorization 会自动帮你请求该服务权限，若被授权该服务权限，则执行 completion 里面的代码，若无权限，则给出提示，用户点击后会自动跳转到该应用的服务设置界面。

> 当然，现在有很多应用，为了最大限度的让用户授予权限，会在服务状态是 not determined 时，跳出一个自定义的弹框提示，说明获取权限的重要性，等用户确认会再弹出系统的授权界面。 使用 JYAuthorization 也能够很方便的实现这个权限。示例如下：

```
- (void)startLocationService
{
    JYAuthorizationManager *authManager = [JYAuthorizationManager shareManager];
    authManager.accessIfNotDetermined = false;
    [authManager requestAccessToServiceType:JYServiceTypeLocationWhenInUse completion:^(BOOL granted, NSError * _Nonnull error) {
        if (granted) {
            // 有权限的话
            // todo...
        } else {
            if (error.code == JYAuthorizationErrorNotDetermined) {
                // 如果尚未决定权限，跳出自己的提示页面
                // 1.客户在自己的提示页面点击确定之后，修改`accessIfNotDetermined`为YES，且再次调用`- (void)requestAccessToServiceType:(JYServiceType)authType completion:(void(^)(BOOL granted, NSError *error))completion`这个方法
            } else {
                [authManager jy_showErrorDetail:error viewController:self];
            }
        }
    }];
}
```

### NSError的使用
`NSError`如果有不明白的可以看我的另一篇博客[NSError](https://kikido.github.io/2019/03/13/NSError%E4%BA%86%E8%A7%A3%E4%B8%80%E5%93%88/)，在这里简单说明下：

- error.domain为自定义的错误域`JYAuthErrorDomain`
- error.code为错误代码，错误类型如下
```
typedef NS_ENUM(NSInteger, JYAuthorizationStatus){
    JYAuthorizationErrorNone = 0,
    JYAuthorizationErrorGranted = 1, // 已授权
    JYAuthorizationErrorNotDetermined = -100, // 未授权
    JYAuthorizationErrorRestricted = -101, // 该应用无权使用该服务，且无法更改这一状态
    JYAuthorizationErrorDenied = -102, // 用户拒绝给该应用服务的权限，或在设置中全局将该服务禁用
    JYAuthorizationErrorUnServiced = -1000, // 手机尚未启用该服务
    JYAuthorizationErrorLowVersion = -2000 // 版本过低，不提供该服务
};
```
- error.localizedDescription：错误描述，具体信息你可以在`Localizable.strings`中修改
- error.localizedRecoverySuggestion：错误恢复建议，具体信息你可以在`Localizable.strings`中修改
- 如果error.userInfo[JYAuthOpenSettingKey]有值，那么在提示错误时，您可以选择点击`前往`，前往设置界面

#### accessIfNotDetermined属性

这是一个BOOL类型的值，默认为YES。当 accessIfNotDetermined 为 YES的时，调用`- (void)requestAccessToServiceType:(JYServiceType)authType completion:(void(^)(BOOL granted, NSError *error))completion`，如果权限是`JYAuthorizationErrorNotDetermined`(未授权)，会直接调用方法请求服务权限。


#### dontAlertIfNotDetermined属性

这是一个BOOL类型的值，默认为YES。值为YES的时候，当你调用`- (void)jy_showErrorDetail:(NSError *)error viewController:(UIViewController *)viewController`时，如果erroe的code(错误码)是`JYAuthorizationErrorNotDetermined`(-100)的话，则不会显示错误提示。

### 结束

好了，说明就到此为止了。如果有错误的话，欢迎指出~


