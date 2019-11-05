//
//  JYAuthorizationManager.m
//  pinlv
//
//  Created by dqh on 2019/3/7.
//  Copyright © 2019 dqh. All rights reserved.
//

#import "JYAuthorizationManager.h"
#import <CoreLocation/CoreLocation.h>    // 定位
//#import <AddressBook/AddressBook.h>      // 通讯录
//#import <Contacts/Contacts.h>           // 通讯录
//#import <EventKit/EventKit.h>           // 日历，提醒
//#import <Photos/Photos.h>               // 相机
//#import <AVFoundation/AVFoundation.h>    // 麦克风，相机
//#import <CoreBluetooth/CoreBluetooth.h>  // 蓝牙
//#import <Speech/Speech.h>               // 语音识别
//#import <HealthKit/HealthKit.h>         // 健康


NSString * const JYAuthErrorDomain    = @"JYAuthErrorDomain";
NSString * const JYAuthOpenSettingKey = @"JYAuthOpenSettingKey";


@interface JYAuthorizationManager () <CLLocationManagerDelegate>

/** 服务类型 */
@property (nonatomic, assign) JYServiceType serviceType;

/**
 * 保存验证结果字典
 *
 * @discuss 有一些服务，当你在系统设置更改了该 app 里该服务的权限后，该 app 会重启，所以可以将结果存储保存起来
 */
@property (nonatomic, strong) NSMutableDictionary *authDict;

//------------------------------
/// @name location
///-----------------------------

/**
 * 定位服务的入口
 *
 * 检测定位服务权限时需长持有该对象
 */
@property (nonatomic, strong) CLLocationManager *locationManager;

/**
 * 在验证 定位 权限时使用，执行完毕会置为 nil
 *
 * @discuss 当第一次验证时如果结果是 not determined，此时需要保存 completion
 */
@property (nonatomic, copy) void(^locationCompletion)(BOOL granted, NSError *error);

@end

@implementation JYAuthorizationManager

+ (instancetype)shareManager
{
    static JYAuthorizationManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (manager == nil) {
            manager = [[super allocWithZone:NULL] init];
            manager.accessIfNotDetermined    = true;
            manager.dontAlertIfNotDetermined = true;
            manager.authDict                 = [NSMutableDictionary dictionary];
        }
    });
    return manager;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
    return [self shareManager];
}

#pragma mark -

