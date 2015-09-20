//
//  JWSMO_Object.m
//  JWSVM-SMO
//
//  Created by Li Chen wei on 2015/9/5.
//  Copyright (c) 2015年 Enoch. All rights reserved.
//

#import "JWSMO_Object.h"

@implementation JWSMO_Object

- (id)init
{
    self = [super init];
    if (self) {
        w = [NSMutableArray new];
        b = @0;
        maxIterations = 1000;
        toleranceValue =  0.0001;  
        oldAlpha1 = 0.0;
        oldAlpha2 = 0.0;
        oldWa = 0.0;
        
        alphaAry = [NSMutableArray new];
        aryEi = [NSMutableArray new];
        
        unKKTIndexAry = [NSMutableArray new];
        alreadyUpdateAlphaIndexAry = [NSMutableArray new];
        
    }
    return self;
}

- (void)printW_And_b{
    
    NSLog(@"W:%@ b:%@",w,b);
    
}

- (void)initValue:(int)maxIter
{
    maxIterations = maxIter;
}

- (void)startSMO:(NSMutableArray *)xAry outputYAry:(NSMutableArray *)yAry cValue:(float)cValue
{
    [alphaAry removeAllObjects];
    
    c = [NSNumber numberWithFloat:cValue];
    aryXi = [xAry copy];
    aryYi = [yAry copy];
    inputCount = (int)[[xAry objectAtIndex:1] count];
    inLoop = YES;
    
    /*
     初始化W 及所有alpha
     */
    
    [w removeAllObjects];
    for (int inputX = 0; inputX < inputCount; inputX ++) {
        [w addObject:@0];
    }
    
    for (int i = 0; i < [xAry count]; i++) {
        [alphaAry addObject:@0];
    }
    
    [self updateValueSMO];
}

- (void)updateValueSMO
{
    [self checkUnKKTValue:NO];
    alpha1Index = 0;

    [self calculateAllE];


    for (alpha1Index = 0; alpha1Index < [unKKTIndexAry count]; alpha1Index ++) {
        if ([self checkAlreadyUpdateIndex:alpha1Index]) {
            
            [alreadyUpdateAlphaIndexAry addObject:[NSNumber numberWithInt:alpha1Index]];
            
            
            /*
             1、首先在非KKT條件的alpha中尋找使得|E1-E2|最大的樣本；
             
             2、如果1中沒找到則從隨機位置找非KKT條件樣本；
             
             3、如果2中也沒找到，則從整個樣本(包含界上和非界乘子)隨機位置尋找。
             */
            alpha2Index = [self selectAlpha2:alpha1Index arrayEi:aryEi];

            if (alpha2Index == alpha1Index) {
                alpha2Index = arc4random() % ([aryYi count]);
                if (alpha2Index == [[unKKTIndexAry objectAtIndex:alpha1Index] intValue]) {
                    if (alpha2Index != 0) {
                        alpha2Index = alpha2Index - 1;
                    }else{
                        alpha2Index = alpha2Index + 1;
                    }
                }
                [unKKTIndexAry addObject:[NSNumber numberWithInt:alpha2Index]];
                alpha2Index = (int)[unKKTIndexAry count] -1;
            }
            
            
            oldE1 = [self calculateE:[[unKKTIndexAry objectAtIndex:alpha1Index] intValue]];
            oldE2 = [self calculateE:[[unKKTIndexAry objectAtIndex:alpha2Index] intValue]];
            
            [alreadyUpdateAlphaIndexAry addObject:[NSNumber numberWithInt:alpha2Index]];
            
            [self updateAlpha2];
            
            NSLog(@"W:%@ b:%@",w,b);

            
            /*
             1、監視目標函數W(\alpha)的增長率，在它低於某個容忍值時停止訓練，這個條件是最直白和簡單的，但是效果不好；
             
             2、監視原問題的KKT條件，對於凸優化來說它們是收斂的充要條件，但是由於KKT條件本身是比較嚴苛的，所以也需要設定一個容忍值，即所有樣本在容忍值範圍内滿足KKT條件則認為訓練可以結束；
                
             在這邊採用KKT條件為收斂條件
             */
            
//            float newWa = [self calculateWa];
            if ([self checkUnKKTValue:YES] /*|| (oldWa != 0.0 && fabsf((newWa - oldWa)/oldWa) < 0.00001)*/) {
                inLoop = NO;
                break;
            }
            
//            oldWa = newWa;
        }
        
    }
    MaxIterations -- ;
    
    if (MaxIterations == 0) {
        inLoop = NO;
    }
    if (inLoop && [unKKTIndexAry count] != 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateValueSMO];
        });
    }
