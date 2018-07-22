//
//  WebViewController.m
//  WebView
//
//  Created by 远方 on 2018/7/22.
//  Copyright © 2018年 远方. All rights reserved.
//
#define ScreenWidth [UIScreen mainScreen].bounds.size.width
#define ScreenHeight [UIScreen mainScreen].bounds.size.height
#define ViewHeight ((ScreenHeight == 812) ? ScreenHeight - 88 : ScreenHeight - 64)


#import "WebViewController.h"
#import <JavaScriptCore/JavaScriptCore.h>

@interface WebViewController () <UIWebViewDelegate>

@property (nonatomic, strong) UIWebView *webView;//webView网页
@property (nonatomic, strong) UIActivityIndicatorView *loadingView; //加载等待
@property (nonatomic, strong) UILabel *titleLabel; //页面标题
@property (nonatomic, strong) UIView *titleView; //h5页面导航栏标题view
@property (nonatomic, strong) NSURL *loadURL; //跳转的url

@end

@implementation WebViewController

- (instancetype)initWithUrl:(NSString *)url {
    self = [super init];
    if (self) {
        if (url.length > 0) {
            self.loadURL = [NSURL URLWithString:url];
        }
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configTitleView];
    [self setTitleWithLoading:@"加载中..." andShowLoading:YES];
    [self startLoading];
}

//page init
- (void)configTitleView {
    self.titleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width - 160, 30)];
    
    self.loadingView = [[UIActivityIndicatorView alloc] init];
    self.loadingView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
    self.loadingView.hidesWhenStopped = YES;
    self.loadingView.center = CGPointMake(self.titleView.frame.size.width / 2 + 50, self.titleView.frame.size.height / 2);
    [self.titleView addSubview:self.loadingView];
    [self.loadingView startAnimating];
    
    self.titleLabel = [[UILabel alloc] initWithFrame:self.titleView.frame];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.font =[UIFont systemFontOfSize:16];
    self.titleLabel.textColor = [UIColor whiteColor];
    [_titleView addSubview:self.titleLabel];
    
    self.navigationItem.titleView = _titleView;
    
    self.webView = [[UIWebView alloc] init];
    self.webView.frame = CGRectMake(0, 0, ScreenWidth, ViewHeight);
    self.webView.delegate = self;
    self.webView.opaque = NO;
    self.webView.scalesPageToFit = YES;
    [self.view addSubview:self.webView];
}

//change frame
- (void)changeWebViewFrame:(CGRect)rect {
    self.webView.frame = rect;
}

- (void)setTitleWithLoading:(NSString *)title andShowLoading:(BOOL)shouldShowLoading {
    self.titleLabel.text = title;
    if (shouldShowLoading) {
        
        [_loadingView startAnimating];
    } else {
        
        [_loadingView stopAnimating];
    }
}

//start loading
- (void)startLoading {
    if (self.loadURL) {
        
        NSURLRequest *request = [[NSURLRequest alloc] initWithURL:self.loadURL];
        [self.webView loadRequest:request];
    } else {
        
        [self setTitleWithLoading:@"无效地址" andShowLoading:NO];
    }
}

#pragma mark - webView Delegate
//should start load
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    return [self shouldStartLoadWithRequest:request];
}

- (BOOL)shouldStartLoadWithRequest:(NSURLRequest *)request {
    if ([request.URL.absoluteString isEqualToString:self.loadURL.absoluteString] == NO) {
        if([request.URL.absoluteString hasPrefix:@"http"]) {
            
            return NO;
        } else {
            
            [self setTitleWithLoading:@"加载中..." andShowLoading:YES];
            return YES;
        }
    } else {
        
        return YES;
    }
}

//finish load
- (void)webViewDidFinishLoad:(UIWebView *)webView {
    
    NSString *theTitle = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    [self setTitleWithLoading:theTitle andShowLoading:NO];
    
    JSContext * jsContext = [webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    
    jsContext.exceptionHandler = ^(JSContext *context, JSValue *exceptionValue) {//异常
        context.exception = exceptionValue;
        NSLog(@"异常信息：%@", exceptionValue);
        return;
    };
    
    [self didLoadFinish:jsContext];
}

//Logical processing
- (void)didLoadFinish:(JSContext *)currentContext {
    currentContext[@"pushViewController"] = ^(NSString *string) {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIViewController *vc = [[NSClassFromString(string) alloc] init];
            [self.navigationController pushViewController:vc animated:YES];
        });
    };
    
    currentContext[@"pressentViewController"] = ^(NSString *string) {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIViewController *vc = [[NSClassFromString(string) alloc] init];
            if (vc != nil) {
                UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
                 [self presentViewController:nav animated:YES completion:nil];
            }
        });
    };
    
    currentContext[@"goBack"] = ^() {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.navigationController popViewControllerAnimated:YES];
        });
    };
    
    currentContext[@"goBackController"] = ^(NSString *string) {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIViewController *viewController = [[NSClassFromString(string) alloc] init];
            if (viewController == nil) {
                if ([string integerValue] >= 0 && [string integerValue] < [[self.navigationController viewControllers] count]) {
                    UIViewController *vc = [[self.navigationController viewControllers] objectAtIndex:[string integerValue]];
                    [self.navigationController popToViewController:vc animated:YES];
                }
            } else {
                for (UIViewController *vc in [self.navigationController viewControllers]) {
                    if ([vc isKindOfClass:[viewController class]]) {
                        [self.navigationController popToViewController:vc animated:YES];
                    }
                }
            }
        });
    };
    
    currentContext[@"goBackRoot"] = ^() {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.navigationController popToRootViewControllerAnimated:YES];
        });
    };
    
    currentContext[@"dismiss"] = ^() {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self dismissViewControllerAnimated:YES completion:nil];
        });
    };
}

//failure
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [self setTitleWithLoading:@"加载失败..." andShowLoading:NO];
}

//refresh
- (void)reloadView {
    [self.webView reload];
}

/**清除缓存和cookie*/
- (void)cleanCacheAndCookie {
    //清除cookies
    NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (NSHTTPCookie *cookie in [storage cookies]){
        [storage deleteCookie:cookie];
    }
    //清除UIWebView的缓存
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    NSURLCache * cache = [NSURLCache sharedURLCache];
    [cache removeAllCachedResponses];
    [cache setDiskCapacity:0];
    [cache setMemoryCapacity:0];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
