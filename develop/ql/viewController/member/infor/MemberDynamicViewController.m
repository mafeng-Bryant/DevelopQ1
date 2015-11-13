//
//  MemberDynamicViewController.m
//  ql
//
//  Created by yunlai on 14-8-5.
//  Copyright (c) 2014年 LuoHui. All rights reserved.
//

#import "MemberDynamicViewController.h"

#import "config.h"
#import "scanViewController.h"
#import "SidebarViewController.h"
#import "MeetingMainViewController.h"
#import "TalkingMainViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>

#import "imageBrowser.h"
#import "DyListViewController.h"

#import "MemberDetailViewController.h"
#import "MessageListViewController.h"
#import "MemberMainViewController.h"

#import "CHTumblrMenuView.h"
#import "TYDotIndicatorView.h"
#import "cardDetailViewController.h"

#import "Common.h"
#import "aboutMeMsgListViewController.h"
#import "dynamic_card_model.h"

#import "dyCardTableViewCell.h"

@interface MemberDynamicViewController (){
    
    //加载效果view
    TYDotIndicatorView *_darkCircleDot;
    //卡片对象组
    NSMutableArray* cardsArr;
    
}

@end

//最大卡片数目 用于是否加载更多
#define MAXCARDCOUNT 2

@implementation MemberDynamicViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    self.view.backgroundColor = [[ThemeManager shareInstance] getColorWithName:@"COLOR_LIGHTWEIGHT"];
    
    if (IOS_VERSION_7) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
        self.navigationController.navigationBar.translucent = NO;
    }
    
    isLoading = NO;
    
    cardsArr = [[NSMutableArray alloc] init];
    
    dytableview = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, KUIScreenHeight - 44.0f) style:UITableViewStylePlain];
    dytableview.delegate = self;
    dytableview.dataSource = self;
    dytableview.backgroundColor = [UIColor clearColor];
    dytableview.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.view addSubview:dytableview];
    
    _darkCircleDot = [[TYDotIndicatorView alloc] initWithFrame:CGRectMake(0, 0.f, KUIScreenWidth, KUIScreenHeight) dotStyle:TYDotIndicatorViewStyleCircle dotColor:[UIColor colorWithWhite:0.6 alpha:1.0] dotSize:CGSizeMake(10, 10)];
    if (IOS_VERSION_7) {
        _darkCircleDot.backgroundColor = [UIColor colorWithRed:0. green:0. blue:0. alpha:0.3];
    }else{
        _darkCircleDot.backgroundColor = [UIColor clearColor];
    }
    [_darkCircleDot startAnimating];
    [self.view addSubview:_darkCircleDot];
    
    [self addheadAndFoot];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"addNewCard" object:nil];
    
    //个人发布的动态
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"deleteMineDynamic" object:nil];
    
    //注册发布动态成功的通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addNewCard:) name:@"addNewCard" object:nil];
    
    //个人发布的动态
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dynamicDeleteNotice:) name:@"deleteMineDynamic" object:nil];
    
    [self accessMyDynamicService];
    
    self.navigationItem.title = @"我的动态";
}

//发布动态成功后刷新
-(void) addNewCard:(NSNotification*) notify{
    [self accessMyDynamicService];
}

- (void)viewWillAppear:(BOOL)animated{
    //查看他人动态时需显示，不然有bug
    [self.navigationController setNavigationBarHidden:NO animated:NO];
}

//动态 删除通知  重新请求数据刷新列表
-(void) dynamicDeleteNotice:(NSNotification*) notify{
    [self accessMyDynamicService];
}

-(void) addheadAndFoot{
    dytableview.contentSize = CGSizeMake(self.view.bounds.size.width, (self.view.bounds.size.height/3)*cardsArr.count);
    
    footerVew = [[LoadMoreTableFooterView alloc] initWithFrame:CGRectMake(0, dytableview.contentSize.height, self.view.bounds.size.width, 50)];
    footerVew.delegate = self;
    footerVew.backgroundColor = [UIColor clearColor];
    
    [dytableview addSubview:footerVew];
    [dytableview bringSubviewToFront:footerVew];
    
    footerVew.hidden = YES;
    if (cardsArr.count >= MAXCARDCOUNT) {
        footerVew.hidden = NO;
    }
}

-(void) freshRedLabAndFooter{
    
    dytableview.contentSize = CGSizeMake(self.view.bounds.size.width, (320)*cardsArr.count);
    footerVew.frame = CGRectMake(0, dytableview.contentSize.height, self.view.bounds.size.width, 50);
    if (cardsArr.count >= MAXCARDCOUNT) {
        footerVew.hidden = NO;
    }else{
        footerVew.hidden = YES;
    }
    
    [dytableview bringSubviewToFront:footerVew];
}

#pragma mark - scrollDelegate

