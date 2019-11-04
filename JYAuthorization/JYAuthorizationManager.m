//
//  JYAuthorizationManager.m
//  pinlv
//
//  Created by dqh on 2019/3/7.
//  Copyright © 2019 dqh. All rights reserved.
//

#import "JYAuthorizationManager.h"
#import <CoreLocation/CoreLocation.h>
#import <AddressBook/AddressBook.h>
#import <Contacts/Contacts.h>
#import <EventKit/EventKit.h>
#import <Photos/Photos.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <Speech/Speech.h>
#import <HealthKit/HealthKit.h>


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
            
        case JYServiceTypeLocationWhenInUse:// 定位-使用应用期间
        {
            description = [self _localizedStringForKey:@"location.description"];
            if ([CLLocationManager locationServicesEnabled]) {
                switch ([CLLocationManager authorizationStatus]) {
                    case kCLAuthorizationStatusNotDetermined:{
                        // 未决定
                        errorCode = JYAuthorizationStatusNotDetermined;
                        suggestion = [self _localizedStringForKey:@"location.notdetermind"];
                        if (self.accessIfNotDetermined) {
                            self.serviceType = authType;
                            self.locationCompletion = completion;
                            self.locationManager.delegate = self;
                            [self.locationManager requestWhenInUseAuthorization];
                            return;
                        }
                        break;
                    }
                    case kCLAuthorizationStatusRestricted:{
                        errorCode = JYAuthorizationStatusNotDetermined;
                        suggestion = [self _localizedStringForKey:@"location.restricted"];
                        break;
                    }
                    case kCLAuthorizationStatusDenied:{
                        errorCode = JYAuthorizationStatusDenied;
                        suggestion = [self _localizedStringForKey:@"location.wheninuse.denied"];
                        openSetting = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                        break;
                    }
                    case kCLAuthorizationStatusAuthorizedAlways:{
                        errorCode = JYAuthorizationStatusDenied;
                        suggestion = [self _localizedStringForKey:@"location.wheninuse.always"];
                        openSetting = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                        break;
                    }
                    case kCLAuthorizationStatusAuthorizedWhenInUse:{
                        errorCode = JYAuthorizationStatusGranted;
                        granted = true;
                        break;
                    }
                    default:break;
                }
                _locationCompletion       = nil;
                _locationManager.delegate = nil;
                _locationManager          = nil;
            } else {
                errorCode = JYAuthorizationStatusUnServiced;
                suggestion = [self _localizedStringForKey:@"location.unserviced"];
                openSetting = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
            }
            break;
        }
            
        case JYServiceTypeLocationAlways:// 定位-始终
        {
            description = [self _localizedStringForKey:@"location.description"];
            if ([CLLocationManager locationServicesEnabled]) {
                switch ([CLLocationManager authorizationStatus]) {
                    case kCLAuthorizationStatusNotDetermined:{
                        errorCode = JYAuthorizationStatusNotDetermined;
                        suggestion = [self _localizedStringForKey:@"location.notdetermind"];
                        if (self.accessIfNotDetermined) {
                            self.locationCompletion = completion;
                            self.locationManager.delegate = self;
                            [self.locationManager requestAlwaysAuthorization];
                            return;
                        }
                        break;
                    }
                    case kCLAuthorizationStatusRestricted:{
                        errorCode = JYAuthorizationStatusNotDetermined;
                        suggestion = [self _localizedStringForKey:@"location.restricted"];
                        break;
                    }
                    case kCLAuthorizationStatusDenied:{
                        errorCode = JYAuthorizationStatusDenied;
                        suggestion = [self _localizedStringForKey:@"location.always.denied"];
                        openSetting = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                        break;
                    }
                    case kCLAuthorizationStatusAuthorizedAlways:{
                        errorCode = JYAuthorizationStatusGranted;
                        granted = true;
                        break;
                    }
                    case kCLAuthorizationStatusAuthorizedWhenInUse:{
                        errorCode = JYAuthorizationStatusDenied;
                        suggestion = [self _localizedStringForKey:@"location.always.wheninuse"];
                        openSetting = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                        break;
                    }
                    default:break;
                }
                _locationCompletion       = nil;
                _locationManager.delegate = nil;
                _locationManager          = nil;
            } else {
                errorCode = JYAuthorizationStatusUnServiced;
                suggestion = [self _localizedStringForKey:@"location.unserviced"];
                openSetting = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
            }
            break;
        }
            
