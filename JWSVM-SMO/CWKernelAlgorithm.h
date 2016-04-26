//
//  CWKernelAlgorithm.h
//  JWSVM-SMO
//
//  Created by Li Chen wei on 2016/4/27.
//  Copyright © 2016年 Enoch. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, KernelType) {
    KernelTypeLinear,
    KernelTypeRBF
};


@interface CWKernelAlgorithm : NSObject

@property (nonatomic) KernelType kernelAlgorithm;
@property (nonatomic) double sigma;

- (double)algorithmWithData:(NSMutableArray *)data data2:(NSMutableArray *)data2;

@end
