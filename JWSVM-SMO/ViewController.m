//
//  ViewController.m
//  JWSVM-SMO
//
//  Created by Li Chen wei on 2015/9/5.
//  Copyright (c) 2015年 Enoch. All rights reserved.
//

#import "ViewController.h"
#import "JWSMO_Object.h"

#import "CWSVMManager.h"

#import "CWSMO.h"
#import "CWPattern.h"

@interface ViewController ()
{
    JWSMO_Object *obj_SMO;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    datas = [NSMutableArray new];
    
    CWPattern *patttern1 = [[CWPattern alloc] initWithX:@[@0,@5] expectations:-1 alpha:0.0];
    CWPattern *patttern2 = [[CWPattern alloc] initWithX:@[@0,@0] expectations:-1 alpha:0.0];
    CWPattern *patttern3 = [[CWPattern alloc] initWithX:@[@2,@2] expectations:-1 alpha:0.0];
    CWPattern *patttern4 = [[CWPattern alloc] initWithX:@[@2,@0] expectations:1 alpha:0.0];
    CWPattern *patttern5 = [[CWPattern alloc] initWithX:@[@3,@0] expectations:1 alpha:0.0];
    
    [datas addObjectsFromArray:@[patttern1, patttern2, patttern3, patttern4, patttern5]];
    
    CWSVMManager *svm = [[CWSVMManager alloc] initWithSettingIteration:10000 toleranceValue:0.0001 cError:1];
    [svm startTraingWithOneToOtherDatas:datas];
    
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