-(void) scrollViewDidScroll:(UIScrollView *)scrollView{
    [footerVew egoRefreshScrollViewDidScroll:scrollView];
}

-(void) scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    
}

-(void) scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    if (cardsArr.count >= MAXCARDCOUNT) {
        [footerVew egoRefreshScrollViewDidEndDragging:scrollView];
    }
}

#pragma mark - egodelegate

-(void) loadMoreTableFooterDidTriggerLoadMore:(LoadMoreTableFooterView *)view{
    [self accessMyDynamicMoreService];
}

/**
 *  返回按钮
 */
- (void)backBarBtn{
    UIButton *backButton = [UIButton  buttonWithType:UIButtonTypeCustom];
    [backButton addTarget:self action:@selector(backTo) forControlEvents:UIControlEventTouchUpInside];
    
    [backButton setImage:[[ThemeManager shareInstance] getThemeImage:@"ico_common_return.png"] forState:UIControlStateNormal];
    backButton.imageEdgeInsets = UIEdgeInsetsMake(0, -20, 0, 0);
    
    backButton.frame = CGRectMake(0 , 30, 44.f, 44.f);
    if (IOS_VERSION_7) {
        backButton.imageEdgeInsets = UIEdgeInsetsMake(0, -15, 0, 0);
    }
    UIBarButtonItem  *backItem = [[UIBarButtonItem  alloc]  initWithCustomView:backButton];
    self.navigationItem.leftBarButtonItem = backItem;
    RELEASE_SAFE(backItem);
}

- (void)backTo{
    
    [self.navigationController popViewControllerAnimated:YES];
    
}

#pragma mark - +号按钮点击
-(void) addBtnClick{
    CHTumblrMenuView* _CHmenuView = [[CHTumblrMenuView alloc] init];
    [_CHmenuView addMenuItemWithTitle:@"照相" andIcon:IMG(@"ico_feed_pic") andSelectedBlock:^{
        NSLog(@"图文");
        //发布图文
//        TalkingMainViewController* talkVC = [[TalkingMainViewController alloc] init];
//        talkVC.pType = PublicImages;
//        [self.navigationController pushViewController:talkVC animated:NO];
//        RELEASE_SAFE(talkVC);
        
        WatermarkCameraViewController *watermarkCamera = [[WatermarkCameraViewController alloc]init];
        watermarkCamera.type = 1;
        watermarkCamera.currentImageCount = 0;
        watermarkCamera.delegate = self;
        [self presentViewController:watermarkCamera animated:YES completion:nil];
        [watermarkCamera release];
        
    }];
    [_CHmenuView addMenuItemWithTitle:@"图文" andIcon:IMG(@"ico_feed_text") andSelectedBlock:^{
        NSLog(@"图文");
        //发布图文
        TalkingMainViewController* talkVC = [[TalkingMainViewController alloc] init];
        talkVC.pType = PublicImages;
        [self.navigationController pushViewController:talkVC animated:YES];
        RELEASE_SAFE(talkVC);
        
    }];
    [_CHmenuView addMenuItemWithTitle:@"聚聚" andIcon:IMG(@"ico_feed_party") andSelectedBlock:^{
        NSLog(@"聚聚");
        MeetingMainViewController* meetVC = [[MeetingMainViewController alloc] init];
        [self.navigationController pushViewController:meetVC animated:YES];
        RELEASE_SAFE(meetVC);
    }];
    [_CHmenuView addMenuItemWithTitle:@"我有" andIcon:IMG(@"ico_feed_have") andSelectedBlock:^{
        NSLog(@"我有");
        TalkingMainViewController* talkVC = [[TalkingMainViewController alloc] init];
        talkVC.pType = PublicHave;
        [self.navigationController pushViewController:talkVC animated:YES];
        RELEASE_SAFE(talkVC);
        
    }];
    [_CHmenuView addMenuItemWithTitle:@"我要" andIcon:IMG(@"ico_feed_want") andSelectedBlock:^{
        NSLog(@"我要");
        TalkingMainViewController* talkVC = [[TalkingMainViewController alloc] init];
        talkVC.pType = PublicWant;
        [self.navigationController pushViewController:talkVC animated:YES];
        RELEASE_SAFE(talkVC);
        
    }];
    [_CHmenuView addMenuItemWithTitle:@"OOXX" andIcon:IMG(@"ico_feed_ox") andSelectedBlock:^{
        
        NSLog(@"OOXX");
        TalkingMainViewController* talkVC = [[TalkingMainViewController alloc] init];
        talkVC.pType = PublicOOXX;
        [self.navigationController pushViewController:talkVC animated:YES];
        RELEASE_SAFE(talkVC);
        
    }];
    
    [_CHmenuView show];
    RELEASE_SAFE(_CHmenuView);
}

