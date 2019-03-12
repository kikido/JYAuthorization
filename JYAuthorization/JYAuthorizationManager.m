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
//#import <CoreBluetooth/CoreBluetooth.h>
#import <Speech/Speech.h>
#import <HealthKit/HealthKit.h>


NSString *const JYAuthErrorDomain = @"JYAuthErrorDomain";
NSString *const JYAuthOpenSettingKey = @"JYAuthOpenSettingKey";


@interface JYAuthorizationManager () <CLLocationManagerDelegate>
///|< 检查定位权限时必须长持有·CLLocationManager·对象
@property (nonatomic, strong) CLLocationManager *locationManager;
///|< 在service为·location·且状态为notdertermind时才会用到。在后面会置为nil避免循环引用
@property (nonatomic, copy) void(^locationCompletion)(BOOL granted, NSError *error);
@property (nonatomic, assign) JYServiceType serviceType;
///|< 存储验证状态结果的字典，key为JYServiceType，value为`NSError`。当第一次进入检查且结果errorType为·JYAuthorizationErrorNotDetermined·时不会保存到字典。iOS的隐私功能权限，如果在设置过之后，应用就会被强制退出。所以，不是·JYAuthorizationErrorNotDetermined·的状态结果都可以保存起来，不必每一次都去查询
@property (nonatomic, strong) NSMutableDictionary *authDict;
@end

@implementation JYAuthorizationManager

+ (instancetype)shareManager
{
    static JYAuthorizationManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (manager == nil) {
            manager = [[super allocWithZone:NULL] init];
            manager.accessIfNotDetermined = true;
            manager.dontAlertIfNotDetermined = true;
            manager.authDict = @{}.mutableCopy;
        }
    });
    return manager;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
    return [self shareManager];
}

#pragma mark - Public