#pragma mark - 通讯录
            
        case JYServiceTypeAddressBook:
        {
            description = [self _localizedStringForKey:@"addressbook.description"];
            if (version >= 8.0 && version < 9.0)
            {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
                switch (ABAddressBookGetAuthorizationStatus()) {
                    case kABAuthorizationStatusNotDetermined:{
                        errorCode = JYAuthorizationStatusNotDetermined;
                        suggestion = [self _localizedStringForKey:@"addressbook.notdetermind"];
                        if (self.accessIfNotDetermined) {
                            ABAddressBookRef addressBookRef =  ABAddressBookCreate();
                            __weak typeof(self) weakSelf = self;
                            ABAddressBookRequestAccessWithCompletion(addressBookRef, ^(bool granted, CFErrorRef error) {
                                __strong typeof(weakSelf) strongSelf = weakSelf;
                                [strongSelf requestAccessToService:authType completion:completion];
                            });
                            return;
                        }
                        break;
                    }
                    case kABAuthorizationStatusRestricted:{
                        errorCode = JYAuthorizationStatusRestricted;
                        suggestion = [self _localizedStringForKey:@"addressbook.restricted"];
                        break;
                    }
                    case kABAuthorizationStatusDenied:{
                        errorCode = JYAuthorizationStatusDenied;
                        suggestion = [self _localizedStringForKey:@"addressbook.denied"];
                        openSetting = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                        break;
                    }
                    case kABAuthorizationStatusAuthorized:{
                        errorCode = JYAuthorizationStatusGranted;
                        granted = true;
                        break;
                    }
                    default:break;
                }
#pragma clang diagnostic pop
            }
            else
            {
                switch ([CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts]) {
                    case CNAuthorizationStatusNotDetermined:{
                        errorCode = JYAuthorizationStatusNotDetermined;
                        suggestion = [self _localizedStringForKey:@"addressbook.notdetermind"];
                        if (self.accessIfNotDetermined) {
                            CNContactStore *contactStore = [[CNContactStore alloc] init];
                            __weak typeof(self) weakSelf = self;
                            [contactStore requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError * _Nullable error) {
                                __strong typeof(weakSelf) strongSelf = weakSelf;
                                [strongSelf requestAccessToService:authType completion:completion];
                            }];
                            return;
                        }
                        break;
                    }
                    case CNAuthorizationStatusRestricted:{
                        errorCode = JYAuthorizationStatusRestricted;
                        suggestion = [self _localizedStringForKey:@"addressbook.restricted"];
                        break;
                    }
                    case CNAuthorizationStatusDenied:{
                        errorCode = JYAuthorizationStatusDenied;
                        suggestion = [self _localizedStringForKey:@"addressbook.denied"];
                        openSetting = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                        break;
                    }
                    case CNAuthorizationStatusAuthorized:{
                        errorCode = JYAuthorizationStatusGranted;
                        granted = true;
                        break;
                    }
                    default:break;
                }                
            }
            break;
        }
            