#pragma mark - waterCamera
-(void) didSelectImages:(NSArray *)images{
    TalkingMainViewController* talkVC = [[TalkingMainViewController alloc] init];
    talkVC.pType = PublicImages;
    talkVC.selectedImages = [images mutableCopy];
    [self.navigationController pushViewController:talkVC animated:YES];
    RELEASE_SAFE(talkVC);
}

#pragma mark - tableviewdelegate

-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (cardsArr.count) {
        return cardsArr.count;
    }
    return 1;
}

-(CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (cardsArr.count) {
        return 320;
    }else{
        return self.view.bounds.size.height;
    }
    return 320;
}

-(UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString* identifier = nil;
    
    if (cardsArr.count) {
        identifier = @"tableCardCell";
        
        dyCardTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifier];
        
        if (cell == nil) {
            cell = [[[dyCardTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier] autorelease];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }else{
            for (UIView* v in [cell.contentView viewWithTag:1000].subviews) {
                [v removeFromSuperview];
            }
        }
        
        cell.dataDic = [cardsArr objectAtIndex:indexPath.row];
        
        return cell;
        
    }else{
        identifier = @"noneCardCell";
        
        UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifier];
        if (cell == nil) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier] autorelease];
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
            UILabel* noneLab = [[UILabel alloc] init];
            noneLab.frame = CGRectMake(0, 12, self.view.bounds.size.width, self.view.bounds.size.height);
            noneLab.textAlignment = UITextAlignmentCenter;
            noneLab.numberOfLines = 2;
            noneLab.textColor = [UIColor darkGrayColor];
            noneLab.backgroundColor = [UIColor whiteColor];
            noneLab.font = KQLboldSystemFont(15);
            
            UIButton *publishBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            [publishBtn setFrame:CGRectMake(20.f, 60.f, 280.f, 140.f)];
            [publishBtn addTarget:self action:@selector(addBtnClick) forControlEvents:UIControlEventTouchUpInside];
            
            [publishBtn setBackgroundImage:IMGREADFILE(@"img_member_default3.png") forState:UIControlStateNormal];
            
            [cell.contentView addSubview:noneLab];
            [cell.contentView addSubview:publishBtn];
            
            noneLab.text = @"写点什么吧...";
            
            [noneLab release];
            
        }
        
        return cell;
    }
    
    return nil;
}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (cardsArr.count) {
        selectedIndex = indexPath.row;
        NSDictionary* dic = [cardsArr objectAtIndex:indexPath.row];
        
        [self accessDynamicDetail:[[dic objectForKey:@"id"] intValue]];
        
//        cardDetailViewController* cardDetailVC = [[cardDetailViewController alloc] init];
//        int type = [[dic objectForKey:@"type"] intValue];
//        
//        CardType cardT;
//        if (type == 0) {
//            cardT = CardImage;
//        }else if (type == 1) {
//            cardT = CardOOXX;
//        }else if (type == 2) {
//            cardT = CardOpenTime;
//        }else if (type == 3) {
//            cardT = CardWantOrHave;
//        }else if (type == 4){
//            cardT = CardWantOrHave;
//        }else if (type == 5){
//            cardT = CardNews;
//        }else if (type == 6) {
//            cardT = CardLabel;
//        }else if (type == 8) {
//            cardT = CardTogether;
//        }else{
//            cardT = CardImage;
//        }
//        cardDetailVC.type = cardT;
//        cardDetailVC.dataDic = dic;
//        cardDetailVC.detailType = DynamicDetailTypeMine;
//        
//        if (self.lookId) {
//            cardDetailVC.detailType = DynamicDetailTypeOther;
//        }
//        
//        [self.navigationController pushViewController:cardDetailVC animated:NO];
//        RELEASE_SAFE(cardDetailVC);
    }
}

- (void)accessMyDynamicService{
    NSString* reqUrl = @"member/mypublish.do?param=";
    
    NSNumber* userId = nil;
    
    if (self.lookId != 0) {
        userId = [NSNumber numberWithLongLong:self.lookId];
    }else{
        userId = [NSNumber numberWithInt:[[Global sharedGlobal].user_id intValue]];
    }
    
    NSMutableDictionary* requestDic = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       userId,@"user_id",
                                       [NSNumber numberWithInt:[[Global sharedGlobal].org_id intValue]],@"org_id",
                                       nil];
    
    [[NetManager sharedManager] accessService:requestDic data:nil command:MAINPAGE_DYNAMIC_COMMAND_ID accessAdress:reqUrl delegate:self withParam:nil];
}

