//
//  CWSVMManager.h
//  JWSVM-SMO
//
//  Created by Li Chen wei on 2015/12/10.
//  Copyright © 2015年 Enoch. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CWKernelAlgorithm.h"

@protocol CWPattern,CWPatternErrorCalculator;

@interface CWSVMManager : NSObject

@property (nonatomic) NSMutableArray *svms;

@property (nonatomic, readonly) int iteration;
@property (nonatomic, readonly) double toleranceValue;
@property (nonatomic, readonly) double c;
@property (nonatomic, readonly) double sigma;
@property (nonatomic) KernelType kernelType;


- (instancetype)initWithSettingIteration:(int)iter toleranceValue:(double)tolerance cError:(double)cValue;
- (void)configWithKernelType:(KernelType)type sigmaValue:(double)sigmaValue;
- (void)startTraingWithOneToOtherDatas:(NSMutableArray <id<CWPattern,CWPatternErrorCalculator>>*)datas;

@end
