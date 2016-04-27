//
//  CWSMO.m
//  JWSVM-SMO
//
//  Created by Li Chen wei on 2015/12/10.
//  Copyright © 2015年 Enoch. All rights reserved.
//

#import "CWSMO.h"

#import "CWKernelAlgorithm.h"

@interface CWSMO ()

@property (nonatomic, strong) CWKernelAlgorithm *kernelMethod;
@property (nonatomic, strong) NSMutableArray <NSMutableArray *>*points;
@property (nonatomic, strong) NSMutableArray *expectations;

@end

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
        
        bound = [NSMutableArray new];
        nonBound = [NSMutableArray new];
        _kernelMethod = [CWKernelAlgorithm new];
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

- (void)startTrain:(NSMutableArray <NSMutableArray *>*)aryXi aryYi:(NSMutableArray *)aryYi
{
    if ([aryXi count] == 0) {
        return;
    }
    
    _points = [aryXi mutableCopy];
    _expectations = [aryYi mutableCopy];
    
    BOOL stopSMO = NO;
    BOOL inSMOStop = NO;

    //如果這個CWSMO NSObject是一個新的話，就初始化所有的值
    if (w == nil && bias == -1) {
        w = [NSMutableArray new];
        aryAlphe = [NSMutableArray new];
        bias = 0;
        
        for (int i = 0; i < [_points count]; i = i + 1) {
            [aryAlphe addObject:@"0"];
        }
        
        for (int j = 0; j < [[_points objectAtIndex:0] count]; j = j + 1) {
            [w addObject:@"0"];
        }
    }
    

    //外圍迭代，當迭代到最大還未收斂，則強制收斂
    for (int sprint = 0; sprint < iteration; sprint = sprint +1) {
        
        //這邊採用啟發式方法來做
        for (int tour = 0; tour < [_points count] ; tour = tour +1) {
            
            NSMutableArray *xi = [_points objectAtIndex:tour];
            NSInteger yi = [[_expectations objectAtIndex:tour] integerValue];
            double alphai = [[aryAlphe objectAtIndex:tour] doubleValue];
            
            //尋找到第一筆不符合KKT條件
            if ([self checkKKTWithPoint:xi y:yi alpha:alphai]) {
                
                int indexj = tour + 1;
                
                if (![xi isEqual:[aryXi lastObject]]) {
                    //如果不為最後一筆的話
                    indexj = [self selectMaxErrorIndexWithEi:[self calculateE:xi y:yi alpha:alphai] startIndex:tour +1];
                }else{
                    //如果為最後一筆的話，就隨機挑點來當作第二調整點
                    
                }
                
                
                
                
            }
            
        }
        
    }
    

}

//確認該點是否符合KKT條件
- (BOOL)checkKKTWithPoint:(NSMutableArray *)x y:(NSInteger)y alpha:(double)alpha
{
    double valueWtX = 0.0,valueOut = 0.0;
    
    for (int index = 0; index < [[x objectAtIndex:0] count]; index = index + 1) {
        valueWtX = valueWtX + [[x objectAtIndex:index] doubleValue] * [[w objectAtIndex:index]  doubleValue];
    }
    valueOut = y * (valueWtX + bias);
    
    if (alpha  == 0 && valueOut + toleranceValue > 1) {
        return YES;
    }else if (alpha  == cValue && valueOut - toleranceValue < 1){
        return YES;
    }else if (alpha > 0 && alpha < cValue && fabs(valueOut - 1) < toleranceValue  ){
        return YES;
    }else{
        return NO;
    }
    
}
//找出Array中符合誤差值|E1-E2|最大者

- (int)selectMaxErrorIndexWithEi:(double)ei startIndex:(int)startIndex{
    
    int maxIndex = startIndex;
    double maxError = 0.0, tempError = 0.0;
    
    for (int index = startIndex; index < [_points count] ; index = index + 1) {
        
        double pointError = [self calculateE:[_points objectAtIndex:index] y:[[_expectations objectAtIndex:index] intValue] alpha:[[aryAlphe objectAtIndex:index] doubleValue]];
        tempError = fabs(pointError - ei);
        
        if (tempError > maxError) {
            maxError = tempError;
            maxIndex = index;
        }
    }

    return maxIndex;
}