//（达到最大迭代次数或没有ai得到更新）

   
}


//確認整個樣本中哪些是不符合KKT條件的
// check = YES時 只確認所有樣本是否符合KKT
//       =  NO時 確認樣本不符合並將其index存起來以便更新時使用
- (BOOL)checkUnKKTValue:(BOOL)check; //Step 1
{
    NSNumber *alpha;
    float valueOut , valueWtX = 0.0;
    BOOL unKKT;
    
    if (!check) {
        [unKKTIndexAry removeAllObjects];
        [alreadyUpdateAlphaIndexAry removeAllObjects];
    }
    
    for (int index = 0 ; index < [aryXi count] ; index++) {
        unKKT = NO;
        valueWtX = 0.0;
        alpha = [alphaAry objectAtIndex:index];
        for (int xIndex = 0; xIndex < inputCount; xIndex ++) {
            valueWtX = valueWtX + [[[aryXi objectAtIndex:index] objectAtIndex:xIndex] floatValue] * [[w objectAtIndex:xIndex]  floatValue];
        }
        
        valueOut = [[aryYi objectAtIndex:index] intValue] * (valueWtX + [b floatValue]);
        
        if ([alpha  isEqual: @0]) {
            if ((valueOut + toleranceValue < 1)) {
                unKKT = YES;
            }
        }else if ([alpha  isEqual: c]){
            if (valueOut - toleranceValue > 1) {
                unKKT = YES;
            }
        }else{
            if (fabs(valueOut - 1) > toleranceValue/2 && valueOut != 1) {
                unKKT = YES;
            }
        }
        
        
        if (unKKT) {
            if (check) {
                return NO;
            }else{
                
                [unKKTIndexAry addObject:[NSNumber numberWithInt:index]];
            }
            
        }
        
    }
    
    return ([unKKTIndexAry count] == 0 ? YES : NO);
}

//選取要更新的Alpha2
//挑選最大的|E1 - E2|
- (int)selectAlpha2:(int)alpha1 arrayEi:(NSMutableArray *)arrayEi  //Step 2
{
    float maxAbsEiEj = 0.0;
    int indexalpha2 = 0;
    
    if ([arrayEi count] == 2) {
        indexalpha2 = 1 - alpha1;
    }else{
        for (int updateIndex = 0; updateIndex < [arrayEi count]; updateIndex ++) {
            if (updateIndex != alpha1) {
                
                float absEiEj = fabs([[arrayEi objectAtIndex:alpha1] floatValue] - [[arrayEi objectAtIndex:updateIndex] floatValue]);
                
                if (maxAbsEiEj < absEiEj) {
                    if ([self checkAlreadyUpdateIndex:updateIndex] || ([alreadyUpdateAlphaIndexAry count] == [unKKTIndexAry count])) {
                        maxAbsEiEj = absEiEj;
                        indexalpha2 = updateIndex;
                    }
                }
            }
        }

    }
    
    return indexalpha2;
}