- (void)requestAccessToServiceType:(JYServiceType)authType completion:(void(^)(BOOL granted, NSError *error))completion;
{
    NSError *authError = self.authDict[@(authType)];
    // 如果这个值不为空，那就代表已经检查过权限了，结果不通过
    if ([authError isKindOfClass:[NSError class]]) {
        completion(false, authError);
        return;
    }
    // 如果这个值是NSNull对象，那就代表已经检查过权限，且结果通过
    if ([authError isKindOfClass:[NSNull class]]) {
        completion(true, nil);
        return;
    }
    
    NSInteger errorCode = JYAuthorizationErrorNone;
    NSString *description = nil;
    NSString *suggestion = nil;
    NSURL *openSetting = nil;
    CGFloat version = [[[UIDevice currentDevice] systemVersion] floatValue];
    
    BOOL granted = false;
    
    switch (authType) {
#pragma mark - 定位
        case JYServiceTypeLocationWhenInUse:// 定位-使用应用期间
        {
            description = [self _localizedStringForKey:@"location.description"];
            if ([CLLocationManager locationServicesEnabled]) {
                switch ([CLLocationManager authorizationStatus]) {
                    case kCLAuthorizationStatusNotDetermined:// 尚未决定
                    {
                        errorCode = JYAuthorizationErrorNotDetermined;
                        suggestion = [self _localizedStringForKey:@"location.notdetermind"];
                        if (self.accessIfNotDetermined) {
                            self.serviceType = authType;
                            self.locationCompletion = completion;
                            self.locationManager.delegate = self;
                            [self.locationManager requestWhenInUseAuthorization];
                            return;
                        }
                    }break;
                        
                    case kCLAuthorizationStatusRestricted:
                        errorCode = JYAuthorizationErrorRestricted;
                        suggestion = [self _localizedStringForKey:@"location.restricted"];break;
                        
                    case kCLAuthorizationStatusDenied:
                        errorCode = JYAuthorizationErrorDenied;
                        suggestion = [self _localizedStringForKey:@"location.wheninuse.denied"];
                        openSetting = [NSURL URLWithString:UIApplicationOpenSettingsURLString];break;
                        
                    case kCLAuthorizationStatusAuthorizedAlways:
                        errorCode = JYAuthorizationErrorDenied;
                        suggestion = [self _localizedStringForKey:@"location.wheninuse.always"];
                        openSetting = [NSURL URLWithString:UIApplicationOpenSettingsURLString];break;
                        
                    case kCLAuthorizationStatusAuthorizedWhenInUse:
                        errorCode = JYAuthorizationErrorGranted;
                        granted = true;break;
                        
                    default:break;
                }
                _locationCompletion = nil;
                _locationManager.delegate = nil;
                _locationManager = nil;
            } else {
                errorCode =JYAuthorizationErrorUnServiced;
                suggestion = [self _localizedStringForKey:@"location.unserviced"];
                openSetting = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
            }
        }break;
            
        case JYServiceTypeLocationAlways:// 定位-始终使用
        {
            description = [self _localizedStringForKey:@"location.description"];
            if ([CLLocationManager locationServicesEnabled]) {
                switch ([CLLocationManager authorizationStatus]) {
                    case kCLAuthorizationStatusNotDetermined:
                    {
                        errorCode = JYAuthorizationErrorNotDetermined;
                        suggestion = [self _localizedStringForKey:@"location.notdetermind"];
                        if (self.accessIfNotDetermined) {
                            self.locationCompletion = completion;
                            self.locationManager.delegate = self;
                            [self.locationManager requestAlwaysAuthorization];
                            return;
                        }
                    }break;
                        
                    case kCLAuthorizationStatusRestricted:
                        errorCode = JYAuthorizationErrorRestricted;
                        suggestion = [self _localizedStringForKey:@"location.restricted"];break;
                        
                    case kCLAuthorizationStatusDenied:
                        errorCode = JYAuthorizationErrorDenied;
                        suggestion = [self _localizedStringForKey:@"location.always.denied"];
                        openSetting = [NSURL URLWithString:UIApplicationOpenSettingsURLString];break;
                        
                    case kCLAuthorizationStatusAuthorizedAlways:
                        errorCode = JYAuthorizationErrorGranted;
                        granted = true;break;
                        
                    case kCLAuthorizationStatusAuthorizedWhenInUse:
                        errorCode = JYAuthorizationErrorDenied;
                        suggestion = [self _localizedStringForKey:@"location.always.wheninuse"];
                        openSetting = [NSURL URLWithString:UIApplicationOpenSettingsURLString];break;
                        
                    default:break;
                }
                _locationCompletion = nil;
                _locationManager.delegate = nil;
                _locationManager = nil;
            } else {
                errorCode =JYAuthorizationErrorUnServiced;
                suggestion = [self _localizedStringForKey:@"location.unserviced"];
                openSetting = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
            }
        }break;
            
#pragma mark - 通讯录
        case JYServiceTypeAddressBook:// 通讯录
        {
            description = [self _localizedStringForKey:@"addressbook.description"];
            if (version >= 8.0 && version < 9.0) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
                ABAuthorizationStatus authorizationStatus = ABAddressBookGetAuthorizationStatus();
                switch (authorizationStatus) {
                    case kABAuthorizationStatusNotDetermined:
                    {
                        errorCode = JYAuthorizationErrorNotDetermined;
                        suggestion = [self _localizedStringForKey:@"addressbook.notdetermind"];
                        if (self.accessIfNotDetermined) {
                            ABAddressBookRef addressBookRef =  ABAddressBookCreate();
                            __weak typeof(self) weakSelf = self;
                            ABAddressBookRequestAccessWithCompletion(addressBookRef, ^(bool granted, CFErrorRef error) {
                                __strong typeof(weakSelf) strongSelf = weakSelf;
                                [strongSelf requestAccessToServiceType:authType completion:completion];
                            });
                            return;
                        }
                    }break;
                        
                    case kABAuthorizationStatusRestricted:
                        errorCode = JYAuthorizationErrorRestricted;
                        suggestion = [self _localizedStringForKey:@"addressbook.restricted"];break;
                        
                    case kABAuthorizationStatusDenied:
                        errorCode = JYAuthorizationErrorDenied;
                        suggestion = [self _localizedStringForKey:@"addressbook.denied"];
                        openSetting = [NSURL URLWithString:UIApplicationOpenSettingsURLString];break;
                        
                    case kABAuthorizationStatusAuthorized:
                        errorCode = JYAuthorizationErrorGranted;
                        granted = true;break;
                        
                    default:break;
                }
#pragma clang diagnostic pop
            } else {
                switch ([CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts]) {
                    case CNAuthorizationStatusNotDetermined:
                        errorCode = JYAuthorizationErrorNotDetermined;
                        suggestion = [self _localizedStringForKey:@"addressbook.notdetermind"];
                        if (self.accessIfNotDetermined) {
                            CNContactStore *contactStore = [[CNContactStore alloc] init];
                            __weak typeof(self) weakSelf = self;
                            [contactStore requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError * _Nullable error) {
                                __strong typeof(weakSelf) strongSelf = weakSelf;
                                [strongSelf requestAccessToServiceType:authType completion:completion];
                            }];
                            return;
                        }break;
                        
                    case CNAuthorizationStatusRestricted:
                        errorCode = JYAuthorizationErrorRestricted;
                        suggestion = [self _localizedStringForKey:@"addressbook.restricted"];break;
                        
                    case CNAuthorizationStatusDenied:
                        errorCode = JYAuthorizationErrorDenied;
                        suggestion = [self _localizedStringForKey:@"addressbook.denied"];break;
                        
                    case CNAuthorizationStatusAuthorized:
                        errorCode = JYAuthorizationErrorGranted;
                        granted = true;break;
                        
                    default:break;
                }                
            }
        }break;
            