//計算誤差值
- (double)calculateE:(NSMutableArray *)x y:(NSInteger)y alpha:(double)alpha
{
    double valueXiTXj,valueEi = 0.0;
    for (int index = 0; index < [x count] ; index ++) {
        valueXiTXj = 0.0;
        valueXiTXj  = [_kernelMethod algorithmWithData:x data2:x];
        
        valueEi = valueEi + (alpha * y *  valueXiTXj);
    }
    
    valueEi = valueEi + bias - y;
    
    return valueEi;
}



/**Old Method**/

//計算不符合KKT條件的項目，並分別回傳是否有在邊界上
- (BOOL)alphaOutOfKKT:(NSMutableArray *)aryXi aryYi:(NSMutableArray *)aryYi aryAlpha:(NSMutableArray *)alphaAry wAry:(NSMutableArray *)wAry b:(double)b valueC:(double)c
{
    double valueWtX,valueOut;
    double alpha;
 
    [nonBound removeAllObjects];
    [bound removeAllObjects];
    
    
    //nonBound：在aryXi 不符合KKT條件並且不在邊界上的index
    //bound：在aryXi 不符合KKT條件並且在邊界上的index
    for (int index = 0 ; index < [aryXi count] ; index++) {
        
        valueWtX = 0.0;
        alpha = [[alphaAry objectAtIndex:index] doubleValue];
        for (int xIndex = 0; xIndex < [[aryXi objectAtIndex:0] count]; xIndex ++) {
            valueWtX = valueWtX + [[[aryXi objectAtIndex:index] objectAtIndex:xIndex] doubleValue] * [[wAry objectAtIndex:xIndex]  doubleValue];
        }
        valueOut = [[aryYi objectAtIndex:index] intValue] * (valueWtX + b);
        
        if (alpha  == 0 && valueOut + toleranceValue > 1) {
            
        }else if (alpha  == c && valueOut - toleranceValue < 1){
            
        }else if (alpha > 0 && alpha < c && fabs(valueOut - 1) < toleranceValue  ){
            
        }else{
            if (alpha > 0 && alpha < c ){
                [nonBound addObject:[NSNumber numberWithInt:index]];
            }else{
                [bound addObject:[NSNumber numberWithInt:index]];
            }
        }
    
        
//        if ((alpha  == 0 && valueOut + toleranceValue < 1) || (alpha  == c && valueOut - toleranceValue > 1)) {
//            [bound addObject:[NSNumber numberWithInt:index]];
//
//        }else if (fabs(valueOut - 1) < toleranceValue )
//        {
//             if (alpha <= 0 && alpha >= c ){
//                [nonBound addObject:[NSNumber numberWithInt:index]];
//            }
//        }else if (fabs(valueOut - 1) > toleranceValue ){
//            if (alpha > 0 && alpha < c ){
//                [nonBound addObject:[NSNumber numberWithInt:index]];
//            }
//        }
    }
    
    if ([bound count] + [nonBound count] == 0) {
        return YES;
    }else{
        return NO;
    }
   
}

- (BOOL)checkAlphaOutOfKKT:(NSMutableArray *)aryXi aryYi:(NSMutableArray *)aryYi aryAlpha:(NSMutableArray *)alphaAry wAry:(NSMutableArray *)wAry b:(double)b valueC:(double)c
{
    double valueWtX,valueOut;
    double alpha;
    
    
    
    
    //nonBound：在aryXi 不符合KKT條件並且不在邊界上的index
    //bound：在aryXi 不符合KKT條件並且在邊界上的index
    for (int index = 0 ; index < [aryXi count] ; index++) {
        
        valueWtX = 0.0;
        alpha = [[alphaAry objectAtIndex:index] doubleValue];
        for (int xIndex = 0; xIndex < [[aryXi objectAtIndex:0] count]; xIndex ++) {
            
            
            valueWtX = valueWtX + [[[aryXi objectAtIndex:index] objectAtIndex:xIndex] doubleValue] * [[wAry objectAtIndex:xIndex]  doubleValue];
        }
        valueOut = [[aryYi objectAtIndex:index] intValue] * (valueWtX + b);
        
        if (alpha  == 0 && valueOut + toleranceValue > 1) {
            
        }else if (alpha  == c && valueOut - toleranceValue < 1){
            
        }else if (alpha > 0 && alpha < c && fabs(valueOut - 1) < toleranceValue  ){
            
        }else{
            if (alpha > 0 && alpha < c ){
                return NO;
            }else{
                return NO;
            }
        }
        
        

    }
    return YES;

    
}

