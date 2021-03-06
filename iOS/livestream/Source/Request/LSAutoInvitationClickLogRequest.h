//
//  LSAutoInvitationClickLogRequest.h
//  dating
//   8.10.自动邀请hangout点击记录
//  Created by Alex on 19/1/22
//  Copyright © 2019年 qpidnetwork. All rights reserved.
//

#import "LSSessionRequest.h"

@interface LSAutoInvitationClickLogRequest : LSSessionRequest
/**
 * anchorId                         主播ID
 */
@property (nonatomic, copy) NSString* _Nullable anchorId;
/**
 * isAuto 是否自动（1：自动  0：手动）
 */
@property (nonatomic, assign) BOOL isAuto;
@property (nonatomic, strong) AutoInvitationClickLogFinishHandler _Nullable finishHandler;
@end
