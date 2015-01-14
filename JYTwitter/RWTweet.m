//
//  RWTweet.m
//  JYTwitter
//
//  Created by JinYong on 15-1-14.
//  Copyright (c) 2015年 apple. All rights reserved.
//

#import "RWTweet.h"

@implementation RWTweet

+(instancetype)tweetWithStatus:(NSDictionary *)status
{
    RWTweet *tweet = [RWTweet new];
    tweet.status            = status[@"text"];
    
    NSDictionary *user      = status[@"user"];
    tweet.profileImageUrl   = user[@"profile_image_url"];
    tweet.username          = user[@"screen_name"];
    
    return tweet;
}
@end