//利用公式來更新我們選取的Alpha2
- (void)updateAlpha2 // Step 3
{
    float alpha2New;
    float K11 = 0, K22 = 0, K12 = 0;
    float alpha2Old = [[alphaAry objectAtIndex:[[unKKTIndexAry objectAtIndex:alpha2Index] intValue]] floatValue];

    oldAlpha2 = alpha2Old;
    
    
    K11 = [self calculateXiTXj:[aryXi objectAtIndex:[[unKKTIndexAry objectAtIndex:alpha1Index] intValue]] j:[aryXi objectAtIndex:[[unKKTIndexAry objectAtIndex:alpha1Index] intValue]]];
    K22 = [self calculateXiTXj:[aryXi objectAtIndex:[[unKKTIndexAry objectAtIndex:alpha2Index] intValue]] j:[aryXi objectAtIndex:[[unKKTIndexAry objectAtIndex:alpha2Index] intValue]]];
    K12 = [self calculateXiTXj:[aryXi objectAtIndex:[[unKKTIndexAry objectAtIndex:alpha1Index] intValue]] j:[aryXi objectAtIndex:[[unKKTIndexAry objectAtIndex:alpha2Index] intValue]]];

    
    alpha2New = alpha2Old + [[aryYi objectAtIndex:[[unKKTIndexAry objectAtIndex:alpha2Index] intValue]] intValue] * (oldE1 - oldE2) / (K11 + K22 - 2*K12);
    
    [alphaAry replaceObjectAtIndex:[[unKKTIndexAry objectAtIndex:alpha2Index] intValue] withObject:[NSNumber numberWithFloat:alpha2New]];
    
    [self checkAlpha2AndUpdateAlpha1:alpha2Index alpha1Index:alpha1Index oldAlpha2:alpha2Old];
    
}

//更新完Alpha2後確認更新的Alpha2是否會我們得範圍
//如大於我們的範圍 Alpha2 = 上限值
//如小於我們的範圍 Alpha2 = 下限值
//確認完後即可更新 Alpha1
- (void)checkAlpha2AndUpdateAlpha1:(int)alpha2 alpha1Index:(int)alpha1 oldAlpha2:(float)alpha2Old //Step 4
{
    float alpha1New;
    float alpha1Value = [[alphaAry objectAtIndex:[[unKKTIndexAry objectAtIndex:alpha1] intValue]] floatValue];
    float alpha2Value = [[alphaAry objectAtIndex:[[unKKTIndexAry objectAtIndex:alpha2] intValue]] floatValue];
    oldAlpha1 = alpha1Value;

    float maxValue,minValue;
    
    if ([[aryYi objectAtIndex:[[unKKTIndexAry objectAtIndex:alpha2] intValue]] intValue] * [[aryYi objectAtIndex:[[unKKTIndexAry objectAtIndex:alpha1] intValue]] intValue] == 1) {
        
        if (0 > alpha2Old + alpha1Value - [c floatValue]) {
            minValue = 0;
        }else{
            minValue = alpha2Old + alpha1Value - [c floatValue];
        }
        
        if ([c floatValue] < alpha2Old + alpha1Value) {
            maxValue = [c floatValue];
        }else{
            maxValue = alpha2Old + alpha1Value;
        }
        
    }else{
        if (0 >= alpha2Old - alpha1Value) {
            minValue = 0;
        }else{
            minValue = alpha2Old - alpha1Value;
        }
        
        if ([c floatValue] <= [c floatValue] + alpha2Old - alpha1Value) {
            maxValue = [c floatValue];
        }else{
            maxValue = [c floatValue] + alpha2Old - alpha1Value;
        }
        
    }
    
    if (alpha2Value > maxValue) {
        [alphaAry replaceObjectAtIndex:[[unKKTIndexAry objectAtIndex:alpha2] intValue] withObject:[NSNumber numberWithFloat:maxValue]];
        alpha2Value = maxValue;
    }else if (alpha2Value < minValue) {
        [alphaAry replaceObjectAtIndex:[[unKKTIndexAry objectAtIndex:alpha2] intValue] withObject:[NSNumber numberWithFloat:minValue]];
        alpha2Value = minValue;
    }
    
    alpha1New = alpha1Value + ([[aryYi objectAtIndex:[[unKKTIndexAry objectAtIndex:alpha2] intValue]] intValue] * [[aryYi objectAtIndex:[[unKKTIndexAry objectAtIndex:alpha1] intValue]] intValue] * (alpha2Old - alpha2Value));
    [alphaAry replaceObjectAtIndex:[[unKKTIndexAry objectAtIndex:alpha1] intValue] withObject:[NSNumber numberWithFloat:alpha1New]];
    
    NSLog(@"alpha1New:%f alpha2New:%f",alpha1New,alpha2Value);
    
    [self updateWbNewAlpha1:alpha1New newAlpha2:alpha2Value];//更新Ｗ及Ｂ

    
}

