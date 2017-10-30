//
//  PrivateViewController.m
//  livestream
//
//  Created by randy on 2017/8/31.
//  Copyright © 2017年 net.qdating. All rights reserved.
//

#import "PrivateViewController.h"

#import "LSImageViewLoader.h"

#import "LSLoginManager.h"
#import "LiveModule.h"
#import "LSConfigManager.h"
#import "LSImManager.h"

#import "DialogTip.h"
#import "DialogOK.h"
#import "DialogChoose.h"

#import "SetFavoriteRequest.h"

#import "RoomTypeIsFirstManager.h"

#import "RandomGiftModel.h"

@interface PrivateViewController () <LiveViewControllerDelegate, IMLiveRoomManagerDelegate, PlayViewControllerDelegate>
// IM管理器
@property (nonatomic, strong) LSImManager *imManager;
// 资费提示小时计时器
@property (nonatomic, strong) NSTimer *hidenTimer;
// 是否显示资费提示
@property (nonatomic, assign) BOOL isTipShow;
// 接口管理器
@property (nonatomic, strong) LSSessionRequestManager *sessionManager;

#pragma mark - 头像逻辑
@property (atomic, strong) LSImageViewLoader *manImageViewLoader;
@property (atomic, strong) LSImageViewLoader *ladyImageViewLoader;
@property (atomic, strong) LSImageViewLoader *manPreviewImageViewLoader;

#pragma mark - 随机礼物控制
@property (nonatomic, strong) dispatch_queue_t randomGiftQueue;
@property (atomic, strong) NSRunLoop *randomGiftLoop;
@property (atomic, strong) NSTimer *randomGiftTimer;
@property (atomic, strong) NSArray *giftArray;
@property (atomic, assign) NSInteger randomGiftIndex;
// 是否第一次随机礼物
@property (nonatomic, assign) BOOL firstRandom;
#pragma mark - 直播间管理器
// 是否第一次进类型直播间管理器
@property (nonatomic, strong) RoomTypeIsFirstManager *firstManager;
// 对话框控件
@property (nonatomic, strong) DialogTip *dialogTipView;
// 是否能推流
@property (assign) BOOL canPublish;

@end

@implementation PrivateViewController
#pragma mark - 界面初始化
- (void)initCustomParam {
    [super initCustomParam];
    
    NSLog(@"PrivateViewController::initCustomParam()");
    
    srand((unsigned)time(0));
    
    self.isTipShow = NO;
    self.randomGiftIndex = -1;

    self.imManager = [LSImManager manager];
    [self.imManager.client addDelegate:self];

    self.sessionManager = [LSSessionRequestManager manager];
    self.firstManager = [RoomTypeIsFirstManager manager];

    self.manImageViewLoader = [LSImageViewLoader loader];
    self.ladyImageViewLoader = [LSImageViewLoader loader];
    self.manPreviewImageViewLoader = [LSImageViewLoader loader];
    
    self.dialogTipView = [DialogTip dialogTip];
    
    self.firstRandom = YES;
    self.canPublish = NO;
}

- (void)dealloc {
    NSLog(@"PrivateViewController::dealloc()");

    [self.imManager.client removeDelegate:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    self.navigationController.navigationBar.hidden = YES;
    self.navigationController.navigationBar.translucent = NO;
    self.edgesForExtendedLayout = UIRectEdgeNone;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // 刷新头像控件
    [self reloadHeadImageView];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // 开启随机礼物定时器
    [self startRandomGiftTimer];
    
    // 刷新双向视频状态
    [self reloadVideoStatus];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];

    // 停止随机礼物计时
    [self stopRandomGiftTimer];
}

- (void)setupContainView {
    [super setupContainView];

    // 初始化播放界面
    [self setupPlayController];
    // 初始化头部界面
    [self setupHeaderImageView];
    
    // 通知外部处理
    if ([self.delegate respondsToSelector:@selector(onSetupViewController:)]) {
        [self.delegate onSetupViewController:self];
    }
}

