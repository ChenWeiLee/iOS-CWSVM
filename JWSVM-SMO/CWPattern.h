//
//  SVMDataPoint.h
//  JWSVM-SMO
//
//  Created by Li Chen wei on 2016/4/28.
//  Copyright © 2016年 Enoch. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CWKernelAlgorithm.h"

@protocol CWPattern <NSObject>

@property (nonatomic) double targetValue; //記得要使用@synthesize

- (double)alpha;
- (void)updateAlpha:(double)newAlpha;

- (NSMutableArray <NSNumber *>*)features;

@end

@protocol CWPatternErrorCalculator <NSObject, CWPattern>

- (double)error:(double)bias patterns:(NSMutableArray<id<CWPattern>> *)patterns;

@end

@interface CWPattern: NSObject<CWPatternErrorCalculator, NSCopying>

- (id)initWithX:(NSArray *)x expectations:(NSInteger)y alpha:(double)alpha;

@end
