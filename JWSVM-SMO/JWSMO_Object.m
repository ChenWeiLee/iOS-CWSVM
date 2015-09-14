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
        toleranceValue =  0.0001;  
        oldAlpha1 = 0.0;
        oldAlpha1 = 0.0;
        
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

- (void)startSMO:(NSMutableArray *)xAry outputYAry:(NSMutableArray *)yAry cValue:(double)cValue
{
    [alphaAry removeAllObjects];
    
    c = [NSNumber numberWithDouble:cValue];
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
            
            /*
             1、監視目標函數W(\alpha)的增長率，在它低於某個容忍值時停止訓練，這個條件是最直白和簡單的，但是效果不好；
             
             2、監視原問題的KKT條件，對於凸優化來說它們是收斂的充要條件，但是由於KKT條件本身是比較嚴苛的，所以也需要設定一個容忍值，即所有樣本在容忍值範圍内滿足KKT條件則認為訓練可以結束；
                
             在這邊採用KKT條件為收斂條件
             */
            if ([self checkUnKKTValue:YES] ) {
                inLoop = NO;
                break;
            }

        }
        
    }
    
    if (inLoop && [unKKTIndexAry count] != 0) {
        [self updateValueSMO];
    }


   
}


//確認整個樣本中哪些是不符合KKT條件的
// check = YES時 只確認所有樣本是否符合KKT
//       =  NO時 確認樣本不符合並將其index存起來以便更新時使用
- (BOOL)checkUnKKTValue:(BOOL)check; //Step 1
{
    NSNumber *alpha;
    double valueOut , valueWtX = 0.0;
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
            valueWtX = valueWtX + [[[aryXi objectAtIndex:index] objectAtIndex:xIndex] doubleValue] * [[w objectAtIndex:xIndex]  doubleValue];
        }
        
        valueOut = [[aryYi objectAtIndex:index] doubleValue] * (valueWtX + [b doubleValue]);
        
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
    double maxAbsEiEj = 0.0;
    int indexalpha2 = 0;
    
    if ([arrayEi count] == 2) {
        indexalpha2 = 1 - alpha1;
    }else{
        for (int updateIndex = 0; updateIndex < [arrayEi count]; updateIndex ++) {
            if (updateIndex != alpha1) {
                
                double absEiEj = fabs([[arrayEi objectAtIndex:alpha1] doubleValue] - [[arrayEi objectAtIndex:updateIndex] doubleValue]);
                
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
    double alpha2New;
    double K11 = 0, K22 = 0, K12 = 0;
    double alpha2Old = [[alphaAry objectAtIndex:[[unKKTIndexAry objectAtIndex:alpha2Index] intValue]] doubleValue];

    oldAlpha2 = alpha2Old;
    
    
    K11 = [self calculateXiTXj:[aryXi objectAtIndex:[[unKKTIndexAry objectAtIndex:alpha1Index] intValue]] j:[aryXi objectAtIndex:[[unKKTIndexAry objectAtIndex:alpha1Index] intValue]]];
    K22 = [self calculateXiTXj:[aryXi objectAtIndex:[[unKKTIndexAry objectAtIndex:alpha2Index] intValue]] j:[aryXi objectAtIndex:[[unKKTIndexAry objectAtIndex:alpha2Index] intValue]]];
    K12 = [self calculateXiTXj:[aryXi objectAtIndex:[[unKKTIndexAry objectAtIndex:alpha1Index] intValue]] j:[aryXi objectAtIndex:[[unKKTIndexAry objectAtIndex:alpha2Index] intValue]]];

    
    alpha2New = alpha2Old + [[aryYi objectAtIndex:[[unKKTIndexAry objectAtIndex:alpha2Index] intValue]] intValue] * (oldE1 - oldE2) / (K11 + K22 - 2*K12);//還有問題
    
    [alphaAry replaceObjectAtIndex:[[unKKTIndexAry objectAtIndex:alpha2Index] intValue] withObject:[NSNumber numberWithDouble:alpha2New]];
    
    [self checkAlpha2AndUpdateAlpha1:alpha2Index alpha1Index:alpha1Index oldAlpha2:alpha2Old];
    
}

//更新完Alpha2後確認更新的Alpha2是否會我們得範圍
//如大於我們的範圍 Alpha2 = 上限值
//如小於我們的範圍 Alpha2 = 下限值
//確認完後即可更新 Alpha1
- (void)checkAlpha2AndUpdateAlpha1:(int)alpha2 alpha1Index:(int)alpha1 oldAlpha2:(double)alpha2Old //Step 4
{
    double alpha1New;
    double alpha1Value = [[alphaAry objectAtIndex:[[unKKTIndexAry objectAtIndex:alpha1] intValue]] doubleValue];
    double alpha2Value = [[alphaAry objectAtIndex:[[unKKTIndexAry objectAtIndex:alpha2] intValue]] doubleValue];
    oldAlpha1 = alpha1Value;

    double maxValue,minValue;
    
    if ([[aryYi objectAtIndex:[[unKKTIndexAry objectAtIndex:alpha2] intValue]] intValue] * [[aryYi objectAtIndex:[[unKKTIndexAry objectAtIndex:alpha1] intValue]] intValue] == 1) {
        
        if (0 > alpha2Old + alpha1Value - [c doubleValue]) {
            minValue = 0;
        }else{
            minValue = alpha2Old + alpha1Value - [c doubleValue];
        }
        
        if ([c doubleValue] < alpha2Old + alpha1Value) {
            maxValue = [c doubleValue];
        }else{
            maxValue = alpha2Old + alpha1Value;
        }
        
    }else{
        if (0 >= alpha2Old - alpha1Value) {
            minValue = 0;
        }else{
            minValue = alpha2Old - alpha1Value;
        }
        
        if ([c doubleValue] <= [c doubleValue] + alpha2Old - alpha1Value) {
            maxValue = [c doubleValue];
        }else{
            maxValue = [c doubleValue] + alpha2Old - alpha1Value;
        }
        
    }
    
    if (alpha2Value > maxValue) {
        [alphaAry replaceObjectAtIndex:[[unKKTIndexAry objectAtIndex:alpha2] intValue] withObject:[NSNumber numberWithDouble:maxValue]];
        alpha2Value = maxValue;
    }else if (alpha2Value < minValue) {
        [alphaAry replaceObjectAtIndex:[[unKKTIndexAry objectAtIndex:alpha2] intValue] withObject:[NSNumber numberWithDouble:minValue]];
        alpha2Value = minValue;
    }
    
    alpha1New = alpha1Value + ([[aryYi objectAtIndex:[[unKKTIndexAry objectAtIndex:alpha2] intValue]] intValue] * [[aryYi objectAtIndex:[[unKKTIndexAry objectAtIndex:alpha1] intValue]] intValue] * (alpha2Old - alpha2Value));
    [alphaAry replaceObjectAtIndex:[[unKKTIndexAry objectAtIndex:alpha1] intValue] withObject:[NSNumber numberWithDouble:alpha1New]];
    
    
    [self updateWbNewAlpha1:alpha1New newAlpha2:alpha2Value];//更新Ｗ及Ｂ

    
}

- (void)updateWbNewAlpha1:(double)alpha1New newAlpha2:(double)alpha2New //Step 5
{
    double updateWi;
    
//      更新W
    
    for (int inputX = 0; inputX < inputCount; inputX ++) {
        
        updateWi = [[w objectAtIndex:inputX] doubleValue] + (alpha1New - oldAlpha1) * [[aryYi objectAtIndex:[[unKKTIndexAry objectAtIndex:alpha1Index] intValue]] intValue] * [[[aryXi objectAtIndex:[[unKKTIndexAry objectAtIndex:alpha1Index] intValue]] objectAtIndex:inputX] doubleValue] + (alpha2New - oldAlpha2) * [[aryYi objectAtIndex:[[unKKTIndexAry objectAtIndex:alpha2Index] intValue]] intValue] * [[[aryXi objectAtIndex:[[unKKTIndexAry objectAtIndex:alpha2Index] intValue]] objectAtIndex:inputX] doubleValue];

        [w replaceObjectAtIndex:inputX withObject:[NSNumber numberWithDouble:updateWi]];
    }
    
//      更新b
    
    double b1New = 0.0,b2New = 0.0;
    double y1a1Value =  [[aryYi objectAtIndex:[[unKKTIndexAry objectAtIndex:alpha1Index] intValue]] doubleValue] * (alpha1New - oldAlpha1);
    double y2a2Value =  [[aryYi objectAtIndex:[[unKKTIndexAry objectAtIndex:alpha2Index] intValue]] doubleValue] * (alpha2New - oldAlpha2);
    
    
    
    b1New = [b doubleValue] - oldE1 - y1a1Value * [self calculateXiTXj:[aryXi objectAtIndex:[[unKKTIndexAry objectAtIndex:alpha1Index] intValue]] j:[aryXi objectAtIndex:[[unKKTIndexAry objectAtIndex:alpha1Index] intValue]]] - y2a2Value * [self calculateXiTXj:[aryXi objectAtIndex:[[unKKTIndexAry objectAtIndex:alpha1Index] intValue]] j:[aryXi objectAtIndex:[[unKKTIndexAry objectAtIndex:alpha2Index] intValue]]];
    
    
    
    b2New = [b doubleValue] - oldE2 - y1a1Value * [self calculateXiTXj:[aryXi objectAtIndex:[[unKKTIndexAry objectAtIndex:alpha1Index] intValue]] j:[aryXi objectAtIndex:[[unKKTIndexAry objectAtIndex:alpha2Index] intValue]]] - y2a2Value * [self calculateXiTXj:[aryXi objectAtIndex:[[unKKTIndexAry objectAtIndex:alpha2Index] intValue]] j:[aryXi objectAtIndex:[[unKKTIndexAry objectAtIndex:alpha2Index] intValue]]];

    
    if (alpha1New != 0 && alpha1New != [c doubleValue]) {
        b = [NSNumber numberWithDouble:b1New];
    }else if (alpha2New != 0 && alpha2New != [c doubleValue]){
        b = [NSNumber numberWithDouble:b2New];
    }else{
        b = [NSNumber numberWithDouble:(b2New + b1New)/2];
    }
    
    
    //更新E
    
    [self calculateAllE];
    
}

#pragma mark - Calculate Method

//只計算沒有符合ＫＫＴ條件的Ｅ
- (void)calculateAllE
{
    
    double valueXiTXj = 0.0;
    double valueEi = 0.0;
    
    [aryEi removeAllObjects];
    
    for (int index = 0; index < [unKKTIndexAry count] ; index ++) {
        valueEi = 0.0;
        
        for (int indexJ = 0; indexJ < [aryXi count] ; indexJ ++) {
            valueXiTXj = 0.0;

            for (int xIndex = 0; xIndex < inputCount; xIndex ++) {
                valueXiTXj = valueXiTXj + [[[aryXi objectAtIndex:index] objectAtIndex:xIndex] doubleValue] * [[[aryXi objectAtIndex:indexJ] objectAtIndex:xIndex] doubleValue];
            }
            
            valueEi = valueEi + ([[alphaAry objectAtIndex:indexJ] doubleValue] * [[aryYi objectAtIndex:indexJ] intValue] *  valueXiTXj);
            
        }
        
        valueEi = valueEi + [b doubleValue] - [[aryYi objectAtIndex:[[unKKTIndexAry objectAtIndex:index] intValue]] intValue];
        
        [aryEi addObject:[NSNumber numberWithDouble:valueEi]];
    }
    
}

//計算傳入index 的E值
- (double)calculateE:(int)index
{
    double valueXiTXj,valueEi = 0.0;
    for (int indexJ = 0; indexJ < [aryXi count] ; indexJ ++) {
        valueXiTXj = 0.0;
        
        for (int xIndex = 0; xIndex < inputCount; xIndex ++) {
            valueXiTXj = valueXiTXj + [[[aryXi objectAtIndex:index] objectAtIndex:xIndex] doubleValue] * [[[aryXi objectAtIndex:indexJ] objectAtIndex:xIndex] doubleValue];
        }
        
        valueEi = valueEi + ([[alphaAry objectAtIndex:indexJ] doubleValue] * [[aryYi objectAtIndex:indexJ] intValue] *  valueXiTXj);
        
    }
    
    valueEi = valueEi + [b doubleValue] - [[aryYi objectAtIndex:index] intValue];
    
    return valueEi;
}

//計算傳入 Xi * Xj 的值

- (double)calculateXiTXj:(NSMutableArray *)xi j:(NSMutableArray *)xj
{
    double xixj = 0.0;
    
        for (int indexM = 0; indexM < [xj count]; indexM ++) {
            xixj = xixj + [[xi objectAtIndex:indexM] doubleValue] * [[xj objectAtIndex:indexM] doubleValue];
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

- (double)calculateWa
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



@end
