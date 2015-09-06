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
        threshold = 0.0000001;
        oldAlpha1 = 0.0;
        oldAlpha1 = 0.0;
        
        alphaAry = [NSMutableArray new];
        aryEi = [NSMutableArray new];
        
        unKKTAryX = [NSMutableArray new];
        unKKTAryY = [NSMutableArray new];
        unKKTAlphaIndexAry = [NSMutableArray new];
        
    }
    return self;
}

- (void)printW_And_b{
    
    NSLog(@"W:%@ b:%@",w,b);
    
}

- (void)startSMO:(NSMutableArray *)xAry OutputYAry:(NSMutableArray *)yAry CValue:(double)cValue
{
    [alphaAry removeAllObjects];
    
    c = [NSNumber numberWithDouble:cValue];
    aryXi = [xAry copy];
    aryYi = [yAry copy];
    inputCount = (int)[[xAry objectAtIndex:1] count];
    
    [self resetW];

    
    for (int i = 0; i < [xAry count]; i++) {
        [alphaAry addObject:@0];
    }
    
    [self updateValueSMO];
}

- (void)updateValueSMO
{
    [self stepOne_unKKTValue:NO];
    alpha1Index = 0;
    threshNewAlpha1 = 0.0;
    threshNewAlpha2 = 0.0;
    


    for (alpha1Index = 0; alpha1Index < [unKKTAryY count]; alpha1Index ++) {
        
        alpha2Index = [self stepTwo_SelectAlpha2:alpha1Index ArrayEi:aryEi];
        
        [self stepThree_Update_Alpha2];
        
        [self stepFive_Update_W_b];//更新Ｗ及Ｂ
        
        NSLog(@"W:%@ b:%@",w,b);

        
        threshNewAlpha1 = threshNewAlpha1 + fabs([[alphaAry objectAtIndex:[[unKKTAlphaIndexAry objectAtIndex:alpha1Index] intValue]] doubleValue] - oldAlpha1);
        thresholdAlpha1 = thresholdAlpha1 + oldAlpha1;
        
        threshNewAlpha2 = threshNewAlpha2 + fabs([[alphaAry objectAtIndex:[[unKKTAlphaIndexAry objectAtIndex:alpha2Index] intValue]] doubleValue] - oldAlpha2);
        thresholdAlpha2 = thresholdAlpha2 + oldAlpha2;

        if ([self stepOne_unKKTValue:YES] ) {
            break;
        }else if( alpha1Index == [unKKTAryY count]-1 ){
            if (threshNewAlpha1/thresholdAlpha1 < threshold && threshNewAlpha2/thresholdAlpha2 < threshold) {
                break;
            }else{
                [self updateValueSMO];
            }
        }
    }
   
}

/*
 
*/
- (BOOL)stepOne_unKKTValue:(BOOL)check;
{
    NSNumber *alpha;
    double valueOut , valueWtX = 0.0;
    BOOL unKKT;
    
    if (!check) {
        [unKKTAryX removeAllObjects];
        [unKKTAryY removeAllObjects];
        [unKKTAlphaIndexAry removeAllObjects];
    }
    
    for (int index = 0 ; index < [aryXi count] ; index++) {
        unKKT = NO;
        alpha = [alphaAry objectAtIndex:index];
        for (int xIndex = 0; xIndex < inputCount; xIndex ++) {
            valueWtX = valueWtX + [[[aryXi objectAtIndex:index] objectAtIndex:xIndex] doubleValue] * [[w objectAtIndex:xIndex]  doubleValue];
        }
        
        valueOut = [[aryYi objectAtIndex:index] doubleValue] * (valueWtX + [b doubleValue]);
        
        if ([alpha  isEqual: @0]) {
            if (valueOut < 1) {
                unKKT = YES;
            }
        }else if ([alpha  isEqual: c]){
            if (valueOut > 1) {
                unKKT = YES;
            }
        }else{
            if (valueOut != 1) {
                unKKT = YES;
            }
        }
        
        if (unKKT) {
            if (check) {
                return NO;
            }else{
                [unKKTAryX addObject:[aryXi objectAtIndex:index]];
                [unKKTAryY addObject:[aryYi objectAtIndex:index]];
                [unKKTAlphaIndexAry addObject:[NSNumber numberWithInt:index]]; //存的是alphaAry的Index
            }
            
        }
        
    }
    return ([unKKTAryY count] == 0 ? YES : NO);
}