- (void)requestAccessToService:(JYServiceType)authType completion:(void(^)(BOOL granted, NSError *error))completion
{
    NSError *authError = self.authDict[@(authType)];
    // 如果不为空，则表示已经验证过权限了，且结果不通过
    if ([authError isKindOfClass:[NSError class]]) {
        completion(false, authError);
        return;
    }
    // 如果这个值是NSNull对象，那就代表已经检查过权限，且结果通过
    if ([authError isKindOfClass:[NSNull class]]) {
        completion(true, nil);
        return;
    }
    CGFloat version = [[[UIDevice currentDevice] systemVersion] floatValue];
    NSInteger errorCode   = JYAuthorizationStatusNone;
    NSString *description = nil;
    NSString *suggestion  = nil;
    NSURL *openSetting    = nil;
    BOOL granted          = false;
    
    switch (authType) {
#pragma mark - 定位
            
//        case JYServiceTypeLocationWhenInUse:// 定位-使用应用期间
//        {
//            description = JYAuthLocalizedStringForKey(@"location.description");
//            if ([CLLocationManager locationServicesEnabled]) {
//                switch ([CLLocationManager authorizationStatus]) {
//                    case kCLAuthorizationStatusNotDetermined:{
//                        // 未决定
//                        errorCode = JYAuthorizationStatusNotDetermined;
//                        suggestion = JYAuthLocalizedStringForKey(@"location.notdetermind");
//                        if (self.accessIfNotDetermined) {
//                            self.serviceType = authType;
//                            self.locationCompletion = completion;
//                            self.locationManager.delegate = self;
//                            [self.locationManager requestWhenInUseAuthorization];
//                            return;
//                        }
//                        break;
//                    }
//                    case kCLAuthorizationStatusRestricted:{
//                        errorCode = JYAuthorizationStatusNotDetermined;
//                        suggestion = JYAuthLocalizedStringForKey(@"location.restricted");
//                        break;
//                    }
//                    case kCLAuthorizationStatusDenied:{
//                        errorCode = JYAuthorizationStatusDenied;
//                        suggestion = JYAuthLocalizedStringForKey(@"location.wheninuse.denied");
//                        openSetting = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
//                        break;
//                    }
//                    case kCLAuthorizationStatusAuthorizedAlways:{
//                        errorCode = JYAuthorizationStatusDenied;
//                        suggestion = JYAuthLocalizedStringForKey(@"location.wheninuse.always");
//                        openSetting = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
//                        break;
//                    }
//                    case kCLAuthorizationStatusAuthorizedWhenInUse:{
//                        errorCode = JYAuthorizationStatusGranted;
//                        granted = true;
//                        break;
//                    }
//                    default:break;
//                }
//                _locationCompletion       = nil;
//                _locationManager.delegate = nil;
//                _locationManager          = nil;
//            } else {
//                errorCode = JYAuthorizationStatusUnServiced;
//                suggestion = JYAuthLocalizedStringForKey(@"location.unserviced");
//                openSetting = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
//            }
//            break;
//        }
//
//        case JYServiceTypeLocationAlways:// 定位-始终
//        {
//            description = JYAuthLocalizedStringForKey(@"location.description");
//            if ([CLLocationManager locationServicesEnabled]) {
//                switch ([CLLocationManager authorizationStatus]) {
//                    case kCLAuthorizationStatusNotDetermined:{
//                        errorCode = JYAuthorizationStatusNotDetermined;
//                        suggestion = JYAuthLocalizedStringForKey(@"location.notdetermind");
//                        if (self.accessIfNotDetermined) {
//                            self.locationCompletion = completion;
//                            self.locationManager.delegate = self;
//                            [self.locationManager requestAlwaysAuthorization];
//                            return;
//                        }
//                        break;
//                    }
//                    case kCLAuthorizationStatusRestricted:{
//                        errorCode = JYAuthorizationStatusNotDetermined;
//                        suggestion = JYAuthLocalizedStringForKey(@"location.restricted");
//                        break;
//                    }
//                    case kCLAuthorizationStatusDenied:{
//                        errorCode = JYAuthorizationStatusDenied;
//                        suggestion = JYAuthLocalizedStringForKey(@"location.always.denied");
//                        openSetting = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
//                        break;
//                    }
//                    case kCLAuthorizationStatusAuthorizedAlways:{
//                        errorCode = JYAuthorizationStatusGranted;
//                        granted = true;
//                        break;
//                    }
//                    case kCLAuthorizationStatusAuthorizedWhenInUse:{
//                        errorCode = JYAuthorizationStatusDenied;
//                        suggestion = JYAuthLocalizedStringForKey(@"location.always.wheninuse");
//                        openSetting = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
//                        break;
//                    }
//                    default:break;
//                }
//                _locationCompletion       = nil;
//                _locationManager.delegate = nil;
//                _locationManager          = nil;
//            } else {
//                errorCode = JYAuthorizationStatusUnServiced;
//                suggestion = JYAuthLocalizedStringForKey(@"location.unserviced");
//                openSetting = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
//            }
//            break;
//        }
            
#pragma mark - 通讯录
            
//        case JYServiceTypeAddressBook:
//        {
//            description = JYAuthLocalizedStringForKey(@"addressbook.description");
//            if (version >= 8.0 && version < 9.0)
//            {
//#pragma clang diagnostic push
//#pragma clang diagnostic ignored "-Wdeprecated-declarations"
//                switch (ABAddressBookGetAuthorizationStatus()) {
//                    case kABAuthorizationStatusNotDetermined:{
//                        errorCode = JYAuthorizationStatusNotDetermined;
//                        suggestion = JYAuthLocalizedStringForKey(@"addressbook.notdetermind");
//                        if (self.accessIfNotDetermined) {
//                            ABAddressBookRef addressBookRef =  ABAddressBookCreate();
//                            __weak typeof(self) weakSelf = self;
//                            ABAddressBookRequestAccessWithCompletion(addressBookRef, ^(bool granted, CFErrorRef error) {
//                                __strong typeof(weakSelf) strongSelf = weakSelf;
//                                [strongSelf requestAccessToService:authType completion:completion];
//                            });
//                            return;
//                        }
//                        break;
//                    }
//                    case kABAuthorizationStatusRestricted:{
//                        errorCode = JYAuthorizationStatusRestricted;
//                        suggestion = JYAuthLocalizedStringForKey(@"addressbook.restricted");
//                        break;
//                    }
//                    case kABAuthorizationStatusDenied:{
//                        errorCode = JYAuthorizationStatusDenied;
//                        suggestion = JYAuthLocalizedStringForKey(@"addressbook.denied");
//                        openSetting = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
//                        break;
//                    }
//                    case kABAuthorizationStatusAuthorized:{
//                        errorCode = JYAuthorizationStatusGranted;
//                        granted = true;
//                        break;
//                    }
//                    default:break;
//                }
//#pragma clang diagnostic pop
//            }
//            else
//            {
//                switch ([CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts]) {
//                    case CNAuthorizationStatusNotDetermined:{
//                        errorCode = JYAuthorizationStatusNotDetermined;
//                        suggestion = JYAuthLocalizedStringForKey(@"addressbook.notdetermind");
//                        if (self.accessIfNotDetermined) {
//                            CNContactStore *contactStore = [[CNContactStore alloc] init];
//                            __weak typeof(self) weakSelf = self;
//                            [contactStore requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError * _Nullable error) {
//                                __strong typeof(weakSelf) strongSelf = weakSelf;
//                                [strongSelf requestAccessToService:authType completion:completion];
//                            }];
//                            return;
//                        }
//                        break;
//                    }
//                    case CNAuthorizationStatusRestricted:{
//                        errorCode = JYAuthorizationStatusRestricted;
//                        suggestion = JYAuthLocalizedStringForKey(@"addressbook.restricted");
//                        break;
//                    }
//                    case CNAuthorizationStatusDenied:{
//                        errorCode = JYAuthorizationStatusDenied;
//                        suggestion = JYAuthLocalizedStringForKey(@"addressbook.denied");
//                        openSetting = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
//                        break;
//                    }
//                    case CNAuthorizationStatusAuthorized:{
//                        errorCode = JYAuthorizationStatusGranted;
//                        granted = true;
//                        break;
//                    }
//                    default:break;
//                }
//            }
//            break;
//        }
            
#pragma mark - 日历
            
//        case JYServiceTypeCalendar:
//        {
//            description = JYAuthLocalizedStringForKey(@"calendar.description");
//            switch ([EKEventStore authorizationStatusForEntityType:EKEntityTypeEvent]) {
//                case EKAuthorizationStatusNotDetermined:{
//                    errorCode = JYAuthorizationStatusNotDetermined;
//                    suggestion = JYAuthLocalizedStringForKey(@"calendar.notdetermind");
//                    if (self.accessIfNotDetermined) {
//                        EKEventStore *eventStore = [[EKEventStore alloc] init];
//                        __weak typeof(self) weakSelf = self;
//                        [eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError * _Nullable error) {
//                            __strong typeof(weakSelf) strongSelf = weakSelf;
//                            [strongSelf requestAccessToService:authType completion:completion];
//                        }];
//                        return;
//                    }
//                    break;
//                }
//                case EKAuthorizationStatusRestricted:{
//                    errorCode = JYAuthorizationStatusRestricted;
//                    suggestion = JYAuthLocalizedStringForKey(@"calendar.restricted");
//                    break;
//                }
//                case EKAuthorizationStatusDenied:{
//                    errorCode = JYAuthorizationStatusDenied;
//                    suggestion = JYAuthLocalizedStringForKey(@"calendar.denied");
//                    openSetting = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
//                    break;
//                }
//                case EKAuthorizationStatusAuthorized:{
//                    errorCode = JYAuthorizationStatusGranted;
//                    granted = true;
//                    break;
//                }
//                default:break;
//            }
//            break;
//        }
            
#pragma mark - 提醒事项
            
//        case JYServiceTypeReminder:
//        {
//            description = JYAuthLocalizedStringForKey(@"reminder.description");
//            switch ([EKEventStore authorizationStatusForEntityType:EKEntityTypeReminder]) {
//                case EKAuthorizationStatusNotDetermined:{
//                    errorCode = JYAuthorizationStatusNotDetermined;
//                    suggestion = JYAuthLocalizedStringForKey(@"reminder.notdetermind");
//                    if (self.accessIfNotDetermined) {
//                        EKEventStore *eventStore = [[EKEventStore alloc] init];
//                        __weak typeof(self) weakSelf = self;
//                        [eventStore requestAccessToEntityType:EKEntityTypeReminder completion:^(BOOL granted, NSError * _Nullable error) {
//                            __strong typeof(weakSelf) strongSelf = weakSelf;
//                            [strongSelf requestAccessToService:authType completion:completion];
//                        }];
//                        return;
//                    }
//                    break;
//                }
//                case EKAuthorizationStatusRestricted:{
//                    errorCode = JYAuthorizationStatusRestricted;
//                    suggestion = JYAuthLocalizedStringForKey(@"reminder.restricted");
//                    break;
//                }
//                case EKAuthorizationStatusDenied:{
//                    errorCode = JYAuthorizationStatusDenied;
//                    suggestion = JYAuthLocalizedStringForKey(@"reminder.denied");
//                    openSetting = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
//                    break;
//                }
//                case EKAuthorizationStatusAuthorized:{
//                    errorCode = JYAuthorizationStatusGranted;
//                    granted = true;
//                    break;
//                }
//                default:break;
//            }
//            break;
//        }
            
#pragma mark - 相册
            
//        case JYServiceTypePhoto:
//        {
//            description = JYAuthLocalizedStringForKey(@"photo.description");
//            switch ([PHPhotoLibrary authorizationStatus]) {
//                case PHAuthorizationStatusNotDetermined:{
//                    errorCode = JYAuthorizationStatusNotDetermined;
//                    suggestion = JYAuthLocalizedStringForKey(@"photo.notdetermind");
//                    if (self.accessIfNotDetermined) {
//                        __weak typeof(self) weakSelf = self;
//                        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
//                            __strong typeof(weakSelf) strongSelf = weakSelf;
//                            [strongSelf requestAccessToService:authType completion:completion];
//                        }];
//                        return;
//                    }
//                    break;
//                }
//                case PHAuthorizationStatusRestricted:{
//                    errorCode = JYAuthorizationStatusRestricted;
//                    suggestion = JYAuthLocalizedStringForKey(@"photo.restricted");
//                    break;
//                }
//                case PHAuthorizationStatusDenied:{
//                    errorCode = JYAuthorizationStatusDenied;
//                    suggestion = JYAuthLocalizedStringForKey(@"photo.denied");
//                    openSetting = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
//                    break;
//                }
//                case PHAuthorizationStatusAuthorized:{
//                    errorCode = JYAuthorizationStatusGranted;
//                    granted = true;
//                    break;
//                }
//                default:break;
//            }
//            break;
//        }
            
//#pragma mark - 蓝牙
//        case JYServiceTypeBlueTooth:// 蓝牙
//            break;
            
#pragma mark - 麦克风
            
//        case JYServiceTypeMicroPhone:
//        {
//            description = JYAuthLocalizedStringForKey(@"microphone.description");
//            switch ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio]) {
//                case AVAuthorizationStatusNotDetermined:{
//                    errorCode = JYAuthorizationStatusNotDetermined;
//                    suggestion = JYAuthLocalizedStringForKey(@"microphone.notdetermind");
//                    if (self.accessIfNotDetermined) {
//                        __weak typeof(self) weakSelf = self;
//                        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
//                            __strong typeof(weakSelf) strongSelf = weakSelf;
//                            [strongSelf requestAccessToService:authType completion:completion];
//                        }];
//                        return;
//                    }
//                    break;
//                }
//                case AVAuthorizationStatusRestricted:{
//                    errorCode = JYAuthorizationStatusRestricted;
//                    suggestion = JYAuthLocalizedStringForKey(@"microphone.restricted");
//                    break;
//                }
//                case AVAuthorizationStatusDenied:{
//                    errorCode = JYAuthorizationStatusDenied;
//                    suggestion = JYAuthLocalizedStringForKey(@"microphone.denied");
//                    openSetting = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
//                    break;
//                }
//                case AVAuthorizationStatusAuthorized:{
//                    errorCode = JYAuthorizationStatusGranted;
//                    granted = true;
//                    break;
//                }
//                default:break;
//            }
//            break;
//        }
            
//#pragma mark - 录音
//
//        case JYServiceTypeAudioRecord:
//        {
//            description = JYAuthLocalizedStringForKey(@"microphone.description");
//            switch ([[AVAudioSession sharedInstance] recordPermission]) {
//                case AVAudioSessionRecordPermissionUndetermined:{
//                    errorCode = JYAuthorizationStatusNotDetermined;
//                    suggestion = JYAuthLocalizedStringForKey(@"microphone.notdetermind");
//                    if (self.accessIfNotDetermined) {
//                        __weak typeof(self) weakSelf = self;
//                        [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted){
//                            __strong typeof(weakSelf) strongSelf = weakSelf;
//                            [strongSelf requestAccessToService:authType completion:completion];
//                        }];
//                        return;
//                    }
//                    break;
//                }
//                case AVAudioSessionRecordPermissionDenied:{
//                    errorCode = JYAuthorizationStatusDenied;
//                    suggestion = JYAuthLocalizedStringForKey(@"microphone.denied");
//                    openSetting = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
//                    break;
//                }
//                case AVAudioSessionRecordPermissionGranted:{
//                    errorCode = JYAuthorizationStatusGranted;
//                    granted = true;
//                    break;
//                }
//                default:break;
//            }
//            break;
//        }

#pragma mark - 相机
            
//        case JYServiceTypeCamera:
//        {
//            description = JYAuthLocalizedStringForKey(@"camera.description");
//            switch ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo]) {
//                case AVAuthorizationStatusNotDetermined:{
//                    errorCode = JYAuthorizationStatusNotDetermined;
//                    suggestion = JYAuthLocalizedStringForKey(@"camera.notdetermind");
//                    if (self.accessIfNotDetermined) {
//                        __weak typeof(self) weakSelf = self;
//                        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
//                            __strong typeof(weakSelf) strongSelf = weakSelf;
//                            [strongSelf requestAccessToService:authType completion:completion];
//                        }];
//                        return;
//                    }
//                    break;
//                }
//                case AVAuthorizationStatusRestricted:{
//                    errorCode = JYAuthorizationStatusRestricted;
//                    suggestion = JYAuthLocalizedStringForKey(@"camera.restricted");
//                    break;
//                }
//                case AVAuthorizationStatusDenied:{
//                    errorCode = JYAuthorizationStatusDenied;
//                    suggestion = JYAuthLocalizedStringForKey(@"camera.denied");
//                    openSetting = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
//                    break;
//                }
//                case AVAuthorizationStatusAuthorized:{
//                    errorCode = JYAuthorizationStatusGranted;
//                    granted = true;
//                    break;
//                }
//                default:break;
//            }
//            break;
//        }
            
#pragma mark - 语音识别
            
//        case JYServiceTypeSpeechRecognition:
//        {
//            description = JYAuthLocalizedStringForKey(@"speechrecognition.description");
//            if (@available(iOS 10.0, *)) {
//                switch ([SFSpeechRecognizer authorizationStatus]) {
//                    case SFSpeechRecognizerAuthorizationStatusNotDetermined:{
//                        errorCode = JYAuthorizationStatusNotDetermined;
//                        suggestion = JYAuthLocalizedStringForKey(@"speechrecognition.notdetermind");
//                        if (self.accessIfNotDetermined) {
//                            __weak typeof(self) weakSelf = self;
//                            [SFSpeechRecognizer requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus status) {
//                                __strong typeof(weakSelf) strongSelf = weakSelf;
//                                [strongSelf requestAccessToService:authType completion:completion];
//                            }];
//                            return;
//                        }
//                        break;
//                    }
//                    case SFSpeechRecognizerAuthorizationStatusRestricted:{
//                        errorCode = JYAuthorizationStatusRestricted;
//                        suggestion = JYAuthLocalizedStringForKey(@"speechrecognition.restricted");
//                        break;
//                    }
//                    case SFSpeechRecognizerAuthorizationStatusDenied:{
//                        errorCode = JYAuthorizationStatusDenied;
//                        suggestion = JYAuthLocalizedStringForKey(@"speechrecognition.denied");
//                        openSetting = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
//                        break;
//                    }
//                    case SFSpeechRecognizerAuthorizationStatusAuthorized:{
//                        errorCode = JYAuthorizationStatusGranted;
//                        granted = true;
//                        break;
//                    }
//                    default:break;
//                }
//            } else {
//                errorCode = JYAuthorizationStatusLowVersion;
//                suggestion = JYAuthLocalizedStringForKey(@"speechrecognition.lowversion");
//            }
//            break;
//        }
            
#pragma mark - 健康
            
//        case JYServiceTypeHealth:
//        {
//            description = JYAuthLocalizedStringForKey(@"health.description");
//            if ([HKHealthStore isHealthDataAvailable]) {
//                HKObjectType *stepObject = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
//                HKHealthStore *healthStore = [[HKHealthStore alloc] init];
//                switch ([healthStore authorizationStatusForType:stepObject]) {
//                    case HKAuthorizationStatusNotDetermined:{
//                        errorCode = JYAuthorizationStatusNotDetermined;
//                        suggestion = JYAuthLocalizedStringForKey(@"health.notdetermind");
//                        if (self.accessIfNotDetermined) {
//                            __weak typeof(self) weakSelf = self;
//                            [healthStore requestAuthorizationToShareTypes:[NSSet setWithObjects:stepObject, nil] readTypes:[NSSet setWithObjects:stepObject, nil] completion:^(BOOL success, NSError * _Nullable error) {
//                                __strong typeof(weakSelf) strongSelf = weakSelf;
//                                [strongSelf requestAccessToService:authType completion:completion];
//                            }];
//                            return;
//                        }
//                        break;
//                    }
//                    case HKAuthorizationStatusSharingDenied:{
//                        errorCode = JYAuthorizationStatusDenied;
//                        suggestion = JYAuthLocalizedStringForKey(@"health.denied");
//                        openSetting = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
//                        break;
//                    }
//                    case HKAuthorizationStatusSharingAuthorized:{
//                        errorCode = JYAuthorizationStatusGranted;
//                        granted = true;
//                        break;
//                    }
//                    default:break;
//                }
//            } else {
//                errorCode =JYAuthorizationStatusUnServiced;
//                suggestion = JYAuthLocalizedStringForKey(@"health.unserviced");
//                openSetting = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
//            }
//            break;
//        }
        
        default:break;
    }
    if (!description) {
        UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
        NSDictionary *dict = @{@(JYServiceTypeLocationWhenInUse) : @"定位(使用应用期间)",
                               @(JYServiceTypeLocationAlways)    : @"定位(始终)",
                               @(JYServiceTypeAddressBook)       : @"通讯录",
                               @(JYServiceTypeCalendar)          : @"日历",
                               @(JYServiceTypeReminder)          : @"提醒",
                               @(JYServiceTypePhoto)             : @"相册",
                               @(JYServiceTypeMicroPhone)        : @"麦克风",
                               @(JYServiceTypeCamera)            : @"相机",
                               @(JYServiceTypeSpeechRecognition) : @"语音识别",
                               @(JYServiceTypeHealth)            : @"健康",
                            };
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:[NSString stringWithFormat:@"为了使用该服务，请在 JYAuthorizationManager.m 文件将 %@ 的代码取消注释，并在 info.plist 文件上添加上该服务", dict[@(authType)]] preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:nil]];
        [keyWindow.rootViewController presentViewController:alertController animated:YES completion:nil];
        return;
    }
    NSError *error = nil;
    if (!granted) {
        NSDictionary *infoDict = @{
                                   NSLocalizedDescriptionKey : description ? description : @"",
                                   NSLocalizedRecoverySuggestionErrorKey : suggestion ? suggestion : @"",
                                   JYAuthOpenSettingKey : openSetting ? openSetting : [NSNull null]
                                   };
        error = [NSError errorWithDomain:JYAuthErrorDomain code:errorCode userInfo:infoDict];
    }
    if (errorCode != JYAuthorizationStatusNotDetermined && errorCode != JYAuthorizationStatusGranted) {
        self.authDict[@(authType)] = error;
    } else if (errorCode == JYAuthorizationStatusGranted) {
        self.authDict[@(authType)] = [NSNull null];
    }
    
    if (completion) {
        completion(granted, granted ? nil : error);
    }
}


