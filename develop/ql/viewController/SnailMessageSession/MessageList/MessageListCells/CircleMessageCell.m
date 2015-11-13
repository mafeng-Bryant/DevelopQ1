//
//  circleMessageCell.m
//  ql
//
//  Created by yunlai on 14-3-3.
//  Copyright (c) 2014年 ChenFeng. All rights reserved.
//

#import "CircleMessageCell.h"
#import "UIImageScale.h"
#import "UIImageView+WebCache.h"
#import "SBJson.h"

@interface CircleMessageCell ()
{
    
}


@property (nonatomic, retain) UIImageView * invitedSign;
@property (nonatomic, assign) SDImageCache * imageCache;

@end

@implementation CircleMessageCell
{
    UIImageView * _inviteArrow;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    self.imageCache = [SDImageCache sharedImageCache];
    
    //添加是否为邀请消息的指示箭头
    UIImageView * invitedSign = [[UIImageView alloc]initWithFrame:CGRectMake(CGRectGetMinX(_msgLabel.frame) - 13, CGRectGetMinY(_msgLabel.frame) + 10, 12, 12)];
    [invitedSign setImage:[UIImage imageCwNamed:@"ico_chat_invite.png"]];
    
    self.invitedSign = invitedSign;
    self.invitedSign.hidden = YES;
    [self.contentView addSubview:invitedSign];
    RELEASE_SAFE(invitedSign);
    
    return self;
}

- (void)freshWithInfoDic:(NSDictionary *)messageDic
{
    [super freshWithInfoDic:messageDic];
    
    //判断是否为邀请消息，并根据邀请消息情况来展示邀请旗帜
    if ([[messageDic objectForKey:@"invited_sign"]intValue] == 1){
        self.invitedSign.hidden = NO;
    } else if ([[messageDic objectForKey:@"invited_sign"]intValue] == 2){
        self.invitedSign.hidden = YES;
    }
    
    //加载圈子头像数据
    NSString *portraitArrJsonStr = [messageDic objectForKey:@"icon_path"];
    NSArray * portraitArr = [portraitArrJsonStr JSONValue];
    if (portraitArr.count > 0) {
        [self typesetHead:portraitArr.count andImages:portraitArr];
    }
}

- (void)typesetHead:(NSInteger)index andImages:(NSArray *)imgsArray{
    
    //移除老的头像
    _headView.image = nil;
    for (UIView *subView in _headView.subviews) {
        [subView removeFromSuperview];
    }
    
    //按人数加载新头像
    if (index == 1)
    {
        NSString * portraitStr = [imgsArray firstObject];
        NSURL * portraitUrl = [NSURL URLWithString:portraitStr];
        
        [_headView setImageWithURL:portraitUrl placeholderImage:[UIImage imageCwNamed:DEFAULT_MALE_PORTRAIT_NAME]];
    } else if (index == 2)
    {
        CGRect rect;
        for (int i = 0; i< index; i++)
        {
            rect = CGRectMake(25 * i + 5, kleftPadding, smallHeight, smallHeight);
            NSString *imgStrs = [NSString stringWithFormat:@"%@",[imgsArray objectAtIndex:i]];
            NSURL * portraitUrl = [NSURL URLWithString:imgStrs];
            
            UIImageView *smallView = [[UIImageView alloc]initWithFrame:rect];
            smallView.backgroundColor = [UIColor grayColor];
            smallView.layer.cornerRadius = 10;
            smallView.clipsToBounds = YES;
            
            UIImage *portaitImg = [self.imageCache imageFromDiskCacheForKey:imgStrs];
            
            if (portaitImg != nil) {
                smallView.image = portaitImg;
            } else {
                [smallView setImageWithURL:portraitUrl placeholderImage:[UIImage imageNamed:DEFAULT_MALE_PORTRAIT_NAME]options:SDWebImageProgressiveDownload];
            }
            [_headView addSubview:smallView];
            RELEASE_SAFE(smallView);
        }
    } else if (index >= 3)
    {
        for (int i = 0; i< 3; i++) {
            CGRect rect;
            if (i == 0) {
                rect = CGRectMake(15.f, 3.f, smallHeight, smallHeight);
            }else{
                rect = CGRectMake(25 * (i-1) + 3, 25.f, smallHeight, smallHeight);
            }
            
            NSString *imgStrs = [NSString stringWithFormat:@"%@",[imgsArray objectAtIndex:i]];
            NSURL * portraitUrl = [NSURL URLWithString:imgStrs];
            
            UIImageView *smallView = [[UIImageView alloc]initWithFrame:rect];
            smallView.backgroundColor = [UIColor grayColor];
            smallView.layer.cornerRadius = 10;
            smallView.clipsToBounds = YES;
            
            UIImage *portaitImg = [self.imageCache imageFromDiskCacheForKey:imgStrs];
            
            if (portaitImg != nil) {
                smallView.image = portaitImg;
            } else {
                [smallView setImageWithURL:portraitUrl placeholderImage:[UIImage imageNamed:DEFAULT_MALE_PORTRAIT_NAME]options:SDWebImageProgressiveDownload];
            }
            [_headView addSubview:smallView];
            RELEASE_SAFE(smallView);
        }
    }
}

- (void)dealloc
{
    LOG_RELESE_SELF;
    RELEASE_SAFE(_inviteArrow);
    [super dealloc];
}

@end