- (void)setupPlayController {
    // 输入栏
    self.playVC = [[PlayViewController alloc] initWithNibName:nil bundle:nil];
    self.playVC.delegate = self;
    [self addChildViewController:self.playVC];
    self.playVC.liveRoom = self.liveRoom;

    [self.view addSubview:self.playVC.view];
    [self.playVC.view mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.titleBackGroundView.mas_bottom);
        make.left.equalTo(self.view);
        make.width.equalTo(self.view);
        make.bottom.equalTo(self.view);
    }];

    [self.playVC.liveVC bringSubviewToFrontFromView:self.view];
    [self.view bringSubviewToFront:self.playVC.chooseGiftListView];
    CGRect frame = self.playVC.chooseGiftListView.frame;
    frame.origin.y = SCREEN_HEIGHT;
    self.playVC.chooseGiftListView.frame = frame;

    // 随机礼物
    self.playVC.randomGiftBtnBgWidth.constant = 36;
    self.playVC.randomGiftBtnWidth.constant = -12;
    self.playVC.randomGiftBtnTailing.constant = -10;
    // 直播间风格
    self.playVC.liveVC.roomStyleItem = [[RoomStyleItem alloc] init];
    // 连击礼物
    self.playVC.liveVC.roomStyleItem.comboViewBgImage = [UIImage imageNamed:@"Live_Private_Bg_Combo"];
    // 弹幕
    self.playVC.liveVC.roomStyleItem.barrageBgColor =  Color(53, 75, 158, 0.9);//Color(83, 13, 120, 0.9);
    // 消息列表界面
    self.playVC.liveVC.roomStyleItem.nameColor = COLOR_WITH_16BAND_RGB(0X0CD7DE);
    self.playVC.liveVC.roomStyleItem.followStrColor = COLOR_WITH_16BAND_RGB(0XFF5ABB);
    self.playVC.liveVC.roomStyleItem.sendStrColor = COLOR_WITH_16BAND_RGB(0XFFD205);
    self.playVC.liveVC.roomStyleItem.chatStrColor = [UIColor whiteColor];
    self.playVC.liveVC.roomStyleItem.announceStrColor = COLOR_WITH_16BAND_RGB(0x0cd7de);
    self.playVC.liveVC.roomStyleItem.riderStrColor = COLOR_WITH_16BAND_RGB(0xffd205);
    // 返点界面
    self.playVC.liveVC.rewardedBgView.backgroundColor = COLOR_WITH_16BAND_RGB(0X293FA3);//Color(53, 75, 158, 1.0);
    self.playVC.liveVC.rewardedBgView.hidden = NO;
    self.playVC.liveVC.rewardedBtn.hidden = NO;
    // 视频播放界面
//    self.playVC.liveVC.videoBgImageView.backgroundColor = self.view.backgroundColor;
    // 视频互动界面
    [self.playVC.liveVC showPreview];
    [self.playVC.liveVC.startVideoBtn addTarget:self action:@selector(startVideoAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.playVC.liveVC.stopVideoBtn addTarget:self action:@selector(stopVideoAction:) forControlEvents:UIControlEventTouchUpInside];
    
    // 随机礼物按钮
    [self.playVC.randomGiftBtn addTarget:self action:@selector(randomGiftAction:) forControlEvents:UIControlEventTouchUpInside];
    // 输入栏目
    [self.playVC.chatBtn setImage:[UIImage imageNamed:@"Live_Private_Btn_Chat"]];
    [self.playVC.giftBtn setImage:[UIImage imageNamed:@"Live_Private_Btn_Gift"] forState:UIControlStateNormal];
    // 发送栏目
    [self.playVC.liveSendBarView.sendBtn setImage:[UIImage imageNamed:@"Private_Send_Btn"] forState:UIControlStateNormal];
    self.playVC.liveSendBarView.louderBtnImage = [UIImage imageNamed:@"Private_Pop_Btn"];
    self.playVC.liveSendBarView.placeholderColor = COLOR_WITH_16BAND_RGB(0xc39eff);
    self.playVC.liveSendBarView.inputBackGroundImageView.image = [UIImage imageNamed:@"Private_Input_icon"];
    self.playVC.liveSendBarView.sendBarBgImageView.image = [UIImage imageNamed:@"Live_Private_SendBar_bg"];
    self.playVC.liveSendBarView.inputTextField.textColor = [UIColor whiteColor];
    // 显示表情按钮
    self.playVC.liveSendBarView.emotionBtnWidth.constant = 30;
}

