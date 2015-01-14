//
//  RWSearchFormViewController.m
//  JYTwitter
//
//  Created by JinYong on 15-1-14.
//  Copyright (c) 2015年 apple. All rights reserved.
//

#import "RWSearchFormViewController.h"
#import "RWSearchResultsViewController.h"
#import "RWTweet.h"
#import <Accounts/Accounts.h>
#import <Social/Social.h>

typedef NS_ENUM(NSInteger, RWSinaInstantError) {
    RWSinaInstantErrorAccessDenied,
    RWSinaInstantErrorNoSinaAccounts,
    RWSinaInstantErrorInvalidResponse
};

static NSString *const RWSinaInstantDomain = @"SinaInstant";

@interface RWSearchFormViewController ()
@property (nonatomic, weak) IBOutlet UITextField *searchText;
@property (nonatomic, strong) RWSearchResultsViewController *resultViewController;

@property (nonatomic, strong) ACAccountStore *accountStore;
@property (nonatomic, strong) ACAccountType *accountType;

@end

@implementation RWSearchFormViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Twitter Instant";
    [self styleTextField:self.searchText];
    self.resultViewController = self.splitViewController.viewControllers[1];
    
    @weakify(self)
    
    [[self.searchText.rac_textSignal
     map:^id(NSString *text) {
        return [self isValidSearchText:text]?[UIColor clearColor]:[UIColor yellowColor];
    }]
    subscribeNext:^(UIColor *color) {
        @strongify(self)
        self.searchText.backgroundColor = color;
    }];
    
//    __typeof(self) __weak weakSelf = self;
//    
//    [[self.searchText.rac_textSignal
//      map:^id(NSString *text) {
//        return [weakSelf isValidSearchText:text] ? [UIColor clearColor]:[UIColor yellowColor];
//    }]
//     subscribeNext:^(UIColor *color) {
//        weakSelf.searchText.backgroundColor = color;
//    }];
    
//    RACSignal *searchTextSignal = [self.searchText.rac_textSignal map:^id(NSString *text) {
//        return @([self isValidSearchText:text]);
//    }];
//    RAC(self.searchText,backgroundColor) = [searchTextSignal map:^id(NSNumber *searchTextValid) {
//        return [searchTextValid boolValue]?[UIColor clearColor]:[UIColor yellowColor];
//    }];
    
//    RACSignal *backgroundColorSignal = [self.searchText.rac_textSignal map:^id(NSString *text) {
//        return [self isValidSearchText:text]?[UIColor clearColor]:[UIColor yellowColor];
//    }];
//    
//    RACDisposable *subscripion = [backgroundColorSignal subscribeNext:^(UIColor *color) {
//        self.searchText.backgroundColor = color;
//    }];
//    
//    //在某个位置调用
//    [subscripion dispose];
    
    //创建账户存储
    self.accountStore = [[ACAccountStore alloc] init];
    self.accountType = [self.accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierSinaWeibo];

    
//    [[self requestAccessToSinaSignal]
//     subscribeNext:^(id x) {
//         NSLog(@"Access granted");
//    } error:^(NSError *error) {
//        NSLog(@"An error occurred:%@",error);
//    }];
    
//    [[[self requestAccessToSinaSignal] then:^RACSignal *{
//        @strongify(self)
//        return self.searchText.rac_textSignal;
//    }]
//    subscribeNext:^(id x) {
//        NSLog(@"%@",x);
//    } error:^(NSError *error) {
//        NSLog(@"An error occurred :%@",error);
//    }];
    
    [[[[[[[self requestAccessToSinaSignal] then:^RACSignal *{
        @strongify(self)
        return self.searchText.rac_textSignal;
    }] filter:^BOOL(NSString *text) {
        @strongify(self)
        return [self isValidSearchText:text];
    }]
       throttle:0.5]
     flattenMap:^RACStream *(NSString *text) {
         @strongify(self)
         return [self signalForSearchWithText:text];
     }]
     deliverOn:[RACScheduler mainThreadScheduler]]
     subscribeNext:^(NSDictionary *jsonSearchResult) {
        NSLog(@"%@",jsonSearchResult);
         NSArray *statuses = jsonSearchResult[@"statuses"];
         NSArray *tweets = [statuses linq_select:^id(id tweet) {
             return [RWTweet tweetWithStatus:tweet];
         }];
         [self.resultViewController displayTweets:tweets];
    } error:^(NSError *error) {
        NSLog(@"An error occurred :%@",error);
    }];
}

- (BOOL)isValidSearchText:(NSString *)text
{
    return text.length>2;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)styleTextField:(UITextField *)textField{
    CALayer *textFieldLayer = textField.layer;
    textFieldLayer.borderColor = [UIColor grayColor].CGColor;
    textFieldLayer.borderWidth = 2.0f;
    textFieldLayer.cornerRadius = 0.0f;
}

- (RACSignal *)requestAccessToSinaSignal{
    //定义一个错误，如果用户拒绝访问则发送
    NSError *accessError = [NSError errorWithDomain:RWSinaInstantDomain code:RWSinaInstantErrorAccessDenied userInfo:nil];
    
    //创建并返回信号
    @weakify(self)
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        //请求访问sina
        @strongify(self)
        [self.accountStore requestAccessToAccountsWithType:self.accountType options:nil completion:^(BOOL granted, NSError *error) {
            //处理相应
            if (!granted) {
                [subscriber sendError:accessError];
            }
            else
            {
                [subscriber sendNext:nil];
                [subscriber sendCompleted];
            }
        }];
        return nil;
    }];
}

- (SLRequest *)requestforSinaSearchWithText:(NSString *)text{
    NSURL *url = [NSURL URLWithString:@"https://api.weibo.com/2/statuses/friends_timeline.json"];
    NSDictionary *params = @{@"q":text};
    SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeSinaWeibo
                                            requestMethod:SLRequestMethodGET
                                                      URL:url
                                               parameters:params];
    return request;
}

- (RACSignal *)signalForSearchWithText:(NSString *)text{
    //定义错误
    NSError *noAccountError = [NSError errorWithDomain:RWSinaInstantDomain
                                                  code:RWSinaInstantErrorNoSinaAccounts
                                              userInfo:nil];
    
    NSError *invalidResponseError = [NSError errorWithDomain:RWSinaInstantDomain code:RWSinaInstantErrorInvalidResponse userInfo:nil];
    
    //创建信号block
    @weakify(self)
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        @strongify(self)
        
        //创建请求
        SLRequest *request = [self requestforSinaSearchWithText:text];
        
        //提供sina账号
        NSArray *sinaAccounts = [self.accountStore accountsWithAccountType:self.accountType];
        if (sinaAccounts.count == 0) {
            [subscriber sendError:[sinaAccounts lastObject]];
        }
        else
        {
            [request setAccount:[sinaAccounts lastObject]];
            
            //执行请求
            [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
                if (urlResponse.statusCode == 200) {
                    //成功,解析相应
                    NSDictionary *timelineData = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingAllowFragments error:nil];
                    [subscriber sendNext:timelineData];
                    [subscriber sendCompleted];
                }
                else
                {
                    //失败
                    [subscriber sendError:invalidResponseError];
                }
            }];
        }
        return nil;
    }];
}
@end
