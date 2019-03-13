### 综述

在iOS开发中，我们总会用到许多iOS的隐私功能，例如`定位`，`相机`，`麦克风`等。在编写这些功能代码的时候，我们都要先判断是否拥有权限，然后根据有无代码执行不同的操作，功能一多的话就会显得繁琐。为了解决这个问题，我自己编写了[JYAuthorization](https://github.com/EchoZuo/ECAuthorizationTools)这一个框架，旨在快速获取以及查询iOS的功能权限，将更多的精力放在业务上。

![快速的获取及查询功能权限](https://ws1.sinaimg.cn/large/006tKfTcly1g10wx1k625g30a00dcb29.gif)

### 支持的类型及要求

- ARC
- iOS 8.0+
- OC

目前支持的隐私类型(如果有需要，后面会继续添加)：
```
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
    ///|< 麦克风
    JYServiceTypeMicroPhone,
    ///|< 相机
    JYServiceTypeCamera,
    ///|< 语音识别
    JYServiceTypeSpeechRecognition,
    ///|< 健康
    JYServiceTypeHealth
};
```

### JYAuthorizationManager

`JYAuthorizationManager`是一个单例，负责查询以及保存功能权限的数据。

1. 你可以通过类方法`shareManager`来创建实例
2. 通过实例方法`- (void)requestAccessToServiceType:(JYServiceType)authType completion:(void(^)(BOOL granted, NSError *error))completion`可以快速的查询功能权限。error的使用下面会有说明
3. 查询过的权限结果(除JYAuthorizationErrorNotDetermined)，将被保存在私有属性`authDict`中。因为`iOS`的隐私功能权限，如果被修改过了，那么当前应用是会被强制退出的，所以当前的查询结果可以保存起来，避免重复查询
4. 如果想要显示查询的Error，你可以调用实例方法`jy_showErrorDetail:(NSError *)error viewController:(UIViewController *)viewController`，效果就跟上面的gif图中的效果一样
5. `JYAuthorization`支持多语言，你可以在`JYAuthorization.bundle`里面的`Localizable.strings`的文件中修改不同的提示语。
![语言国际化](https://ws2.sinaimg.cn/large/006tKfTcly1g10xt1g94rj31ks0p878h.jpg)


#### NSError的使用
`NSError`如果有不明白的可以看我的另一篇博客[未发布](www.baidu.com)，在这里简单说明下：

- error.domain为自定义的错误域`JYAuthErrorDomain`
- error.code为自定义的值
```
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
```
- error.localizedDescription：错误描述，具体信息你可以在`Localizable.strings`中修改
- error.localizedRecoverySuggestion：错误恢复建议，具体信息你可以在`Localizable.strings`中修改
- 如果error.userInfo[JYAuthOpenSettingKey]有值，那么在提示错误时，您可以选择点击`前往`，前往设置界面

#### accessIfNotDetermined属性

这是一个BOOL类型的值，默认为YES。值为YES的时候，当你调用`- (void)requestAccessToServiceType:(JYServiceType)authType completion:(void(^)(BOOL granted, NSError *error))completion`时，如果权限是`JYAuthorizationErrorNotDetermined`(未授权)，则会直接调用方法请求权限。



#### dontAlertIfNotDetermined属性

这是一个BOOL类型的值，默认为YES。值为YES的时候，当你调用`- (void)jy_showErrorDetail:(NSError *)error viewController:(UIViewController *)viewController`时，如果erroe的code(错误码)是`JYAuthorizationErrorNotDetermined`(-100)的话，则不会显示错误提示。

### 如何使用

假设我们有一个需求：调用iOS的定位服务。那么我们可以像下面这样：

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
            [authManager jy_showErrorDetail:error viewController:self];
        }
    }];
}
```

使用`JYAuthorization`，你不需要考虑有没有权限，是否未决定权限。在上面的例子中，如果尚未决定权限，并且`error.code`是`JYAuthorizationErrorNotDetermined`的话，会自动帮你请求权限，并且在获取权限之后，执行completion里面的回调。

> 当然，现在的很多应用，为了能够获取客户的权限，都会在申请权限之前，跳出一个弹框提示，说明获取权限的重要性，那么使用`JYAuthorization`也能够很方便的实现这个权限。示例如下：

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
### 结束

好了，说明就到此为止了。如果有错误的话，欢迎指出~