- (void)updateWbNewAlpha1:(float)alpha1New newAlpha2:(float)alpha2New //Step 5
{
    float updateWi;
    
//      更新W
    
    for (int inputX = 0; inputX < inputCount; inputX ++) {
        
        updateWi = [[w objectAtIndex:inputX] floatValue] + (alpha1New - oldAlpha1) * [[aryYi objectAtIndex:[[unKKTIndexAry objectAtIndex:alpha1Index] intValue]] intValue] * [[[aryXi objectAtIndex:[[unKKTIndexAry objectAtIndex:alpha1Index] intValue]] objectAtIndex:inputX] floatValue] + (alpha2New - oldAlpha2) * [[aryYi objectAtIndex:[[unKKTIndexAry objectAtIndex:alpha2Index] intValue]] intValue] * [[[aryXi objectAtIndex:[[unKKTIndexAry objectAtIndex:alpha2Index] intValue]] objectAtIndex:inputX] floatValue];

        [w replaceObjectAtIndex:inputX withObject:[NSNumber numberWithFloat:updateWi]];
    }
    
//      更新b
    
    float b1New = 0.0,b2New = 0.0;
    float y1a1Value =  [[aryYi objectAtIndex:[[unKKTIndexAry objectAtIndex:alpha1Index] intValue]] floatValue] * (alpha1New - oldAlpha1);
    float y2a2Value =  [[aryYi objectAtIndex:[[unKKTIndexAry objectAtIndex:alpha2Index] intValue]] floatValue] * (alpha2New - oldAlpha2);
    
    
    
    b1New = [b floatValue] - oldE1 - y1a1Value * [self calculateXiTXj:[aryXi objectAtIndex:[[unKKTIndexAry objectAtIndex:alpha1Index] intValue]] j:[aryXi objectAtIndex:[[unKKTIndexAry objectAtIndex:alpha1Index] intValue]]] - y2a2Value * [self calculateXiTXj:[aryXi objectAtIndex:[[unKKTIndexAry objectAtIndex:alpha1Index] intValue]] j:[aryXi objectAtIndex:[[unKKTIndexAry objectAtIndex:alpha2Index] intValue]]];
    
    
    
    b2New = [b floatValue] - oldE2 - y1a1Value * [self calculateXiTXj:[aryXi objectAtIndex:[[unKKTIndexAry objectAtIndex:alpha1Index] intValue]] j:[aryXi objectAtIndex:[[unKKTIndexAry objectAtIndex:alpha2Index] intValue]]] - y2a2Value * [self calculateXiTXj:[aryXi objectAtIndex:[[unKKTIndexAry objectAtIndex:alpha2Index] intValue]] j:[aryXi objectAtIndex:[[unKKTIndexAry objectAtIndex:alpha2Index] intValue]]];

    NSLog(@"B1:%f  B2:%f",b1New,b2New);
    
    if (alpha1New > 0 && alpha1New < [c floatValue]) {
        b = [NSNumber numberWithFloat:b1New];
    }else if (alpha2New > 0 && alpha2New < [c floatValue]){
        b = [NSNumber numberWithFloat:b2New];
    }else{
        b = [NSNumber numberWithFloat:(b2New + b1New)/2];
    }
    
    
    //更新E
    
    [self calculateAllE];
    
}

