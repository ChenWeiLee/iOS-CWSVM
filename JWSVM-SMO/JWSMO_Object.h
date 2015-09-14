//
//  JWSMO_Object.h
//  JWSVM-SMO
//
//  Created by Li Chen wei on 2015/9/5.
//  Copyright (c) 2015年 Enoch. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JWSMO_Object : NSObject
{
    NSMutableArray *w;
    NSNumber *b;
    NSNumber *c;
    
    NSMutableArray *alphaAry;
    NSMutableArray *aryXi, *aryYi;
    NSMutableArray *aryEi;
    
    
    NSMutableArray *unKKTIndexAry; //不符合KKT條件的Index
    NSMutableArray *alreadyUpdateAlphaIndexAry; //迭代已更新過的Index

    int inputCount; // 暫存特徵值有多少個
    int alpha1Index, alpha2Index; //更新的alpha1及alpha2 Index
    
    double oldAlpha1,oldAlpha2; // 暫存更新前的alpha1及alpha2
    double oldE1,oldE2;  // 暫存更新alpha1及alpha2前的E1及E2

    double toleranceValue; //容忍誤差值
    
    BOOL inLoop;
}

- (id)init;
- (void)printW_And_b;
- (void)startSMO:(NSMutableArray *)xAry outputYAry:(NSMutableArray *)yAry cValue:(double)cValue;
- (double)calculateXiTXj:(NSMutableArray *)xi j:(NSMutableArray *)xj;
 @end
