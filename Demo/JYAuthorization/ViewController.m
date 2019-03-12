//
//  ViewController.m
//  JYAuthorization
//
//  Created by dqh on 2019/3/11.
//  Copyright © 2019 dqh. All rights reserved.
//

#import "ViewController.h"
#import "JYForm.h"
#import "JYAuthorizationManager.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    JYFormDescriptor *formDescriptor = [JYFormDescriptor formDescriptor];
    JYFormSectionDescriptor *section = nil;
    JYFormRowDescriptor *row = nil;
    
    section = [JYFormSectionDescriptor formSection];
    [formDescriptor addFormSection:section];
    
    row = [JYFormRowDescriptor formRowDescriptorWithTag:@"00" rowType:JYFormRowDescriptorTypeButton title:@"定位-使用期间"];
    row.action.rowBlock = ^(JYFormRowDescriptor * _Nonnull sender) {
        [self accessService:JYServiceTypeLocationWhenInUse];
    };
    [section addFormRow:row];
    
    row = [JYFormRowDescriptor formRowDescriptorWithTag:@"01" rowType:JYFormRowDescriptorTypeButton title:@"定位-持续"];
    row.action.rowBlock = ^(JYFormRowDescriptor * _Nonnull sender) {
        [self accessService:JYServiceTypeLocationAlways];
    };
    [section addFormRow:row];
    
    row = [JYFormRowDescriptor formRowDescriptorWithTag:@"02" rowType:JYFormRowDescriptorTypeButton title:@"通讯录"];
    row.action.rowBlock = ^(JYFormRowDescriptor * _Nonnull sender) {
        [self accessService:JYServiceTypeAddressBook];
    };
    [section addFormRow:row];
    
    row = [JYFormRowDescriptor formRowDescriptorWithTag:@"03" rowType:JYFormRowDescriptorTypeButton title:@"日历"];
    row.action.rowBlock = ^(JYFormRowDescriptor * _Nonnull sender) {
        [self accessService:JYServiceTypeCalendar];
    };
    [section addFormRow:row];
    
    row = [JYFormRowDescriptor formRowDescriptorWithTag:@"04" rowType:JYFormRowDescriptorTypeButton title:@"提醒"];
    row.action.rowBlock = ^(JYFormRowDescriptor * _Nonnull sender) {
        [self accessService:JYServiceTypeReminder];
    };
    [section addFormRow:row];
    
    row = [JYFormRowDescriptor formRowDescriptorWithTag:@"05" rowType:JYFormRowDescriptorTypeButton title:@"相册"];
    row.action.rowBlock = ^(JYFormRowDescriptor * _Nonnull sender) {
        [self accessService:JYServiceTypePhoto];
    };
    [section addFormRow:row];
    
//    row = [JYFormRowDescriptor formRowDescriptorWithTag:@"06" rowType:JYFormRowDescriptorTypeButton title:@"蓝牙"];
//    row.action.rowBlock = ^(JYFormRowDescriptor * _Nonnull sender) {
//        [self accessService:JYServiceTypeLocationWhenInUse];
//    };
//    [section addFormRow:row];
    
    row = [JYFormRowDescriptor formRowDescriptorWithTag:@"07" rowType:JYFormRowDescriptorTypeButton title:@"麦克风"];
    row.action.rowBlock = ^(JYFormRowDescriptor * _Nonnull sender) {
        [self accessService:JYServiceTypeMicroPhone];
    };
    [section addFormRow:row];
    
    row = [JYFormRowDescriptor formRowDescriptorWithTag:@"08" rowType:JYFormRowDescriptorTypeButton title:@"相机"];
    row.action.rowBlock = ^(JYFormRowDescriptor * _Nonnull sender) {
        [self accessService:JYServiceTypeCamera];
    };
    [section addFormRow:row];
    
    row = [JYFormRowDescriptor formRowDescriptorWithTag:@"09" rowType:JYFormRowDescriptorTypeButton title:@"语音识别"];
    row.action.rowBlock = ^(JYFormRowDescriptor * _Nonnull sender) {
        [self accessService:JYServiceTypeSpeechRecognition];
    };
    [section addFormRow:row];
    
    row = [JYFormRowDescriptor formRowDescriptorWithTag:@"010" rowType:JYFormRowDescriptorTypeButton title:@"健康"];
    row.action.rowBlock = ^(JYFormRowDescriptor * _Nonnull sender) {
        [self accessService:JYServiceTypeHealth];
    };
    [section addFormRow:row];


    JYForm *form = [JYForm formWithFormDescriptor:formDescriptor autoLayoutSuperView:self.view];
    [form beginLoading];
    
    
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)accessService:(JYServiceType)type
{
    JYAuthorizationManager *manager = [JYAuthorizationManager shareManager];
    [manager requestAccessToServiceType:type completion:^(BOOL granted, NSError * _Nonnull error) {
        if (!granted) {
            [manager jy_showErrorDetail:error viewController:self];
        } else {
            // todo...
        }
    }];
}


@end

