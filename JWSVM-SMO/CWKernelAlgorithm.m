//
//  CWKernelAlgorithm.m
//  JWSVM-SMO
//
//  Created by Li Chen wei on 2016/4/27.
//  Copyright © 2016年 Enoch. All rights reserved.
//

#import "CWKernelAlgorithm.h"

@interface CWKernelAlgorithm ()

@property (strong , nonatomic) NSMutableArray *data1;
@property (strong , nonatomic) NSMutableArray *data2;

@end

@implementation CWKernelAlgorithm

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        //default
        _kernelAlgorithm = KernelTypeLinear;
        _sigma = 1.0;

    }
    return self;
}

- (double)algorithmWithData:(NSMutableArray *)data data2:(NSMutableArray *)data2
{
    
    _data1 = [data mutableCopy];
    _data2 = [data2 mutableCopy];
    
    switch (_kernelAlgorithm) {
        case KernelTypeRBF:
            return [self kernelRBF];
            break;
            
        case KernelTypeLinear:
        default :
            return [self kernelLinear];
            break;
    }
}


- (double)kernelLinear
{
    double linearResult = 0;

    for (int indexM = 0; indexM < [_data1 count]; indexM ++) {
        linearResult = linearResult + [[_data1 objectAtIndex:indexM] doubleValue] * [[_data2 objectAtIndex:indexM] doubleValue];
    }
    
    return linearResult;
}

//https://developer.apple.com/library/mac/documentation/Darwin/Reference/ManPages/man3/exp.3.html
- (double)kernelRBF
{
    double rbfResult = 0;
    
    for (int indexM = 0; indexM < [_data1 count]; indexM ++) {
        rbfResult = rbfResult + powf([[_data1 objectAtIndex:indexM] doubleValue] - [[_data2 objectAtIndex:indexM] doubleValue], 2);
    }
    rbfResult = sqrtf(rbfResult);
    rbfResult = expf(pow(rbfResult, 2)/(-2*pow(_sigma, 2)));
    
    return rbfResult;
}



@end
