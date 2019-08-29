//
//  ModuleContext.h
//  KKJSBridgeDemo
//
//  Created by karos li on 2019/8/29.
//  Copyright © 2019 karosli. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ModuleContext : NSObject

@property (nonatomic, weak) UIViewController *vc;
@property (nonatomic, weak) UIScrollView *scrollView;
@property (nonatomic, copy) NSString *name;

@end

NS_ASSUME_NONNULL_END
