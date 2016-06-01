//
//  SVMDataPoint.m
//  JWSVM-SMO
//
//  Created by Li Chen wei on 2016/4/28.
//  Copyright © 2016年 Enoch. All rights reserved.
//

#import "CWPattern.h"


@interface CWPattern ()

@property (nonatomic, strong) CWKernelAlgorithm *kernel;
@property (nonatomic, strong, readonly) NSMutableArray *x;
@property (nonatomic) double alpha;


@end

@implementation CWPattern
@synthesize targetValue = _targetValue;

- (id)initWithX:(NSArray *)x expectations:(NSInteger)y alpha:(double)alpha
{
    self = [super init];
    
    if (self) {
        _x = [x mutableCopy];
        _targetValue = y;
        _alpha = alpha;
        _kernel = [[CWKernelAlgorithm alloc] initWithKernelType:KernelTypeLinear sigma:1.0];
    }
    
    return self;
}


- (double)getErrorWithBias:(double)bias points:(NSMutableArray <CWPattern *>*)points kernelType:(KernelType)type
{
    _kernel.kernelAlgorithm = type;
    double valueEi = 0;
    for (CWPattern *point in points) {
      valueEi  =  valueEi + point.targetValue * point.alpha * [_kernel algorithmWithData:_x data2:point.x];
    }

    valueEi = valueEi + bias - _targetValue;
    return valueEi;
}

- (void)updateAlpha:(double)newAlpha
{
    _alpha = newAlpha;
}

- (BOOL)isEqual:(id)object{
    return [self isEqualToPattern:object];
}

- (BOOL)isEqualToPattern:(CWPattern *)other{
    return ([_x isEqual:other.features]) && (_targetValue == other.targetValue) && (_alpha == other.alpha);
}

#pragma mark - CWPatternErrorCalculator

- (double)error:(double)bias patterns:(NSMutableArray <id<CWPattern>>*)patterns
{
    double valueEi = 0;
    for (id<CWPattern> point in patterns) {
        valueEi  =  valueEi + [point targetValue] * [point alpha] * [_kernel algorithmWithData:_x data2:[point features]];
    }
    
    valueEi = valueEi + bias - _targetValue;
    return valueEi;
}

#pragma mark - CWPattern

- (double)alpha;
{
    return _alpha;
}

- (NSMutableArray <NSNumber *>*)features
{
    return _x;
}

- (id)copyWithZone:(NSZone *)zone{
    
    CWPattern *copy = [[CWPattern allocWithZone:zone] initWithX:self.features expectations:self.targetValue alpha:self.alpha];
    copy.alpha = self.alpha;
    copy.targetValue = self.targetValue;
    copy.kernel = self.kernel;
    copy.kernel.kernelAlgorithm = self.kernel.kernelAlgorithm;
    return copy;
}


@end
