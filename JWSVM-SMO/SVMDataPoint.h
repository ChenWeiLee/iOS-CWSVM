//
//  SVMDataPoint.h
//  JWSVM-SMO
//
//  Created by Li Chen wei on 2016/4/28.
//  Copyright © 2016年 Enoch. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CWKernelAlgorithm.h"

@interface SVMDataPoint : NSObject

@property (nonatomic, strong, readonly) NSMutableArray *x;
@property (nonatomic, readonly) NSInteger y;
@property (nonatomic, readonly) double alpha;

- (id)initWithX:(NSMutableArray *)x expectations:(NSInteger)y;

- (double)getErrorWithBias:(double)bias points:(NSMutableArray <SVMDataPoint *>*)points kernelType:(KernelType)type;
- (void)updateAlpha:(double)newAlpha;

@end