- (void)setupHeaderImageView {
    self.manHeadImageView.layer.cornerRadius = self.manHeadImageView.frame.size.width / 2;
    self.ladyHeadImageView.layer.cornerRadius = self.ladyHeadImageView.frame.size.width / 2;

    // 直播间类型资费提示
    self.tipView = [[ChardTipView alloc] init];
    self.tipView.gotBtn.backgroundColor = COLOR_WITH_16BAND_RGB(0X5D0E86);
    [self.tipView setTipWithRoomPrice:self.liveRoom.imLiveRoom.roomPrice
                              roomTip:NSLocalizedStringFromSelf(@"PUBLIV_TIP")
                           creditText:NSLocalizedStringFromSelf(@"CREDIT_TIP")];

    [self.view addSubview:self.tipView];
    [self.roomTypeImageView sizeToFit];
    [self.tipView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.roomTypeImageView.mas_left);
        make.top.equalTo(self.roomTypeImageView.mas_bottom).offset(2);
        make.width.equalTo(@(self.roomTypeImageView.frame.size.width));
    }];

    // 图片点击事件
    WeakObject(self, weakSelf);
    [self.roomTypeImageView addTapBlock:^(id obj) {
        if (!weakSelf.isTipShow) {
            weakSelf.hidenTimer = [NSTimer scheduledTimerWithTimeInterval:3.0
                                                                   target:weakSelf
                                                                 selector:@selector(hidenChardTip)
                                                                 userInfo:nil
                                                                  repeats:YES];
            [[NSRunLoop currentRunLoop] addTimer:weakSelf.hidenTimer forMode:NSRunLoopCommonModes];
            [weakSelf.view bringSubviewToFront:weakSelf.tipView];
            weakSelf.tipView.hidden = NO;
            weakSelf.isTipShow = YES;
        }
    }];

    // 是否第一次进入该类型直播间 显示资费提示
    BOOL haveCome = [self.firstManager getThisTypeHaveCome:self.liveRoom.roomType];
    if (haveCome) {
        [self.tipView hiddenChardTip];

    } else {
        [self.firstManager comeinLiveRoomWithType:self.liveRoom.roomType HaveComein:YES];
    }

    // 关注
    if (self.liveRoom.imLiveRoom.favorite) {
        self.followBtn.hidden = YES;
    }
}

- (void)setupVideoPreview:(BOOL)start {
    self.playVC.liveVC.previewImageView.hidden = start;
    self.playVC.liveVC.startVideoImageView.hidden = start;
    self.playVC.liveVC.startVideoBtn.hidden = start;
    self.playVC.liveVC.showBtn.enabled = start;
    self.playVC.liveVC.stopVideoBtn.hidden = YES;
    self.playVC.liveVC.muteBtn.hidden = YES;
}

#pragma mark - 按钮事件
- (void)hidenChardTip {
    // TODO:点击资费提示
    self.tipView.hidden = YES;
    if (self.hidenTimer) {
        [self.hidenTimer invalidate];
        self.hidenTimer = nil;
    }
    self.isTipShow = NO;
}

- (IBAction)followAction:(id)sender {
    // TODO:点击关注
    [self sendFollowRequest];
}