#pragma mark - 日历
        case JYServiceTypeCalendar:// 日历
            description = [self _localizedStringForKey:@"calendar.description"];
            switch ([EKEventStore authorizationStatusForEntityType:EKEntityTypeEvent]) {
                case EKAuthorizationStatusNotDetermined:
                    errorCode = JYAuthorizationErrorNotDetermined;
                    suggestion = [self _localizedStringForKey:@"addressbook.notdetermind"];
                    if (self.accessIfNotDetermined) {
                        EKEventStore *eventStore = [[EKEventStore alloc] init];
                        __weak typeof(self) weakSelf = self;
                        [eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError * _Nullable error) {
                            __strong typeof(weakSelf) strongSelf = weakSelf;
                            [strongSelf requestAccessToServiceType:authType completion:completion];
                        }];
                        return;
                    }break;
                    
                case EKAuthorizationStatusRestricted:
                    errorCode = JYAuthorizationErrorRestricted;
                    suggestion = [self _localizedStringForKey:@"addressbook.restricted"];break;
                    
                case EKAuthorizationStatusDenied:
                    errorCode = JYAuthorizationErrorDenied;
                    suggestion = [self _localizedStringForKey:@"addressbook.denied"];
                    openSetting = [NSURL URLWithString:UIApplicationOpenSettingsURLString];break;
                    
                case EKAuthorizationStatusAuthorized:
                    errorCode = JYAuthorizationErrorGranted;
                    granted = true;break;
                    
                default:break;
            }break;
            
#pragma mark - 提醒事项
        case JYServiceTypeReminder:// 提醒
            description = [self _localizedStringForKey:@"reminder.description"];
            switch ([EKEventStore authorizationStatusForEntityType:EKEntityTypeReminder]) {
                case EKAuthorizationStatusNotDetermined:
                    errorCode = JYAuthorizationErrorNotDetermined;
                    suggestion = [self _localizedStringForKey:@"reminder.notdetermind"];
                    if (self.accessIfNotDetermined) {
                        EKEventStore *eventStore = [[EKEventStore alloc] init];
                        __weak typeof(self) weakSelf = self;
                        [eventStore requestAccessToEntityType:EKEntityTypeReminder completion:^(BOOL granted, NSError * _Nullable error) {
                            __strong typeof(weakSelf) strongSelf = weakSelf;
                            [strongSelf requestAccessToServiceType:authType completion:completion];
                        }];
                        return;
                    }break;
                    
                case EKAuthorizationStatusRestricted:
                    errorCode = JYAuthorizationErrorRestricted;
                    suggestion = [self _localizedStringForKey:@"reminder.restricted"];break;
                    
                case EKAuthorizationStatusDenied:
                    errorCode = JYAuthorizationErrorDenied;
                    suggestion = [self _localizedStringForKey:@"reminder.denied"];
                    openSetting = [NSURL URLWithString:UIApplicationOpenSettingsURLString];break;
                    
                case EKAuthorizationStatusAuthorized:
                    errorCode = JYAuthorizationErrorGranted;
                    granted = true;break;
                    
                default:break;
            }break;
            
