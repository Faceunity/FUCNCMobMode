//
//  CNCLayeredMenuViewController.h
//  CNCMobStreamLibDemo
//
//  Created by 82008223 on 2017/3/28.
//  Copyright © 2017年 chinanetcenter. All rights reserved.
//

#import <UIKit/UIKit.h>
#ifdef CNC_NewInterface
#import "CNCAppUserDataMng.h"
#import "NewInfrastructureViewController.h"
@interface CNCLayeredMenuViewController : NewInfrastructureViewController
#else
#import "InfrastructureViewController.h"
@interface CNCLayeredMenuViewController : InfrastructureViewController {
    
}

#endif

@property (nonatomic) BOOL is_fu;


@end
