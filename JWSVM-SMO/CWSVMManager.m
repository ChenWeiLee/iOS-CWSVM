//
//  CWSVMManager.m
//  JWSVM-SMO
//
//  Created by Li Chen wei on 2015/12/10.
//  Copyright © 2015年 Enoch. All rights reserved.
//

#import "CWSVMManager.h"
#import "CWPattern.h"
#import "CWSMO.h"

#import "NSMutableArray+Copy.h"

@implementation CWSVMManager

- (instancetype)init
{
    self = [super init];
    if (self) {
        _svms = [NSMutableArray new];
        
        _iteration = 10000;
        _toleranceValue = 0.0001;
        _c = 1;
        _sigma = 1;
        _kernelType = KernelTypeLinear;
    }
    return self;
}

- (instancetype)initWithSettingIteration:(int)iter toleranceValue:(double)tolerance cError:(double)cValue
{
    self = [self init];
    
    if (self) {
        
        _iteration = iter;
        _toleranceValue = tolerance;
        _c = cValue;
        
    }
    return self;
}

- (void)configWithKernelType:(KernelType)type sigmaValue:(double)sigmaValue
{
    _sigma = sigmaValue;
    _kernelType = type;

}

#pragma mark - Training

- (void)startTraingWithOneToOtherDatas:(NSMutableArray <id<CWPattern,CWPatternErrorCalculator>>*)datas
{
    NSMutableDictionary <NSNumber *, NSMutableArray *> *classifyDictionary = [self classifyDatas:datas];
    if ([classifyDictionary count] < 2) {
        return;
    }
    
    [classifyDictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, NSMutableArray * _Nonnull obj, BOOL * _Nonnull stop) {
        
        NSMutableArray *otherDatas = [datas mutableCopy];
        [otherDatas removeObjectsInArray:obj];

        
        CWSMO *smo = [[CWSMO alloc] initWithKernelMethod:_kernelType sigmaValue:_sigma maxIterations:_iteration relaxation:_c toleranceValue:_toleranceValue];
        [smo startTrainingWithMainData:obj otherData:otherDatas];
        
        [_svms addObject:smo];
    }];
}

- (void)startTraingWithOneToOneDatas:(NSMutableArray <id<CWPattern,CWPatternErrorCalculator>>*)datas
{
    
}

- (NSMutableDictionary <NSNumber *, NSMutableArray *>*)classifyDatas:(NSMutableArray <id<CWPattern,CWPatternErrorCalculator>>*)datas
{
    NSMutableDictionary *classifications = [NSMutableDictionary new];
    
    for ( id<CWPattern,CWPatternErrorCalculator> data in datas ) {
        
        NSNumber *classificationKey = [NSNumber numberWithDouble:data.targetValue];
        
        NSMutableArray *classification = [classifications objectForKey:classificationKey] ?: [NSMutableArray new];
        
        [classification addObject:data];
        
        [classifications setObject:classification forKey:classificationKey];
    }
    
    return classifications;
}


@end