#pragma mark - 日历
            
        case JYServiceTypeCalendar:
        {
            description = [self _localizedStringForKey:@"calendar.description"];
            switch ([EKEventStore authorizationStatusForEntityType:EKEntityTypeEvent]) {
                case EKAuthorizationStatusNotDetermined:{
                    errorCode = JYAuthorizationStatusNotDetermined;
                    suggestion = [self _localizedStringForKey:@"calendar.notdetermind"];
                    if (self.accessIfNotDetermined) {
                        EKEventStore *eventStore = [[EKEventStore alloc] init];
                        __weak typeof(self) weakSelf = self;
                        [eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError * _Nullable error) {
                            __strong typeof(weakSelf) strongSelf = weakSelf;
                            [strongSelf requestAccessToService:authType completion:completion];
                        }];
                        return;
                    }
                    break;
                }
                case EKAuthorizationStatusRestricted:{
                    errorCode = JYAuthorizationStatusRestricted;
                    suggestion = [self _localizedStringForKey:@"calendar.restricted"];
                    break;
                }
                case EKAuthorizationStatusDenied:{
                    errorCode = JYAuthorizationStatusDenied;
                    suggestion = [self _localizedStringForKey:@"calendar.denied"];
                    openSetting = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                    break;
                }
                case EKAuthorizationStatusAuthorized:{
                    errorCode = JYAuthorizationStatusGranted;
                    granted = true;
                    break;
                }
                default:break;
            }
            break;
        }
            
#pragma mark - 提醒事项
            
        case JYServiceTypeReminder:
        {
            description = [self _localizedStringForKey:@"reminder.description"];
            switch ([EKEventStore authorizationStatusForEntityType:EKEntityTypeReminder]) {
                case EKAuthorizationStatusNotDetermined:{
                    errorCode = JYAuthorizationStatusNotDetermined;
                    suggestion = [self _localizedStringForKey:@"reminder.notdetermind"];
                    if (self.accessIfNotDetermined) {
                        EKEventStore *eventStore = [[EKEventStore alloc] init];
                        __weak typeof(self) weakSelf = self;
                        [eventStore requestAccessToEntityType:EKEntityTypeReminder completion:^(BOOL granted, NSError * _Nullable error) {
                            __strong typeof(weakSelf) strongSelf = weakSelf;
                            [strongSelf requestAccessToService:authType completion:completion];
                        }];
                        return;
                    }
                    break;
                }
                case EKAuthorizationStatusRestricted:{
                    errorCode = JYAuthorizationStatusRestricted;
                    suggestion = [self _localizedStringForKey:@"reminder.restricted"];
                    break;
                }
                case EKAuthorizationStatusDenied:{
                    errorCode = JYAuthorizationStatusDenied;
                    suggestion = [self _localizedStringForKey:@"reminder.denied"];
                    openSetting = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                    break;
                }
                case EKAuthorizationStatusAuthorized:{
                    errorCode = JYAuthorizationStatusGranted;
                    granted = true;
                    break;
                }
                default:break;
            }
            break;
        }
            
#pragma mark - 相册
            
        case JYServiceTypePhoto:
        {
            description = [self _localizedStringForKey:@"photo.description"];
            switch ([PHPhotoLibrary authorizationStatus]) {
                case PHAuthorizationStatusNotDetermined:{
                    errorCode = JYAuthorizationStatusNotDetermined;
                    suggestion = [self _localizedStringForKey:@"photo.notdetermind"];
                    if (self.accessIfNotDetermined) {
                        __weak typeof(self) weakSelf = self;
                        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                            __strong typeof(weakSelf) strongSelf = weakSelf;
                            [strongSelf requestAccessToService:authType completion:completion];
                        }];
                        return;
                    }
                    break;
                }
                case PHAuthorizationStatusRestricted:{
                    errorCode = JYAuthorizationStatusRestricted;
                    suggestion = [self _localizedStringForKey:@"photo.restricted"];
                    break;
                }
                case PHAuthorizationStatusDenied:{
                    errorCode = JYAuthorizationStatusDenied;
                    suggestion = [self _localizedStringForKey:@"photo.denied"];
                    openSetting = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                    break;
                }
                case PHAuthorizationStatusAuthorized:{
                    errorCode = JYAuthorizationStatusGranted;
                    granted = true;
                    break;
                }
                default:break;
            }
            break;
        }
            
//#pragma mark - 蓝牙
//        case JYServiceTypeBlueTooth:// 蓝牙
//            break;
            
