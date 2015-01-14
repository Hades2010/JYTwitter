//
//  RWTweet.h
//  JYTwitter
//
//  Created by JinYong on 15-1-14.
//  Copyright (c) 2015年 apple. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RWTweet : NSObject
@property (nonatomic, strong) NSString *status;
@property (nonatomic, strong) NSString *profileImageUrl;
@property (nonatomic, strong) NSString *username;

+(instancetype)tweetWithStatus:(NSDictionary *)status;
@end
