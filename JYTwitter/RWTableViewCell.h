//
//  RWTableViewCell.h
//  JYTwitter
//
//  Created by JinYong on 15-1-14.
//  Copyright (c) 2015年 apple. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RWTableViewCell : UITableViewCell
@property (nonatomic, weak) IBOutlet UIImageView *twitterAvatarView;
@property (nonatomic, weak) IBOutlet UILabel *twitterStatusText;
@property (nonatomic, weak) IBOutlet UILabel *twitterUsernameText;
@end