#pragma mark - 麦克风
            
        case JYServiceTypeMicroPhone:
        {
            description = [self _localizedStringForKey:@"microphone.description"];            
            switch ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio]) {
                case AVAuthorizationStatusNotDetermined:{
                    errorCode = JYAuthorizationStatusNotDetermined;
                    suggestion = [self _localizedStringForKey:@"microphone.notdetermind"];
                    if (self.accessIfNotDetermined) {
                        __weak typeof(self) weakSelf = self;
                        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
                            __strong typeof(weakSelf) strongSelf = weakSelf;
                            [strongSelf requestAccessToService:authType completion:completion];
                        }];
                        return;
                    }
                    break;
                }
                case AVAuthorizationStatusRestricted:{
                    errorCode = JYAuthorizationStatusRestricted;
                    suggestion = [self _localizedStringForKey:@"microphone.restricted"];
                    break;
                }
                case AVAuthorizationStatusDenied:{
                    errorCode = JYAuthorizationStatusDenied;
                    suggestion = [self _localizedStringForKey:@"microphone.denied"];
                    openSetting = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                    break;
                }
                case AVAuthorizationStatusAuthorized:{
                    errorCode = JYAuthorizationStatusGranted;
                    granted = true;
                    break;
                }
                default:break;
            }
            break;
        }
            
#pragma mark - 录音
            
        case JYServiceTypeAudioRecord:
        {
            description = [self _localizedStringForKey:@"microphone.description"];
            switch ([[AVAudioSession sharedInstance] recordPermission]) {
                case AVAudioSessionRecordPermissionUndetermined:{
                    errorCode = JYAuthorizationStatusNotDetermined;
                    suggestion = [self _localizedStringForKey:@"microphone.notdetermind"];
                    if (self.accessIfNotDetermined) {
                        __weak typeof(self) weakSelf = self;
                        [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted){
                            __strong typeof(weakSelf) strongSelf = weakSelf;
                            [strongSelf requestAccessToService:authType completion:completion];
                        }];
                        return;
                    }
                    break;
                }
                case AVAudioSessionRecordPermissionDenied:{
                    errorCode = JYAuthorizationStatusDenied;
                    suggestion = [self _localizedStringForKey:@"microphone.denied"];
                    openSetting = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                    break;
                }
                case AVAudioSessionRecordPermissionGranted:{
                    errorCode = JYAuthorizationStatusGranted;
                    granted = true;
                    break;
                }
                default:break;
            }
            break;
        }

#pragma mark - 相机
            
        case JYServiceTypeCamera:
        {
            description = [self _localizedStringForKey:@"camera.description"];
            switch ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo]) {
                case AVAuthorizationStatusNotDetermined:{
                    errorCode = JYAuthorizationStatusNotDetermined;
                    suggestion = [self _localizedStringForKey:@"camera.notdetermind"];
                    if (self.accessIfNotDetermined) {
                        __weak typeof(self) weakSelf = self;
                        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                            __strong typeof(weakSelf) strongSelf = weakSelf;
                            [strongSelf requestAccessToService:authType completion:completion];
                        }];
                        return;
                    }
                    break;
                }
                case AVAuthorizationStatusRestricted:{
                    errorCode = JYAuthorizationStatusRestricted;
                    suggestion = [self _localizedStringForKey:@"camera.restricted"];
                    break;
                }
                case AVAuthorizationStatusDenied:{
                    errorCode = JYAuthorizationStatusDenied;
                    suggestion = [self _localizedStringForKey:@"camera.denied"];
                    openSetting = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                    break;
                }
                case AVAuthorizationStatusAuthorized:{
                    errorCode = JYAuthorizationStatusGranted;
                    granted = true;
                    break;
                }
                default:break;
            }
            break;
        }
            