- (IBAction)closeAction:(id)sender {
    // TODO:点击关闭界面
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)randomGiftAction:(id)sender {
    // TODO:点击随机礼物
    if( self.randomGiftIndex != -1 ) {
        RandomGiftModel *gift = [self.giftArray objectAtIndex:self.randomGiftIndex];
        [self.playVC.presentView randomSelect:gift.randomInteger];
    }
    
    // 打开礼物界面
    [self.playVC giftAction:sender];
}

- (IBAction)startVideoAction:(id)sender {
    // TODO:点击开始视频互动
    
    // 关闭所有输入
    [self.playVC closeAllInputView];
    
    // 开始视频互动
        if (![LSConfigManager manager].dontShow2WayVideoDialog) {
        DialogChoose *dialogChoose = [DialogChoose dialog];
        NSString *price = [NSString stringWithFormat:@"%.2f", self.liveRoom.imLiveRoom.manPushPrice];
        NSString *tips = [NSString stringWithFormat:NSLocalizedStringFromSelf(@"PUSH_TIPS"), price];
        dialogChoose.tipsLabel.text = tips;
        WeakObject(self, weakObj);
        [dialogChoose showDialog:self.view
                     cancelBlock:^{
                         // 保存参数
                         [LSConfigManager manager].dontShow2WayVideoDialog = dialogChoose.checkBox.on;
                         [[LSConfigManager manager] saveConfigParam];
                     }
                     actionBlock:^{
                         // 保存参数
                         [LSConfigManager manager].dontShow2WayVideoDialog = dialogChoose.checkBox.on;
                         [[LSConfigManager manager] saveConfigParam];
                         
                         // 开始视频互动
                         [weakObj sendVideoControl:YES];
                     }];
    } else {
        // 开始视频互动
        [self sendVideoControl:YES];
    }
}

- (IBAction)stopVideoAction:(id)sender {
    // TODO:点击关闭视频互动
    
    // 关闭所有输入
    [self.playVC closeAllInputView];
    
    // 关闭视频互动
    [self sendVideoControl:NO];
    
    // 隐藏按钮
    self.playVC.liveVC.stopVideoBtn.hidden = YES;
    self.playVC.liveVC.muteBtn.hidden = YES;
}

#pragma mark - 数据逻辑
- (void)reloadHeadImageView {
    // TODO:刷新男士头像J
    [self.manImageViewLoader loadImageWithImageView:self.manHeadImageView options:0 imageUrl:[LSLoginManager manager].loginItem.photoUrl placeholderImage:[UIImage imageNamed:@"Default_Img_Man_Circyle"]];
    // 设置模糊
    UIImage *manBlurImage = [[UIImage imageNamed:@"Default_Img_Man_Square"] blurImageWithRadius:5.0];
    [self.manPreviewImageViewLoader loadImageWithImageView:self.playVC.liveVC.previewImageView options:0 imageUrl:[LSLoginManager manager].loginItem.photoUrl placeholderImage:manBlurImage];
    // TODO:刷新女士头像
    [self.ladyImageViewLoader loadImageWithImageView:self.ladyHeadImageView options:0 imageUrl:self.liveRoom.photoUrl placeholderImage:[UIImage imageNamed:@"Default_Img_Lady_Circyle"]];
    // TODO:刷新亲密度
    NSString *imageName = [NSString stringWithFormat:@"Live_Private_Img_Intimacy_Head_%d", self.liveRoom.imLiveRoom.loveLevel];
    UIImage *image = [UIImage imageNamed:imageName];
    if( image ) {
        self.intimacyImageView.image = image;
    }
}

- (void)reloadVideoStatus {
    NSLog(@"PrivateViewController::reloadVideoStatus( publishUrl : %@ )", self.liveRoom.publishUrl);
    
    if (self.liveRoom.publishUrl.length > 0) {
        // 已经有推流地址, 发送命令
        [self sendVideoControl:YES];
        
    } else {
        // 停止推流
        [self.playVC.liveVC stopPublish];
        
        // 刷新界面
        [self setupVideoPreview:NO];
    }
}

