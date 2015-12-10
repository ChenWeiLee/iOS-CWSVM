//
//  CWSMO.m
//  JWSVM-SMO
//
//  Created by Li Chen wei on 2015/12/10.
//  Copyright © 2015年 Enoch. All rights reserved.
//

#import "CWSMO.h"

@implementation CWSMO

#pragma mark - init Default

- (id)init
{
    self = [super init];
    if (self) {
        
        bias = -1;
        kernelMode = LinearKernel;
        sigma = 1.0;
        iteration = 1000;
        toleranceValue = 0.0001;
        cValue = 10;
        _Tag = @"0";
    }
    return self;
}

- (id)initWithKernelMethod:(kernelType)kernelType sigmaValue:(double)sigmaValue maxIterations:(int)iterations relaxation:(double)c;
{
    self = [self init];
    
    if (self) {
        kernelMode = kernelType;
        
        if (sigmaValue <= 0) {
            sigma = 1;
        }else{
            sigma = sigmaValue;
        }
        
        iteration = iterations;
        
        cValue = c;
    }
    
    return self;
}

#pragma mark - Start Class SMO-Step Method



#pragma mark - Start Train SMO-Step Method

- (void)startTrain:(NSMutableArray *)aryXi aryYi:(NSMutableArray *)aryYi
{
    if ([aryXi count] == 0) {
        return;
    }
    
    
    //如果這個CWSMO NSObject是一個新的話，就初始化所有的值
    if (w == nil && bias == -1) {
        w = [NSMutableArray new];
        aryAlphe = [NSMutableArray new];
        
        for (int i = 0; i < [aryXi count]; i ++) {
            [aryAlphe addObject:@"0"];
        }
        
        for (int j = 0; j < [[aryXi objectAtIndex:0] count]; j ++) {
            [w addObject:@"0"];
        }
        bias = 0;
    }
    
    for (int i = 0; i < iteration; i ++) {
        [self alphaOutOfKKT:aryXi aryYi:aryYi aryAlpha:aryAlphe wAry:w b:bias valueC:cValue callBack:^(NSMutableArray *boundaryAry, NSMutableArray *nonBoundAry) {
            
            
            
            
            NSLog(@"123");
            
            
            
            
            
        }];
    }
}


//計算不符合KKT條件的項目，並分別回傳是否有在邊界上
- (void)alphaOutOfKKT:(NSMutableArray *)aryXi aryYi:(NSMutableArray *)aryYi aryAlpha:(NSMutableArray *)alphaAry wAry:(NSMutableArray *)wAry b:(double)b valueC:(double)c callBack:(void(^)(NSMutableArray *boundaryAry, NSMutableArray *nonBoundAry))completeBlock
{
    NSMutableArray *bound = [NSMutableArray new];
    NSMutableArray *nonBound = [NSMutableArray new];
    double valueWtX,valueOut;
    double alpha;
    
    for (int index = 0 ; index < [aryXi count] ; index++) {
        
        valueWtX = 0.0;
        alpha = [[alphaAry objectAtIndex:index] doubleValue];
        for (int xIndex = 0; xIndex < [[aryXi objectAtIndex:0] count]; xIndex ++) {
            valueWtX = valueWtX + [[[aryXi objectAtIndex:index] objectAtIndex:xIndex] doubleValue] * [[wAry objectAtIndex:xIndex]  doubleValue];
        }
        valueOut = [[aryYi objectAtIndex:index] intValue] * (valueWtX + b);
        
        if (alpha  == 0) {
            if ((valueOut + toleranceValue < 1)) {
                [bound addObject:[NSNumber numberWithInt:index]];
            }
        }else if (alpha  == c){
            if (valueOut - toleranceValue > 1) {
                [nonBound addObject:[NSNumber numberWithInt:index]];
            }
        }else{
            if (fabs(valueOut - 1) > toleranceValue/2 && valueOut != 1) {
                [bound addObject:[NSNumber numberWithInt:index]];
            }
        }
    }
    
    completeBlock(bound,nonBound);
}

- (void)getReadyUpadteAlpha1
{
    
}

- (void)getReadyUpadteAlpha2
{
    
}

//更新Alpha2
- (double)updateAlpha2:(double)alpha2 aryX1:(NSMutableArray *)x1 aryX2:(NSMutableArray *)x2 y2:(int)y2 oldE1:(double)oldE1 oldE2:(double)oldE2
{
    double alpha2New;
    double K11 = 0, K22 = 0, K12 = 0;

    K11 = [self calculateXiTXj:x1 j:x1];
    K22 = [self calculateXiTXj:x2 j:x2];
    K12 = [self calculateXiTXj:x1 j:x2];
    
    alpha2New = alpha2 + y2 * (oldE1 - oldE2) / (K11 + K22 - 2*K12);
    
    return alpha2New;
}

