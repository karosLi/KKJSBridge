//
//  WebViewController.h
//  KKJSBridge
//
//  Created by karos li on 2019/8/29.
//  Copyright © 2019 karosli. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WebViewController : UIViewController

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithUrl:(NSString * _Nullable)url NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