- (void)sendVideoControl:(BOOL)start {
    // 显示菊花
    self.playVC.liveVC.preActivityView.hidden = NO;
    [self.playVC.liveVC.preActivityView startAnimating];

    IMControlType type = start ? IMCONTROLTYPE_START : IMCONTROLTYPE_CLOSE;
    BOOL bFlag = [self.imManager controlManPush:self.liveRoom.roomId
                                        control:type
                                  finishHandler:^(BOOL success, LCC_ERR_TYPE errType, NSString *_Nonnull errMsg, NSArray<NSString *> *_Nonnull manPushUrl) {
                                      dispatch_async(dispatch_get_main_queue(), ^{
                                          // 隐藏菊花
                                          self.playVC.liveVC.preActivityView.hidden = YES;
                                          
                                          if (success) {
                                              BOOL bChange = YES;
                                              BOOL bSuccess = NO;
                                              
                                              if (start) {
                                                  // 开启视频互动成功
                                                  if (manPushUrl.count > 0) {
                                                      bChange = YES;
                                                      bSuccess = YES;
                                                      
                                                      // 开始推流
                                                      self.liveRoom.publishUrlArray = manPushUrl;
                                                      
                                                  } else {
                                                      bChange = NO;

                                                      // 发送关闭命令
                                                      [self.imManager controlManPush:self.liveRoom.roomId control:IMCONTROLTYPE_CLOSE finishHandler:nil];

                                                      // 错误提示
                                                      [self.dialogTipView showDialogTip:self.view tipText:@"发起视频互动失败(没有推流地址)"];
                                                  }
                                              } else {
                                                  // 关闭视频互动成功
//                                                  // 停止推流
//                                                  [self.playVC.liveVC stopPublish];
                                              }

                                              // 改变界面状态
                                              if( bSuccess ) {
                                                  // 开始推流
                                                  [self.playVC.liveVC publish];
                                              } else {
                                                  // 停止推流
                                                  [self.playVC.liveVC stopPublish];
                                              }
                                              
                                              [self setupVideoPreview:bSuccess];
//                                              if (bChange) {
//                                                  self.playVC.liveVC.previewImageView.hidden = start;
//
//                                                  self.playVC.liveVC.startVideoImageView.hidden = start;
//                                                  self.playVC.liveVC.startVideoBtn.hidden = start;
//                                                  self.playVC.liveVC.showBtn.enabled = start;
//
//                                                  [self.playVC.liveVC.preActivityView stopAnimating];
//                                              }
                                              

                                          } else {
                                              // 错误提示
                                              NSString *errStr = start ? @"开启视频互动失败" : @"关闭视频互动失败";
                                              [self.dialogTipView showDialogTip:self.view tipText:errStr];
                                          }
                                      });
                                  }];
    if (!bFlag) {
        self.playVC.liveVC.preActivityView.hidden = YES;
        [self.playVC.liveVC.preActivityView stopAnimating];
    }
}

- (void)sendFollowRequest {
    SetFavoriteRequest *request = [[SetFavoriteRequest alloc] init];
    request.userId = self.liveRoom.userId;
    request.roomId = self.liveRoom.roomId;
    request.isFav = YES;
    request.finishHandler = ^(BOOL success, NSInteger errnum, NSString *_Nonnull errmsg) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                self.followBtn.hidden = YES;
//                [self.playVC.liveVC addAudienceFollowLiverMessage:self.playVC.loginManager.loginItem.nickName];
            }

        });
    };
    [self.sessionManager sendRequest:request];
}


#pragma mark - 播放界面回调
- (void)onReEnterRoom:(PlayViewController *)vc {
    NSLog(@"PrivateViewController::onReEnterRoom()");
    // 清空旧的推流地址
    [self.liveRoom reset];
    
    // 刷新双向视频状态
    [self reloadVideoStatus];
}