#pragma mark - 相册
        case JYServiceTypePhoto:// 相册
            description = [self _localizedStringForKey:@"photo.description"];
            switch ([PHPhotoLibrary authorizationStatus]) {
                case PHAuthorizationStatusNotDetermined:
                    errorCode = JYAuthorizationErrorNotDetermined;
                    suggestion = [self _localizedStringForKey:@"photo.notdetermind"];
                    if (self.accessIfNotDetermined) {
                        __weak typeof(self) weakSelf = self;
                        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                            __strong typeof(weakSelf) strongSelf = weakSelf;
                            [strongSelf requestAccessToServiceType:authType completion:completion];
                        }];
                        return;
                    }break;
                    
                case PHAuthorizationStatusRestricted:
                    errorCode = JYAuthorizationErrorRestricted;
                    suggestion = [self _localizedStringForKey:@"photo.restricted"];break;
                    
                case PHAuthorizationStatusDenied:
                    errorCode = JYAuthorizationErrorDenied;
                    suggestion = [self _localizedStringForKey:@"photo.denied"];
                    openSetting = [NSURL URLWithString:UIApplicationOpenSettingsURLString];break;
                    
                case PHAuthorizationStatusAuthorized:
                    errorCode = JYAuthorizationErrorGranted;
                    granted = true;break;
                    
                default:break;
            } break;
            
//#pragma mark - 蓝牙
//        case JYServiceTypeBlueTooth:// 蓝牙
//            break;
            
#pragma mark - 麦克风
        case JYServiceTypeMicroPhone:// 麦克风
        {
            description = [self _localizedStringForKey:@"microphone.description"];
            switch ([[AVAudioSession sharedInstance] recordPermission]) {
                case AVAudioSessionRecordPermissionUndetermined:
                    errorCode = JYAuthorizationErrorNotDetermined;
                    suggestion = [self _localizedStringForKey:@"microphone.notdetermind"];
                    if (self.accessIfNotDetermined) {
                        __weak typeof(self) weakSelf = self;
                        [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted){
                            __strong typeof(weakSelf) strongSelf = weakSelf;
                            [strongSelf requestAccessToServiceType:authType completion:completion];
                        }];
//                        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
//                            __strong typeof(weakSelf) strongSelf = weakSelf;
////                            [strongSelf requestAccessToServiceType:authType completion:completion];
//                        }];
                        NSLog(@"hh");
                        return;
                    }break;
                    
                    
                case AVAudioSessionRecordPermissionDenied:
                    errorCode = JYAuthorizationErrorDenied;
                    suggestion = [self _localizedStringForKey:@"microphone.denied"];
                    openSetting = [NSURL URLWithString:UIApplicationOpenSettingsURLString];break;
                    
                case AVAudioSessionRecordPermissionGranted:
                    errorCode = JYAuthorizationErrorGranted;
                    granted = true;break;
                    
                default:break;
            }
        }break;
            
#pragma mark - 相机
        case JYServiceTypeCamera:// 相机
        {
            description = [self _localizedStringForKey:@"camera.description"];
            switch ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo]) {
                case AVAuthorizationStatusNotDetermined:
                    errorCode = JYAuthorizationErrorNotDetermined;suggestion = [self _localizedStringForKey:@"camera.notdetermind"];
                    if (self.accessIfNotDetermined) {
                        __weak typeof(self) weakSelf = self;
                        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                            __strong typeof(weakSelf) strongSelf = weakSelf;
                            [strongSelf requestAccessToServiceType:authType completion:completion];
                        }];
                        return;
                    }break;
                    
                case PHAuthorizationStatusRestricted:
                    errorCode = JYAuthorizationErrorRestricted;
                    suggestion = [self _localizedStringForKey:@"camera.restricted"];break;
                    
                case PHAuthorizationStatusDenied:
                    errorCode = JYAuthorizationErrorDenied;
                    suggestion = [self _localizedStringForKey:@"camera.denied"];
                    openSetting = [NSURL URLWithString:UIApplicationOpenSettingsURLString];break;
                    
                case PHAuthorizationStatusAuthorized:
                    errorCode = JYAuthorizationErrorGranted;
                    granted = true;break;
                    
                default:break;
            }
        }break;
            