- (int)stepTwo_SelectAlpha2:(int)alpha1 ArrayEi:(NSMutableArray *)arrayEi
{
    [self calculateAllE];
    double maxAbsEiEj = 0.0;
    int indexalpha2 = 0;
    
    for (int updateIndex = 0; updateIndex < [arrayEi count]; updateIndex ++) {
        if (updateIndex != alpha1) {
            
            double absEiEj = fabs([[arrayEi objectAtIndex:alpha1] doubleValue] - [[arrayEi objectAtIndex:updateIndex] doubleValue]);
            
            if (maxAbsEiEj < absEiEj) {
                maxAbsEiEj = absEiEj;
                indexalpha2 = updateIndex;
            }
        }
    }
    
    return indexalpha2;
}

- (void)stepThree_Update_Alpha2
{
    double alpha2New;
    double K11 = 0, K22 = 0, K12 = 0;
    double alpha2Old = [[alphaAry objectAtIndex:[[unKKTAlphaIndexAry objectAtIndex:alpha2Index] intValue]] doubleValue];

    oldAlpha2 = alpha2Old;
    
    for (int i = 0; i < inputCount; i++) {
        
        K11 = K11 + [[[unKKTAryX objectAtIndex:alpha1Index] objectAtIndex:i] doubleValue] * [[[unKKTAryX objectAtIndex:alpha1Index] objectAtIndex:i] doubleValue];
        
        K11 = K11 + [[[unKKTAryX objectAtIndex:alpha2Index] objectAtIndex:i] doubleValue] * [[[unKKTAryX objectAtIndex:alpha2Index] objectAtIndex:i] doubleValue];
        
        K11 = K11 + [[[unKKTAryX objectAtIndex:alpha1Index] objectAtIndex:i] doubleValue] * [[[unKKTAryX objectAtIndex:alpha2Index] objectAtIndex:i] doubleValue];
    }
    
    alpha2New = alpha2Old + [[unKKTAryY objectAtIndex:alpha2Index] intValue] * ([[aryEi objectAtIndex:alpha1Index] doubleValue] - [[aryEi objectAtIndex:alpha2Index] doubleValue]) / (K11 + K22 - 2*K12);
    
    [alphaAry replaceObjectAtIndex:[[unKKTAlphaIndexAry objectAtIndex:alpha2Index] intValue] withObject:[NSNumber numberWithDouble:alpha2New]];
    
    [self stepFour_Check_Alpha2_And_Update_Alpha1:alpha2Index Alpha1Index:alpha1Index OldAlpha2:alpha2Old];
    
}

- (void)stepFour_Check_Alpha2_And_Update_Alpha1:(int)alpha2 Alpha1Index:(int)alpha1 OldAlpha2:(double)alpha2Old
{
    double alpha1New;
    double alpha1Value = [[alphaAry objectAtIndex:[[unKKTAlphaIndexAry objectAtIndex:alpha1] intValue]] doubleValue];
    double alpha2Value = [[alphaAry objectAtIndex:[[unKKTAlphaIndexAry objectAtIndex:alpha2] intValue]] doubleValue];
    oldAlpha1 = alpha1Value;

    double maxValue,minValue;
    
    if ([[unKKTAryY objectAtIndex:alpha2] intValue] * [[unKKTAryY objectAtIndex:alpha1] intValue] == 1) {
        
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
        if (0 > alpha2Old - alpha1Value) {
            minValue = 0;
        }else{
            minValue = alpha2Old - alpha1Value;
        }
        
        if ([c doubleValue] < [c doubleValue] + alpha2Old - alpha1Value) {
            maxValue = [c doubleValue];
        }else{
            maxValue = [c doubleValue] + alpha2Old - alpha1Value;
        }
        
    }
    
    if (alpha2Value > maxValue) {
        [alphaAry replaceObjectAtIndex:[[unKKTAlphaIndexAry objectAtIndex:alpha2] intValue] withObject:[NSNumber numberWithDouble:maxValue]];
        alpha2Value = maxValue;
    }else if (alpha2Value < minValue) {
        [alphaAry replaceObjectAtIndex:[[unKKTAlphaIndexAry objectAtIndex:alpha2] intValue] withObject:[NSNumber numberWithDouble:minValue]];
        alpha2Value = minValue;
    }
    
    alpha1New = alpha1Value + ([[unKKTAryY objectAtIndex:alpha2] intValue] * [[unKKTAryY objectAtIndex:alpha1] intValue] * (alpha2Old - alpha2Value));
    [alphaAry replaceObjectAtIndex:[[unKKTAlphaIndexAry objectAtIndex:alpha1] intValue] withObject:[NSNumber numberWithDouble:alpha1New]];
    
}

