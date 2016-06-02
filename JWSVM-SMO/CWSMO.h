//
//  CWSMO.h
//  JWSVM-SMO
//
//  Created by Li Chen wei on 2015/12/10.
//  Copyright © 2015年 Enoch. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CWKernelAlgorithm.h"

@protocol CWPattern;
@interface CWSMO : NSObject
{
    NSMutableArray *w;
    double bias;
    NSMutableArray *aryAlphe;
    
    double toleranceValue;
    double cValue;
    int iteration;
}
@property (nonatomic, retain) NSString *tag; //為了多分類用
@property (nonatomic, readonly) double sigma;
@property (nonatomic) KernelType methodType;

- (id)init;
- (id)initWithKernelMethod:(KernelType)kernelType sigmaValue:(double)sigmaValue maxIterations:(int)iterations relaxation:(double)c toleranceValue:(double)toler;
- (void)startTrainingOneToOneWithMainData:(NSMutableArray <id<CWPattern>>*)tPatterns otherData:(NSMutableArray <id<CWPattern>>*)fPatterns;
- (void)startTrainingOneToOtherWithMainData:(NSMutableArray <id<CWPattern>>*)tPatterns otherData:(NSMutableArray <id<CWPattern>>*)fPatterns;

- (void)startTrainingWithMainData:(NSMutableArray <id<CWPattern>>*)tPatterns otherData:(NSMutableArray <id<CWPattern>>*)fPatterns;
- (void)startTrainingWithData:(NSMutableArray <NSMutableArray *>*)aryXi aryYi:(NSMutableArray *)aryYi;

@end