//確認新的alpha2在我們要的範圍內
- (double)checkRange:(double)alpha1 alpha2New:(double)alpha2New alpha2Old:(double)alpha2Old y1:(int)y1 y2:(int)y2 cValue:(double)c
{
    double maxValue,minValue;
    
    if ((y1 * y2) == 1) {
        
        if (0 > alpha2Old + alpha1 - c) {
            minValue = 0;
        }else{
            minValue = alpha2Old + alpha1 - c;
        }
        
        if (c < alpha2Old + alpha1) {
            maxValue = c;
        }else{
            maxValue = alpha2Old + alpha1;
        }
        
    }else{
        if (0 >= alpha2Old - alpha1) {
            minValue = 0;
        }else{
            minValue = alpha2Old - alpha1;
        }
        
        if (c <= c + alpha2Old - alpha1) {
            maxValue = c;
        }else{
            maxValue = c + alpha2Old - alpha1;
        }
    }
    
    //如果 alpha2New 不在既定範圍中的話，將 alpha2New 限制在最大可接受值
    if (alpha2New > maxValue) {
        return maxValue;
    }else if (alpha2New < minValue) {
        return minValue;
    }else{
        return alpha2New;
    }
}

//更新Alpha1
- (double)updateAlpha1:(int)alpha1 alpha2:(double)alpha2 alpha2Old:(double)alpha2Old y1:(int)y1 y2:(int)y2
{
    double alpha1New = alpha1 + (y2 * y1 * (alpha2Old - alpha2));

    return alpha1New;
}



#pragma mark - calculate Method

//計算W
- (double)calculateW:(NSMutableArray *)aryXi aryYi:(NSMutableArray *)aryYi aryAlpha:(NSMutableArray *)alphaAry
{
    double sumAlpha = 0.0;
    double sumIJ = 0.0;
    double Wa = 0.0;
    
    for (int i = 0; i < [aryXi count]; i ++) {
        
        sumAlpha = sumAlpha + [[alphaAry objectAtIndex:i] doubleValue];
        
        for (int j = 0; j < [aryXi count]; j ++) {
            sumIJ = sumIJ +([[alphaAry objectAtIndex:i] doubleValue] * [[alphaAry objectAtIndex:j] doubleValue] * [[aryYi objectAtIndex:i] doubleValue] * [[aryYi objectAtIndex:i] doubleValue] * [self calculateXiTXj:[aryXi objectAtIndex:i] j:[aryXi objectAtIndex:j]]);
        }
    }
    
    return Wa = sumAlpha - sumIJ/2;
}

//更新誤差值bias
- (double)updateBias:(double)b aryX1:(NSMutableArray *)x1 aryX2:(NSMutableArray *)x2 y1Value:(double)y1Value y2Value:(double)y2Value alpha1New:(double)alpha1New oldAlpha1:(double)oldAlpha1 alpha2New:(double)alpha2New oldAlpha2:(double)oldAlpha2 oldE1:(double)oldE1 oldE2:(double)oldE2 valueC:(double)c
{
    
    double b1New = 0.0,b2New = 0.0;
    double y1a1Value =  y1Value * (alpha1New - oldAlpha1);
    double y2a2Value =  y2Value * (alpha2New - oldAlpha2);
    
    b1New = b - oldE1 - y1a1Value * [self calculateXiTXj:x1 j:x1] - y2a2Value * [self calculateXiTXj:x1 j:x2];
    
    b2New = b - oldE2 - y1a1Value * [self calculateXiTXj:x1 j:x2] - y2a2Value * [self calculateXiTXj:x2 j:x2];
    
    
    if (alpha1New > 0 && alpha1New < c) {
        return b1New;
    }else if (alpha2New > 0 && alpha2New < c){
        return b2New;
    }else{
        return (b2New + b1New)/2;
    }
}

//核函數Kernel
- (float)calculateXiTXj:(NSMutableArray *)xi j:(NSMutableArray *)xj
{
    float xixj = 0.0;
    
    switch (kernelMode) {
        case LinearKernel:
        {
            for (int indexM = 0; indexM < [xj count]; indexM ++) {
                xixj = xixj + [[xi objectAtIndex:indexM] floatValue] * [[xj objectAtIndex:indexM] floatValue];
            }
        }
            break;
        case RBFKernel:
        {
            //https://developer.apple.com/library/mac/documentation/Darwin/Reference/ManPages/man3/exp.3.html
            for (int indexM = 0; indexM < [xj count]; indexM ++) {
                xixj = xixj + powf([[xi objectAtIndex:indexM] floatValue] - [[xj objectAtIndex:indexM] floatValue], 2);
            }
            xixj = sqrtf(xixj);
            xixj = expf(pow(xixj, 2)/(-2*pow(sigma, 2)));
        }
            break;
        default:
            break;
    }
    
    return xixj;
}

//計算誤差值
- (double)calculateE:(NSMutableArray *)aryXi aryYi:(NSMutableArray *)aryYi aryAlpha:(NSMutableArray *)alphaAry index:(int)index bias:(double)b
{
    double valueXiTXj,valueEi = 0.0;
    for (int indexJ = 0; indexJ < [aryXi count] ; indexJ ++) {
        valueXiTXj = 0.0;
        valueXiTXj  = [self calculateXiTXj:[aryXi objectAtIndex:index] j:[aryXi objectAtIndex:indexJ]];
        
        valueEi = valueEi + ([[alphaAry objectAtIndex:indexJ] floatValue] * [[aryYi objectAtIndex:indexJ] intValue] *  valueXiTXj);
    }
    
    valueEi = valueEi + b - [[aryYi objectAtIndex:index] intValue];
    
    return valueEi;
}

@end
