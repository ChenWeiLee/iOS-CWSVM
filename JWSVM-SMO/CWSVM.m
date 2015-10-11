//
//  CWSVM.m
//  JWSVM-SMO
//
//  Created by Li Chen wei on 2015/10/11.
//  Copyright © 2015年 Enoch. All rights reserved.
//

#import "CWSVM.h"
#import "CWSMO.h"

@implementation CWSVM
{
    NSMutableArray *w;
    NSNumber *b;
    NSNumber *c;
    
    NSMutableArray *alphaAry;
    NSMutableArray *aryXi, *aryYi;

    
    
    int maxIterations;//最大迭代數

    float toleranceValue; //容忍誤差值
    float oldWa;
    
    BOOL inLoop;
}

- (id)init
{
    self = [super init];
    if (self) {
        w = [NSMutableArray new];
        b = @0;
        toleranceValue =  0.0001;
        
        oldWa = 0.0;
        
        alphaAry = [NSMutableArray new];
        
        
        
    }
    return self;
}

- (void)printW_And_b{
    
    NSLog(@"W:%@ b:%@",w,b);
    
}

- (void)initValue:(int)maxIter
{
    maxIterations = maxIter;
}

- (void)startSMO:(NSMutableArray *)xAry outputYAry:(NSMutableArray *)yAry cValue:(float)cValue
{
    if ([xAry count] == 0 || [yAry count] == 0) {
        return;
    }
    
    
    [alphaAry removeAllObjects];
    
    c = [NSNumber numberWithFloat:cValue];
    aryXi = [xAry copy];
    aryYi = [yAry copy];
    inLoop = YES;
    
    /*
     初始化W 及所有alpha
     */
    
        
    [self updateValueSMO];
}




@end