#pragma mark - 语音识别
            
        case JYServiceTypeSpeechRecognition:
        {
            description = [self _localizedStringForKey:@"speechrecognition.description"];
            if (@available(iOS 10.0, *)) {
                switch ([SFSpeechRecognizer authorizationStatus]) {
                    case SFSpeechRecognizerAuthorizationStatusNotDetermined:{
                        errorCode = JYAuthorizationStatusNotDetermined;
                        suggestion = [self _localizedStringForKey:@"speechrecognition.notdetermind"];
                        if (self.accessIfNotDetermined) {
                            __weak typeof(self) weakSelf = self;
                            [SFSpeechRecognizer requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus status) {
                                __strong typeof(weakSelf) strongSelf = weakSelf;
                                [strongSelf requestAccessToService:authType completion:completion];
                            }];
                            return;
                        }
                        break;
                    }
                    case SFSpeechRecognizerAuthorizationStatusRestricted:{
                        errorCode = JYAuthorizationStatusRestricted;
                        suggestion = [self _localizedStringForKey:@"speechrecognition.restricted"];
                        break;
                    }
                    case SFSpeechRecognizerAuthorizationStatusDenied:{
                        errorCode = JYAuthorizationStatusDenied;
                        suggestion = [self _localizedStringForKey:@"speechrecognition.denied"];
                        openSetting = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                        break;
                    }
                    case SFSpeechRecognizerAuthorizationStatusAuthorized:{
                        errorCode = JYAuthorizationStatusGranted;
                        granted = true;
                        break;
                    }
                    default:break;
                }
            } else {
                errorCode = JYAuthorizationStatusLowVersion;
                suggestion = [self _localizedStringForKey:@"speechrecognition.lowversion"];
            }
            break;
        }
            
#pragma mark - 健康
            
        case JYServiceTypeHealth:
        {
            description = [self _localizedStringForKey:@"health.description"];
            if ([HKHealthStore isHealthDataAvailable]) {
                HKObjectType *stepObject = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
                HKHealthStore *healthStore = [[HKHealthStore alloc] init];
                switch ([healthStore authorizationStatusForType:stepObject]) {
                    case HKAuthorizationStatusNotDetermined:{
                        errorCode = JYAuthorizationStatusNotDetermined;
                        suggestion = [self _localizedStringForKey:@"health.notdetermind"];
                        if (self.accessIfNotDetermined) {
                            __weak typeof(self) weakSelf = self;
                            [healthStore requestAuthorizationToShareTypes:[NSSet setWithObjects:stepObject, nil] readTypes:[NSSet setWithObjects:stepObject, nil] completion:^(BOOL success, NSError * _Nullable error) {
                                __strong typeof(weakSelf) strongSelf = weakSelf;
                                [strongSelf requestAccessToService:authType completion:completion];
                            }];
                            return;
                        }
                        break;
                    }
                    case HKAuthorizationStatusSharingDenied:{
                        errorCode = JYAuthorizationStatusDenied;
                        suggestion = [self _localizedStringForKey:@"health.denied"];
                        openSetting = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                        break;
                    }
                    case HKAuthorizationStatusSharingAuthorized:{
                        errorCode = JYAuthorizationStatusGranted;
                        granted = true;
                        break;
                    }
                    default:break;
                }
            } else {
                errorCode =JYAuthorizationStatusUnServiced;
                suggestion = [self _localizedStringForKey:@"health.unserviced"];
                openSetting = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
            }
            break;
        }
        
        default:break;
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


- (void)jy_showErrorDetail:(NSError *)error viewController:(UIViewController *)viewController
{
    if (!error || ![error isKindOfClass:[NSError class]]) {
        return;
    }
    if (self.dontAlertIfNotDetermined && error.code == JYAuthorizationStatusNotDetermined) {
        return;
    }
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:error.localizedDescription
                                                                             message:error.localizedRecoverySuggestion
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:[self _localizedStringForKey:@"ok"]
                                                        style:UIAlertActionStyleDefault handler:nil]];
    
    if (error.userInfo[JYAuthOpenSettingKey] != nil && ![error.userInfo[JYAuthOpenSettingKey] isKindOfClass:[NSNull class]]) {
        [alertController addAction:[UIAlertAction actionWithTitle:[self _localizedStringForKey:@"go"]
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

- (NSString *)_localizedStringForKey:(NSString *)key
{
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