//我的动态加载更多
-(void) accessMyDynamicMoreService{
    NSString* reqUrl = @"member/mypublish.do?param=";
    
    NSNumber* userId = nil;
    
    if (self.lookId != 0) {
        userId = [NSNumber numberWithLongLong:self.lookId];
    }else{
        userId = [NSNumber numberWithInt:[[Global sharedGlobal].user_id intValue]];
    }
    
    NSMutableDictionary* requestDic = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       userId,@"user_id",
                                       [NSNumber numberWithInt:[[Global sharedGlobal].org_id intValue]],@"org_id",
                                       [NSNumber numberWithInt:[[[cardsArr lastObject] objectForKey:@"id"] intValue]],@"id",
                                       [NSNumber numberWithInt:[[[cardsArr lastObject] objectForKey:@"created"] intValue]],@"created",
                                       nil];
    
    [[NetManager sharedManager] accessService:requestDic data:nil command:MAINPAGE_DYNAMIC_MORE_COMMAND_ID accessAdress:reqUrl delegate:self withParam:nil];
}

-(void) accessDynamicDetail:(int) publishId{
    NSString* reqUrl = @"member/publishDetail.do?param=";
    NSMutableDictionary* requestDic = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       [NSNumber numberWithInt:publishId],@"publish_id",
                                       [Global sharedGlobal].user_id,@"user_id",
                                       nil];
    [[NetManager sharedManager] accessService:requestDic data:nil command:DYNAMIC_DETAIL_COMMAND_ID accessAdress:reqUrl delegate:self withParam:nil];
}

#pragma mark - 网络请求回调
//请求回调
- (void)didFinishCommand:(NSMutableArray*)resultArray cmd:(int)commandid withVersion:(int)ver{
    NSLog(@"did finish");
    //移除loading
    [_darkCircleDot removeFromSuperview];
    
    if (![[resultArray lastObject] isKindOfClass:[NSString class]]) {
        switch (commandid) {
            case MAINPAGE_DYNAMIC_COMMAND_ID:
            {
                NSLog(@"my dynamic");
                dispatch_async(dispatch_get_main_queue(), ^{
                    [cardsArr removeAllObjects];
                    [cardsArr addObjectsFromArray:resultArray];
                    
                    [self freshRedLabAndFooter];
                    [dytableview reloadData];
                });
            }
                break;
            case MAINPAGE_DYNAMIC_MORE_COMMAND_ID:
            {
                NSLog(@"mainpage dynamic load more");
                [footerVew egoRefreshScrollViewDataSourceDidFinishedLoading:dytableview];
                if (resultArray.count) {
                    [cardsArr addObjectsFromArray:resultArray];
                    
                    [self freshRedLabAndFooter];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self reloadMoreList];
                    });
                }else{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [Common checkProgressHUD:@"没有更多了" andImage:nil showInView:self.view];
                    });
                    
                }
            }
                break;
            case DYNAMIC_DETAIL_COMMAND_ID:
            {
                //delete字段0未删除，1已删除
                int deleteStatus = [[[resultArray firstObject] objectForKey:@"delete"] intValue];
                if (deleteStatus) {
                    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:nil message:@"这条动态已被删除" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
                    [alert show];
                    [alert release];
                    return;
                }
                
                NSDictionary* dic = [resultArray firstObject];
                
                cardDetailViewController* cardDetailVC = [[cardDetailViewController alloc] init];
                int type = [[dic objectForKey:@"type"] intValue];
                
                CardType cardT;
                if (type == 0) {
                    cardT = CardImage;
                }else if (type == 1) {
                    cardT = CardOOXX;
                }else if (type == 2) {
                    cardT = CardOpenTime;
                }else if (type == 3) {
                    cardT = CardWantOrHave;
                }else if (type == 4){
                    cardT = CardWantOrHave;
                }else if (type == 5){
                    cardT = CardNews;
                }else if (type == 6) {
                    cardT = CardLabel;
                }else if (type == 8) {
                    cardT = CardTogether;
                }else{
                    cardT = CardImage;
                }
                cardDetailVC.type = cardT;
                cardDetailVC.dataDic = dic;
                if (self.lookId) {
                    cardDetailVC.detailType = DynamicDetailTypeAll;
                    cardDetailVC.enterFromDYList = NO;
                }else{
                    cardDetailVC.detailType = DynamicDetailTypeMine;
                }
                
                [self.navigationController pushViewController:cardDetailVC animated:NO];
                RELEASE_SAFE(cardDetailVC);
            }
                break;
            default:
                break;
        }
    }else{
        [footerVew egoRefreshScrollViewDataSourceDidFinishedLoading:dytableview];
        
    }
}

-(void) reloadMoreList{
    [dytableview reloadData];
    isLoading = NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) dealloc{
    RELEASE_SAFE(dytableview);
    RELEASE_SAFE(_darkCircleDot);
    RELEASE_SAFE(cardsArr);
    
    RELEASE_SAFE(progressHUDTmp);
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"addNewCard" object:nil];
    
    //个人发布的动态
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"deleteMineDynamic" object:nil];
    
    [super dealloc];
}

@end