#pragma mark - Calculate Method

//只計算沒有符合ＫＫＴ條件的Ｅ
- (void)calculateAllE
{
    
    float valueXiTXj = 0.0;
    float valueEi = 0.0;
    
    [aryEi removeAllObjects];
    
    for (int index = 0; index < [unKKTIndexAry count] ; index ++) {
        valueEi = 0.0;
        
        for (int indexJ = 0; indexJ < [aryXi count] ; indexJ ++) {
            valueXiTXj = 0.0;

            for (int xIndex = 0; xIndex < inputCount; xIndex ++) {
                valueXiTXj = valueXiTXj + [[[aryXi objectAtIndex:index] objectAtIndex:xIndex] floatValue] * [[[aryXi objectAtIndex:indexJ] objectAtIndex:xIndex] floatValue];
            }
            
            valueEi = valueEi + ([[alphaAry objectAtIndex:indexJ] floatValue] * [[aryYi objectAtIndex:indexJ] intValue] *  valueXiTXj);
            
        }
        
        valueEi = valueEi + [b floatValue] - [[aryYi objectAtIndex:[[unKKTIndexAry objectAtIndex:index] intValue]] intValue];
        
        [aryEi addObject:[NSNumber numberWithFloat:valueEi]];
    }
    
}

//計算傳入index 的E值
- (float)calculateE:(int)index
{
    float valueXiTXj,valueEi = 0.0;
    for (int indexJ = 0; indexJ < [aryXi count] ; indexJ ++) {
        valueXiTXj = 0.0;
        
        for (int xIndex = 0; xIndex < inputCount; xIndex ++) {
            valueXiTXj = valueXiTXj + [[[aryXi objectAtIndex:index] objectAtIndex:xIndex] floatValue] * [[[aryXi objectAtIndex:indexJ] objectAtIndex:xIndex] floatValue];
        }
        
        valueEi = valueEi + ([[alphaAry objectAtIndex:indexJ] floatValue] * [[aryYi objectAtIndex:indexJ] intValue] *  valueXiTXj);
        
    }
    
    valueEi = valueEi + [b floatValue] - [[aryYi objectAtIndex:index] intValue];
    
    return valueEi;
}

//計算傳入 Xi * Xj 的值

- (float)calculateXiTXj:(NSMutableArray *)xi j:(NSMutableArray *)xj
{
    float xixj = 0.0;
    
        for (int indexM = 0; indexM < [xj count]; indexM ++) {
            xixj = xixj + [[xi objectAtIndex:indexM] floatValue] * [[xj objectAtIndex:indexM] floatValue];
        }
    
    return xixj;
}

//確認是否這次迭代有更新過
- (BOOL)checkAlreadyUpdateIndex:(int)index
{
    for (NSNumber *alreadyIndex in alreadyUpdateAlphaIndexAry) {
        if ([alreadyIndex intValue] == index) {
            return NO;
        }
    }
    return YES;
}

//計算 W(a) 的值

- (float)calculateWa
{
    float sumAlpha = 0.0;
    float sumIJ = 0.0;
    float Wa = 0.0;
    
    for (int i = 0; i < [aryXi count]; i ++) {
        
        sumAlpha = sumAlpha + [[alphaAry objectAtIndex:i] floatValue];
        
        for (int j = 0; j < [aryXi count]; j ++) {
            sumIJ = sumIJ +([[alphaAry objectAtIndex:i] floatValue] * [[alphaAry objectAtIndex:j] floatValue] * [[aryYi objectAtIndex:i] floatValue] * [[aryYi objectAtIndex:i] floatValue] * [self calculateXiTXj:[aryXi objectAtIndex:i] j:[aryXi objectAtIndex:j]]);
        }
    }
    
   return Wa = sumAlpha - sumIJ/2;
}



@end