#pragma mark - 播放界面回调
- (void)onGetLiveRoomGiftList:(NSArray<LiveRoomGiftModel *> *)array {
    NSLog(@"PrivateViewController::onGetLiveRoomGiftList( count : %lu )", (unsigned long)array.count);
    // 更新礼物数组
    self.giftArray = array;
    
    if (self.firstRandom) {
        self.randomGiftIndex = 0;
        RandomGiftModel *gift = [self.giftArray objectAtIndex:self.randomGiftIndex];
        LiveRoomGiftModel *giftModel = gift.giftModel;
        
        WeakObject(self, weakSelf);
        [[SDWebImageManager sharedManager] loadImageWithURL:[NSURL URLWithString:giftModel.allItem.infoItem.smallImgUrl] options:0 progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
            
        } completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
            if (image) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf.playVC.randomGiftBtn setImage:image forState:UIControlStateNormal];
                });
            }
        }];
        self.firstRandom = NO;
    }
}

#pragma mark - 倒数控制
- (void)randomGiftCountDown {
    dispatch_async(dispatch_get_main_queue(), ^{
        // 修改随机礼物
        UIImage *defaultImage = [UIImage imageNamed:@"Live_Publish_Btn_Gift"];
        [self.playVC.randomGiftBtn setImage:defaultImage forState:UIControlStateNormal];

        if (self.giftArray.count > 0) {
            int randValue = rand();
            self.randomGiftIndex = randValue % self.giftArray.count;
            
            RandomGiftModel *gift = [self.giftArray objectAtIndex:self.randomGiftIndex];
            LiveRoomGiftModel *giftModel = gift.giftModel;
            NSString *url = [[LiveGiftDownloadManager manager] backMiddleImgUrlWithGiftID:giftModel.giftId];
            
            WeakObject(self, weakSelf);
            SDWebImageManager *manager = [SDWebImageManager sharedManager];
            [manager loadImageWithURL:[NSURL URLWithString:url]
                options:0
                progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL *_Nullable targetURL) {

                }
                completed:^(UIImage *_Nullable image, NSData *_Nullable data, NSError *_Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL *_Nullable imageURL) {
                    if (image) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [weakSelf.playVC.randomGiftBtn setImage:image forState:UIControlStateNormal];
                        });
                    }
                }];
        } else {
            // 没有随机礼物
            self.randomGiftIndex = -1;
        }
    });
}

- (void)startRandomGiftTimer {
    NSLog(@"PrivateViewController::startRandomGiftTimer()");

    if (!self.randomGiftQueue) {
        self.randomGiftQueue = dispatch_queue_create("randomGiftQueue", DISPATCH_QUEUE_SERIAL);
    }
    
    dispatch_async(self.randomGiftQueue, ^{
        self.randomGiftLoop = [NSRunLoop currentRunLoop];
        @synchronized(self) {
            if (!self.randomGiftTimer) {
                self.randomGiftTimer = [NSTimer scheduledTimerWithTimeInterval:300
                                                                            target:self
                                                                          selector:@selector(randomGiftCountDown)
                                                                          userInfo:nil
                                                                           repeats:YES];
                [[NSRunLoop currentRunLoop] addTimer:self.randomGiftTimer forMode:NSDefaultRunLoopMode];
            }
        }
        [[NSRunLoop currentRunLoop] run];
    });
}

- (void)stopRandomGiftTimer {
    NSLog(@"PrivateViewController::stopRandomGiftTimer()");
    
    self.randomGiftQueue = nil;
    
    @synchronized(self) {
        [self.randomGiftTimer invalidate];
        self.randomGiftTimer = nil;
    }
    
    if ([self.randomGiftLoop getCFRunLoop]) {
        CFRunLoopStop([self.randomGiftLoop getCFRunLoop]);
    }
}
@end