- (void)stepFive_Update_W_b //w = sum(ai * yi * xi)
{
    double alpha_yi,updateWi;
    [self resetW];
    
    double update_b_max = 0.0,update_b_min = 0.0;
    double valueWiTXj = 0.0;
    BOOL firstUpdate_b_max = YES,firstUpdate_b_min = YES;
    
    for (int index = 0; index < [alphaAry count]; index++) {
        //更新Ｗ
        alpha_yi = [[alphaAry objectAtIndex:index] doubleValue] * [[aryYi objectAtIndex:index] doubleValue];
        
        for (int inputX = 0; inputX < inputCount; inputX ++) {
            
            updateWi = [[w objectAtIndex:inputX] doubleValue] + alpha_yi * [[[aryXi objectAtIndex:index] objectAtIndex:inputX] doubleValue];
            
            [w replaceObjectAtIndex:inputX withObject:[NSNumber numberWithDouble:updateWi]];
        }
        
    }
    
    for (int index = 0; index < [alphaAry count]; index++) {
        //更新b
        valueWiTXj = 0.0;
        for (int xIndex = 0; xIndex < inputCount; xIndex ++) {
            valueWiTXj = valueWiTXj + [[w objectAtIndex:xIndex] doubleValue] * [[[aryXi objectAtIndex:index] objectAtIndex:xIndex] doubleValue];
        }
        
        
        
        if ([[aryYi objectAtIndex:index] intValue] == 1) {
            if (firstUpdate_b_min) {
                update_b_min = valueWiTXj;
                firstUpdate_b_min = NO;
            }else if (!firstUpdate_b_min && update_b_min > valueWiTXj) {
                update_b_min = valueWiTXj;
            }
            
        }else{
            if (firstUpdate_b_max) {
                update_b_max = valueWiTXj;
                firstUpdate_b_max = NO;
            }else if (!firstUpdate_b_max && update_b_max < valueWiTXj) {
                update_b_max = valueWiTXj;
            }
        }

        
    }

    b = [NSNumber numberWithDouble:-(update_b_max+update_b_min)/2];
}

#pragma mark - Calculate Method


//只計算沒有符合ＫＫＴ條件的Ｅ
- (void)calculateAllE
{
    
    double valueXiTXj = 0.0;
    double valueEi = 0.0;
    
    [aryEi removeAllObjects];
    
    for (int index = 0; index < [unKKTAryX count] ; index ++) {
        valueEi = 0.0;
        
        for (int indexJ = 0; indexJ < [unKKTAryX count] ; indexJ ++) {
            valueXiTXj = 0.0;

            for (int xIndex = 0; xIndex < inputCount; xIndex ++) {
                valueXiTXj = valueXiTXj + [[[unKKTAryX objectAtIndex:index] objectAtIndex:xIndex] doubleValue] * [[[unKKTAryX objectAtIndex:indexJ] objectAtIndex:xIndex] doubleValue];
            }
            
            valueEi = valueEi + ([[alphaAry objectAtIndex:indexJ] doubleValue] * [[unKKTAryY objectAtIndex:indexJ] intValue] *  valueXiTXj);
            
        }
        
        valueEi = valueEi + [b doubleValue] - [[unKKTAryY objectAtIndex:index] intValue];
        
        [aryEi addObject:[NSNumber numberWithDouble:valueEi]];
    }
    
}

- (void)resetW
{
    [w removeAllObjects];
    for (int inputX = 0; inputX < inputCount; inputX ++) {
        [w addObject:@0];
    }
}

@end