#pragma mark - 语音识别
        case JYServiceTypeSpeechRecognition:// 语音识别
            description = [self _localizedStringForKey:@"speechrecognition.description"];
            if (version >= 10.0) {
                switch ([SFSpeechRecognizer authorizationStatus]) {
                    case SFSpeechRecognizerAuthorizationStatusNotDetermined:
                        errorCode = JYAuthorizationErrorNotDetermined;suggestion = [self _localizedStringForKey:@"speechrecognition.notdetermind"];
                        if (self.accessIfNotDetermined) {
                            __weak typeof(self) weakSelf = self;
                            [SFSpeechRecognizer requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus status) {
                                __strong typeof(weakSelf) strongSelf = weakSelf;
                                [strongSelf requestAccessToServiceType:authType completion:completion];
                            }];
                            return;
                        }break;
                        
                    case SFSpeechRecognizerAuthorizationStatusRestricted:
                        errorCode = JYAuthorizationErrorRestricted;
                        suggestion = [self _localizedStringForKey:@"speechrecognition.restricted"];break;
                        
                    case SFSpeechRecognizerAuthorizationStatusDenied:
                        errorCode = JYAuthorizationErrorDenied;
                        suggestion = [self _localizedStringForKey:@"speechrecognition.denied"];
                        openSetting = [NSURL URLWithString:UIApplicationOpenSettingsURLString];break;
                        
                    case SFSpeechRecognizerAuthorizationStatusAuthorized:
                        errorCode = JYAuthorizationErrorGranted;
                        granted = true;break;
                        
                    default:break;
                }
            } else {
                errorCode = JYAuthorizationErrorLowVersion;
                suggestion = [self _localizedStringForKey:@"speechrecognition.lowversion"];
            }break;
            
#pragma mark - 健康
        case JYServiceTypeHealth:// 健康
        {
            description = [self _localizedStringForKey:@"health.description"];
            if ([HKHealthStore isHealthDataAvailable]) {
                HKObjectType *stepObject = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
                HKHealthStore *healthStore = [[HKHealthStore alloc] init];
                switch ([healthStore authorizationStatusForType:stepObject]) {
                    case HKAuthorizationStatusNotDetermined:// 尚未决定
                    {
                        errorCode = JYAuthorizationErrorNotDetermined;
                        suggestion = [self _localizedStringForKey:@"health.notdetermind"];
                        if (self.accessIfNotDetermined) {
                            __weak typeof(self) weakSelf = self;
                            [healthStore requestAuthorizationToShareTypes:[NSSet setWithObjects:stepObject, nil] readTypes:[NSSet setWithObjects:stepObject, nil] completion:^(BOOL success, NSError * _Nullable error) {
                                __strong typeof(weakSelf) strongSelf = weakSelf;
                                [strongSelf requestAccessToServiceType:authType completion:completion];
                            }];
                            return;
                        }
                    }break;
                        
                    case HKAuthorizationStatusSharingDenied:
                        errorCode = JYAuthorizationErrorDenied;
                        suggestion = [self _localizedStringForKey:@"health.denied"];
                        openSetting = [NSURL URLWithString:UIApplicationOpenSettingsURLString];break;
                        
                    case HKAuthorizationStatusSharingAuthorized:
                        errorCode = JYAuthorizationErrorGranted;
                        granted = true;break;
                        
                    default:break;
                }
            } else {
                errorCode =JYAuthorizationErrorUnServiced;
                suggestion = [self _localizedStringForKey:@"health.unserviced"];
                openSetting = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
            }
        }break;
            
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
    if (errorCode != JYAuthorizationErrorNotDetermined && errorCode != JYAuthorizationErrorGranted) {
        self.authDict[@(authType)] = error;
    } else if (errorCode == JYAuthorizationErrorGranted) {
        self.authDict[@(authType)] = [NSNull null];
    }
    
    if (completion) {
        completion(granted, granted ? nil : error);
    }
}


- (void)jy_showErrorDetail:(NSError *)error viewController:(UIViewController *)viewController
{
    if (![viewController isKindOfClass:[UIViewController class]]) {
        return;
    }
    if (![error isKindOfClass:[NSError class]] || !error) {
        return;
    }
    if (self.dontAlertIfNotDetermined && error.code == JYAuthorizationErrorNotDetermined) {
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
            [[UIApplication sharedApplication] openURL:error.userInfo[JYAuthOpenSettingKey] options:@{} completionHandler:^(BOOL  success) {
                if (success) {
                    NSLog(@"跳转成功");
                }
            }];
        }]];
    }
    [viewController presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (self.locationCompletion && status != kCLAuthorizationStatusNotDetermined) {
        [self requestAccessToServiceType:self.serviceType completion:self.locationCompletion];
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


#pragma mark - Lazy loading

- (CLLocationManager *)locationManager
{
    if (!_locationManager) {
        _locationManager = [[CLLocationManager alloc] init];
    }
    return _locationManager;
}


@end
