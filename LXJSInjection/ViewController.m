//
//  ViewController.m
//  LXJSInjection
//
//  Created by lixu06 on 16/11/21.
//  Copyright © 2016年 lixu06. All rights reserved.
//

#import "ViewController.h"

typedef NS_ENUM(NSInteger, GESTURE_STATE) {
    GESTURE_STATE_START,
    GESTURE_STATE_MOVE,
    GESTURE_STATE_END,
    GESTURE_STATE_CANCEL
};


@interface ViewController () <UIActionSheetDelegate>

    @property (strong, nonatomic) UIWebView *webView;
    @property (strong, nonatomic) NSString *imgURL;
    @property (assign, nonatomic) NSInteger gesState;
    @property (strong, nonatomic) NSTimer *timer;
    
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"JS注入";
    // Set Up WebView
    self.webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
    self.webView.backgroundColor = [UIColor redColor];
    [self.view addSubview:self.webView];
    self.webView.delegate = self;
    NSURL *url = [NSURL URLWithString:@"https://www.baidu.com"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [self.webView loadRequest:request];
}
    
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
    
#pragma mark - UIWebViewDelegate
- (void)webViewDidFinishLoad:(UIWebView *)webview {
    /*!
     * 加载完成后注入监听touch事件的js代码
     */
    NSString *kTouchJavaScriptString = [self getJSCode];
    [self.webView stringByEvaluatingJavaScriptFromString:kTouchJavaScriptString];
//    [self.webView stringByEvaluatingJavaScriptFromString:@"document.documentElement.style.webkitUserSelect='none';"];
//    [self.webView stringByEvaluatingJavaScriptFromString:@"document.documentElement.style.webkitTouchCallout='none';"];
}
    
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSString *actionType = request.URL.host;
    NSString *scheme = request.URL.scheme;
    NSString *fragment =[request.URL.fragment stringByRemovingPercentEncoding];
    if(![@"lxjsinject-touch" isEqualToString:scheme]){
        return YES;
    }
    if (![@"index" isEqualToString:actionType]) {
        return YES;
    }
    NSArray *components = [fragment componentsSeparatedByString:@":"];
    if ([components count] > 1 && [(NSString *)[components objectAtIndex:0] isEqualToString:@"myweb"]) {
        if([(NSString *)[components objectAtIndex:1] isEqualToString:@"touch"]) {
            //ZXLog(@"you are touching!");
            NSString *touchAction = (NSString *)[components objectAtIndex:2];
            // 处理touch事件
            if ([touchAction isEqualToString:@"start"]) {
                self.gesState = GESTURE_STATE_START;
                float ptX = [[components objectAtIndex:3]floatValue];
                float ptY = [[components objectAtIndex:4]floatValue];
                NSLog(@"touch start (%f, %f)", ptX, ptY);
                // 获取touch位置处的element
                NSString *js = [NSString stringWithFormat:@"document.elementFromPoint(%f, %f).tagName", ptX, ptY];
                NSString * tagName = [self.webView stringByEvaluatingJavaScriptFromString:js];
                self.imgURL = nil;
                if ([tagName isEqualToString:@"IMG"]) {
                    NSString *jsSrc = [NSString stringWithFormat:@"document.elementFromPoint(%f, %f).src", ptX, ptY];
                    self.imgURL = [self.webView stringByEvaluatingJavaScriptFromString:jsSrc];
                    if (self.imgURL) {
                        self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(handleLongTouch:) userInfo:@{@"content":@"图片长按"} repeats:NO];
                    }
                } else if ([tagName isEqualToString:@"SPAN"]) {
                    self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(handleLongTouch:) userInfo:@{@"content":@"文字长按"} repeats:NO];
                }
                
            } else if ([touchAction isEqualToString:@"move"]) {
                //**如果touch动作是滑动，则取消hanleLongTouch动作**//
                self.gesState = GESTURE_STATE_MOVE;
                NSLog(@"you are move");
            } else if ([touchAction isEqualToString:@"end"]) {
                [self.timer invalidate];
                self.timer = nil;
                self.gesState = GESTURE_STATE_END;
                NSLog(@"touch end");
            } else if ([touchAction isEqualToString:@"cancel"]) {
                [self.timer invalidate];
                self.timer = nil;
                self.gesState = GESTURE_STATE_CANCEL;
                NSLog(@"touch cancel");
            }
        }
    }
    return NO;
}
    
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    NSLog(@"Loading Fail");
}
    
//如果点击的是图片，并且按住的时间超过1s，执行handleLongTouch函数，处理图片操作。
- (void)handleLongTouch:(NSTimer*)theTimer {
    NSString *content = theTimer.userInfo[@"content"];
    if (self.gesState == GESTURE_STATE_START) {
        UIActionSheet* sheet = [[UIActionSheet alloc] initWithTitle:nil
                                                           delegate:self
                                                  cancelButtonTitle:@"取消"
                                             destructiveButtonTitle:nil
                                                  otherButtonTitles:content, nil];
        sheet.cancelButtonIndex = sheet.numberOfButtons - 1;
        [sheet showInView:[UIApplication sharedApplication].keyWindow];
    }
}
    
/* 
 * @brief 从文件获取js代码
 */
- (NSString *)getJSCode{
    NSString *jsFilePath = [[NSBundle mainBundle] pathForResource:@"JS_INJECTION_TOUCH_EVENT"
                                                           ofType:@"js"];
    
        NSFileManager *manager = [NSFileManager defaultManager];
        if (![manager fileExistsAtPath:jsFilePath]) {
            return nil;
        }
        NSFileHandle *file = [NSFileHandle fileHandleForReadingAtPath:jsFilePath];
    NSData *data = [file readDataToEndOfFile];
    return [[NSString alloc] initWithData:data  encoding:NSUTF8StringEncoding];
}


@end
