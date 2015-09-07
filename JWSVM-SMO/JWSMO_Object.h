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
    
    NSMutableArray *unKKTAryX, *unKKTAryY;
    NSMutableArray *unKKTAlphaIndexAry;

    int inputCount;
    int alpha1Index, alpha2Index;
    
    double thresholdAlpha;
    double oldAlpha1,oldAlpha2;
    double threshNewAlpha;

    double threshold;
}

- (id)init;
- (void)printW_And_b;
- (void)startSMO:(NSMutableArray *)xAry OutputYAry:(NSMutableArray *)yAry CValue:(double)cValue;
 @end