- (int)getReadyUpadteAlpha1:(NSMutableArray *)unKKTAry aryXi:(NSMutableArray *)aryXi aryYi:(NSMutableArray *)aryYi alpheAry:(NSMutableArray *)alpheAry
{
    double maxEi = 0,tempValue;
    int aryIndex = 0;
    
    //計算擁有最大的|Ei|
    for (int index = 0; index < [unKKTAry count]; index++) {
        
        tempValue = [self calculateE:aryXi aryYi:aryYi aryAlpha:alpheAry index:[[unKKTAry objectAtIndex:index] intValue] bias:bias];
        
        if (fabs(tempValue) > maxEi) {
            aryIndex = index;
        }
    }
    
    //回傳他在傳進來unKKTAry中的Index
    return aryIndex;
}

- (int)getReadyUpadteAlpha2:(NSMutableArray *)unKKTAry aryXi:(NSMutableArray *)aryXi aryYi:(NSMutableArray *)aryYi alpheAry:(NSMutableArray *)alpheAry alpheI:(int)alpheI
{
    double maxEiEj = 0,tempEiEj,tempEiValue,tempEjValue;
    int aryIndex = 0;
    
    tempEiValue = [self calculateE:aryXi aryYi:aryYi aryAlpha:alpheAry index:alpheI bias:bias];

    
    for (int index = 0; index < [unKKTAry count]; index++) {
        
        tempEjValue = [self calculateE:aryXi aryYi:aryYi aryAlpha:alpheAry index:[[unKKTAry objectAtIndex:index] intValue] bias:bias];
        
        tempEiEj = fabs(tempEiValue - tempEjValue);

        
        if (tempEiEj > maxEiEj) {
            maxEiEj = fabs(tempEiValue - tempEjValue);
            aryIndex = index;
        }
    }
    
    return aryIndex;
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
        
        if (0 > alpha2Old + alpha1 + c) {
            minValue = 0;
        }else{
            minValue = alpha2Old + alpha1 + c;
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

//計算Wa
- (double)calculateWa:(NSMutableArray *)aryXi aryYi:(NSMutableArray *)aryYi aryAlpha:(NSMutableArray *)alphaAry
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

//更新W
- (NSMutableArray *)updateW:(NSMutableArray *)wAry alpha1New:(double)alpha1New oldAlpha1:(double)oldAlpha1 alpha2New:(double)alpha2New oldAlpha2:(double)oldAlpha2 yi:(int)yi xi:(NSMutableArray *)xi yj:(int)yj xj:(NSMutableArray *)xj
{
    double updateWi = 0.0;
    NSMutableArray *wNew = [wAry mutableCopy];
    
    for (int inputX = 0; inputX < [wAry count]; inputX ++) {
        
        updateWi = [[wNew objectAtIndex:inputX] doubleValue] + (alpha1New - oldAlpha1) * yi * [[xi objectAtIndex:inputX] doubleValue] + (alpha2New - oldAlpha2) * yj * [[xj objectAtIndex:inputX] doubleValue];
        
        [wNew replaceObjectAtIndex:inputX withObject:[NSNumber numberWithFloat:updateWi]];
    }
    
    return wNew;
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
        valueXiTXj  = [self calculateXiTXj:[aryXi objectAtIndex:indexJ] j:[aryXi objectAtIndex:index]];
        
        valueEi = valueEi + ([[alphaAry objectAtIndex:indexJ] doubleValue] * [[aryYi objectAtIndex:indexJ] intValue] *  valueXiTXj);
    }
    
    valueEi = valueEi + b - [[aryYi objectAtIndex:index] intValue];
    
    return valueEi;
}

@end