+ (void)jy_showErrorDetail:(NSError *)error viewController:(UIViewController *)viewController
{
    if (!error || ![error isKindOfClass:[NSError class]]) {
        return;
    }
    JYAuthorizationManager *manager = [JYAuthorizationManager shareManager];
    if (manager.dontAlertIfNotDetermined && error.code == JYAuthorizationStatusNotDetermined) {
        return;
    }
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:error.localizedDescription
                                                                             message:error.localizedRecoverySuggestion
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:JYAuthLocalizedStringForKey(@"ok")
                                                        style:UIAlertActionStyleDefault handler:nil]];
    
    if (error.userInfo[JYAuthOpenSettingKey] != nil && ![error.userInfo[JYAuthOpenSettingKey] isKindOfClass:[NSNull class]]) {
        [alertController addAction:[UIAlertAction actionWithTitle:JYAuthLocalizedStringForKey(@"go")
                                                            style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            if (@available(iOS 10.0, *)) {
                [[UIApplication sharedApplication] openURL:error.userInfo[JYAuthOpenSettingKey]
                                                   options:@{}
                                         completionHandler:nil];
            }
        }]];
    }
    [viewController presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (self.locationCompletion && status != kCLAuthorizationStatusNotDetermined) {
        [self requestAccessToService:self.serviceType completion:self.locationCompletion];
    }
}

#pragma mark - Localized

static inline NSString * JYAuthLocalizedStringForKey(NSString *key) {
    if ([key isKindOfClass:[NSString class]]) {
        static NSBundle *bundle = nil;
        if (bundle == nil) {
            NSString *language = [NSLocale preferredLanguages].firstObject;
            if ([language rangeOfString:@"zh-Hans"].location != NSNotFound) {
                language = @"zh-Hans";
            } else {
                language = @"en";
            }
            NSURL *url = [[NSBundle mainBundle] URLForResource:@"JYAuthorization" withExtension:@"bundle"];
            bundle = [NSBundle bundleWithURL:url];
            bundle = [NSBundle bundleWithPath:[bundle pathForResource:language ofType:@"lproj"]];
        }
        NSString *value = [bundle localizedStringForKey:key value:key table:nil];
        
        return value;
    }
    return nil;
}

#pragma mark - locationManager

- (CLLocationManager *)locationManager
{
    if (!_locationManager) {
        _locationManager = [[CLLocationManager alloc] init];
    }
    return _locationManager;
}

@end
