//
//  IAnalyticsManager.h
//  livestream
//
//  Created by Calvin on 17/10/18.
//  Copyright © 2017年 net.qdating. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol IAnalyticsManager <NSObject>

/**
 跟踪屏幕创建

 @param viewController 界面控制器实例
 */
- (void)reportAllocScreen:(UIViewController *)viewController assignScreenName:(NSString *)screenName;

/**
 跟踪屏幕销毁

 @param viewController 界面控制器实例
 */
- (void)reportDeallocScreen:(UIViewController *)viewController;

/**
 跟踪屏幕显示

 @param viewController 界面控制器实例
 */
- (void)reportShowScreen:(UIViewController *)viewController assignScreenName:(NSString *)screenName;

/**
 跟踪屏幕消失

 @param viewController 界面控制器实例
 */
- (void)reportDismissScreen:(UIViewController *)viewController;

/**
 跟踪屏幕显示页

 @param viewController 界面控制器实例
 @param pageIndex 页面号
 */
- (void)reportDidShowPage:(UIViewController *)viewController pageIndex:(NSUInteger)pageIndex;

/**
 跟踪用户事件
 
 @param action 事件操作
 @param category 类型
 */
- (void)reportActionEvent:(NSString *)action eventCategory:(NSString *)category;

/**
跟踪用户事件

 @param action 事件操作
 @param category 类型
 @param label 标签
 @param value 数值
 */
- (void)reportActionEvent:(NSString *)action eventCategory:(NSString *)category label:(NSString *)label value:(NSNumber *)value;

/**
 跟踪用户事件

 @param action 事件操作
 @param category 类型
 @param label 标签
 @param value 数值
 @param dimension 纬度
 @param dimensionIndex 纬度下标
 */
- (void)reportActionEvent:(NSString *)action eventCategory:(NSString *)category label:(NSString *)label value:(NSNumber *)value dimension:(NSString *)dimension dimensionIndex:(NSInteger)dimensionIndex;


/**
 跟踪App被打开

 @param url 被打开的URL
 */
- (void)openURL:(NSURL *)url;


@end