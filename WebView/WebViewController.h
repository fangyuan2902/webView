//
//  WebViewController.h
//  WebView
//
//  Created by 远方 on 2018/7/22.
//  Copyright © 2018年 远方. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WebViewController : UIViewController

- (instancetype)initWithUrl:(NSString *)url;

- (void)changeWebViewFrame:(CGRect)rect;

- (void)reloadView;

- (void)cleanCacheAndCookie;

@end
