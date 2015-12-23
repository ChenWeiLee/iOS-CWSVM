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
        
        bound = [NSMutableArray new];
        nonBound = [NSMutableArray new];
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
    
    __block BOOL stopSMO = NO;
    __block BOOL inSMOStop = NO;

    //如果這個CWSMO NSObject是一個新的話，就初始化所有的值
    if (w == nil && bias == -1) {
        w = [NSMutableArray new];
        aryAlphe = [NSMutableArray new];
        bias = 0;
    }
    
    
    for (int i = 0; i < [aryXi count]; i ++) {
        [aryAlphe addObject:@"0"];
    }
    
    for (int j = 0; j < [[aryXi objectAtIndex:0] count]; j ++) {
        [w addObject:@"0"];
    }

    /*
    for (int i = 0; i < iteration; i ++) {
        stopSMO = [self alphaOutOfKKT:aryXi aryYi:aryYi aryAlpha:aryAlphe wAry:w b:bias valueC:cValue];
        
        if (stopSMO) {
            break;
        }else{
            
            int tempAlpheAryIndex;
            int i = 0, j;
            int yi,yj;
            double alphe1New,alphe2New;
            double alphe1Old,alphe2Old;
            double oldE1,oldE2;
            
            //找出最適合的Alphe 1 在aryXi中的index
            if ([nonBound count] != 0) {
                tempAlpheAryIndex = [self getReadyUpadteAlpha1:nonBound aryXi:aryXi aryYi:aryYi alpheAry:aryAlphe];
                i = [[nonBound objectAtIndex:tempAlpheAryIndex] intValue];
                [nonBound removeObjectAtIndex:tempAlpheAryIndex];
                
            }else{
                tempAlpheAryIndex = [self getReadyUpadteAlpha1:bound aryXi:aryXi aryYi:aryYi alpheAry:aryAlphe];
                i = [[bound objectAtIndex:tempAlpheAryIndex] intValue];
                [bound removeObjectAtIndex:tempAlpheAryIndex];
            }
            
            //找出最適合的Alphe 2 在aryXi中的index
            if ([nonBound count] != 0) {
                tempAlpheAryIndex = [self getReadyUpadteAlpha2:nonBound aryXi:aryXi aryYi:aryYi alpheAry:aryAlphe alpheI:i];
                j = [[nonBound objectAtIndex:tempAlpheAryIndex] intValue];
                //                    [nonBound removeObjectAtIndex:tempAlpheAryIndex];
                
            }
            else if([bound count] != 0){
                
                tempAlpheAryIndex = [self getReadyUpadteAlpha2:bound aryXi:aryXi aryYi:aryYi alpheAry:aryAlphe alpheI:i];
                j = [[bound objectAtIndex:tempAlpheAryIndex] intValue];
                //                    [bound removeObjectAtIndex:tempAlpheAryIndex];
                
            }
            else{//當Alphe 1挑完後全部淨空，沒有剩下不符KKT條件的部分
                j = arc4random() % ([aryYi count]);
                if (i == j) {
                    if (i != [aryYi count]-1) {
                        j = j+1;
                    }else{
                        j = j-1;
                    }
                }
            }
            
            
            yi = [[aryYi objectAtIndex:i] intValue];
            yj = [[aryYi objectAtIndex:j] intValue];
            
            alphe1Old = [[aryAlphe objectAtIndex:i] doubleValue];
            alphe2Old = [[aryAlphe objectAtIndex:j] doubleValue];
            
            oldE1 = [self calculateE:aryXi aryYi:aryYi aryAlpha:aryAlphe index:i bias:bias];
            oldE2 = [self calculateE:aryXi aryYi:aryYi aryAlpha:aryAlphe index:j bias:bias];
            
            //先更新Alphe 2
            alphe2New = [self updateAlpha2:alphe2Old aryX1:[aryXi objectAtIndex:i] aryX2:[aryXi objectAtIndex:j] y2:yj oldE1:oldE1 oldE2:oldE2];
            //確認更新的Alphe 2在範圍內
            alphe2New = [self checkRange:alphe1Old alpha2New:alphe2New alpha2Old:alphe2Old y1:yi y2:yj cValue:cValue];
            //更新Alphe 1
            alphe1New = [self updateAlpha1:alphe1Old alpha2:alphe2New alpha2Old:alphe2Old y1:yi y2:yj];
            
            if (alphe1Old == alphe1New && alphe2Old == alphe2New){
                break;
            }
            
            //更新 aryAlphe中的 Alphe
            [aryAlphe replaceObjectAtIndex:i withObject:[NSNumber numberWithDouble:alphe1New]];
            [aryAlphe replaceObjectAtIndex:j withObject:[NSNumber numberWithDouble:alphe2New]];
            
            //更新誤差bais
            bias = [self updateBias:bias aryX1:[aryXi objectAtIndex:i] aryX2:[aryXi objectAtIndex:j] y1Value:yi y2Value:yj alpha1New:alphe1New oldAlpha1:alphe1Old alpha2New:alphe2New oldAlpha2:alphe2Old oldE1:oldE1 oldE2:oldE2 valueC:cValue];
            //更新Ｗ
//            w = [[self updateW:w alpha1New:alphe1New oldAlpha1:alphe1Old alpha2New:alphe2New oldAlpha2:alphe2Old yi:yi xi:[aryXi objectAtIndex:i] yj:yj xj:[aryXi objectAtIndex:j]] mutableCopy];
            
            NSLog(@"Alphe1:%d Alpha2:%d",i,j);
            NSLog(@"alphe1Old:%f alphe1New:%f",alphe1Old,alphe1New);
            NSLog(@"alphe2Old:%f alphe2New:%f",alphe2Old,alphe2New);
            NSLog(@"Bias:%f",bias);
            NSLog(@"W:%@",w);
            NSLog(@"====nonBoundaryAry:%ld BoundAry:%ld====",[nonBound count],[bound count]);
            
            inSMOStop = [self checkAlphaOutOfKKT:aryXi aryYi:aryYi aryAlpha:aryAlphe wAry:w b:bias valueC:cValue];
            
            if (inSMOStop) {
                NSLog(@"inSMOStop");
                //                    NSLog(@"W:%@",wAry);
                break;
            }
            
            if (inSMOStop) {
                break;
            }
        }
        
        
    }*/
    
    
//    __block NSMutableArray *wAry = [w mutableCopy];
    
    for (int i = 0; i < iteration; i ++) {
        stopSMO = [self alphaOutOfKKT:aryXi aryYi:aryYi aryAlpha:aryAlphe wAry:w b:bias valueC:cValue];
        
        if (stopSMO) {
            break;
        }else{
            
            int tempAlpheAryIndex;
            int i = 0, j;
            int yi,yj;
            double alphe1New,alphe2New;
            double alphe1Old,alphe2Old;
            double oldE1,oldE2;
            
            do {
                
                NSLog(@"boundaryAry:%ld nonBoundAry:%ld",[nonBound count],[bound count]);
                
                //找出最適合的Alphe 1 在aryXi中的index
                if ([nonBound count] != 0) {
                    tempAlpheAryIndex = [self getReadyUpadteAlpha1:nonBound aryXi:aryXi aryYi:aryYi alpheAry:aryAlphe];
                    i = [[nonBound objectAtIndex:tempAlpheAryIndex] intValue];
                    [nonBound removeObjectAtIndex:tempAlpheAryIndex];
                    
                }else{
                    tempAlpheAryIndex = [self getReadyUpadteAlpha1:bound aryXi:aryXi aryYi:aryYi alpheAry:aryAlphe];
                    i = [[bound objectAtIndex:tempAlpheAryIndex] intValue];
                    [bound removeObjectAtIndex:tempAlpheAryIndex];
                }
                
                //找出最適合的Alphe 2 在aryXi中的index
                if ([nonBound count] != 0) {
                    tempAlpheAryIndex = [self getReadyUpadteAlpha2:nonBound aryXi:aryXi aryYi:aryYi alpheAry:aryAlphe alpheI:i];
                    j = [[nonBound objectAtIndex:tempAlpheAryIndex] intValue];
//                    [nonBound removeObjectAtIndex:tempAlpheAryIndex];
                    
                }
                else if([bound count] != 0){
                    
                    tempAlpheAryIndex = [self getReadyUpadteAlpha2:bound aryXi:aryXi aryYi:aryYi alpheAry:aryAlphe alpheI:i];
                    j = [[bound objectAtIndex:tempAlpheAryIndex] intValue];
//                    [bound removeObjectAtIndex:tempAlpheAryIndex];
                    
                }
                else{//當Alphe 1挑完後全部淨空，沒有剩下不符KKT條件的部分
                    j = arc4random() % ([aryYi count]);
                    if (i == j) {
                        if (i != [aryYi count]-1) {
                            j = j+1;
                        }else{
                            j = j-1;
                        }
                    }
                }
                
                
                yi = [[aryYi objectAtIndex:i] intValue];
                yj = [[aryYi objectAtIndex:j] intValue];
                
                alphe1Old = [[aryAlphe objectAtIndex:i] doubleValue];
                alphe2Old = [[aryAlphe objectAtIndex:j] doubleValue];
                
                oldE1 = [self calculateE:aryXi aryYi:aryYi aryAlpha:aryAlphe index:i bias:bias];
                oldE2 = [self calculateE:aryXi aryYi:aryYi aryAlpha:aryAlphe index:j bias:bias];
                
                //先更新Alphe 2
                alphe2New = [self updateAlpha2:alphe2Old aryX1:[aryXi objectAtIndex:i] aryX2:[aryXi objectAtIndex:j] y2:yj oldE1:oldE1 oldE2:oldE2];
                //確認更新的Alphe 2在範圍內
                alphe2New = [self checkRange:alphe1Old alpha2New:alphe2New alpha2Old:alphe2Old y1:yi y2:yj cValue:cValue];
                //更新Alphe 1
                alphe1New = [self updateAlpha1:alphe1Old alpha2:alphe2New alpha2Old:alphe2Old y1:yi y2:yj];
                
                if (alphe1Old == alphe1New && alphe2Old == alphe2New){
                    break;
                }
                
                //更新 aryAlphe中的 Alphe
                [aryAlphe replaceObjectAtIndex:i withObject:[NSNumber numberWithDouble:alphe1New]];
                [aryAlphe replaceObjectAtIndex:j withObject:[NSNumber numberWithDouble:alphe2New]];
                
                //更新Ｗ
                w = [[self updateW:w alpha1New:alphe1New oldAlpha1:alphe1Old alpha2New:alphe2New oldAlpha2:alphe2Old yi:yi xi:[aryXi objectAtIndex:i] yj:yj xj:[aryXi objectAtIndex:j]] mutableCopy];
                //更新誤差bais
                bias = [self updateBias:bias aryX1:[aryXi objectAtIndex:i] aryX2:[aryXi objectAtIndex:j] y1Value:yi y2Value:yj alpha1New:alphe1New oldAlpha1:alphe1Old alpha2New:alphe2New oldAlpha2:alphe2Old oldE1:oldE1 oldE2:oldE2 valueC:cValue];
                
                
                NSLog(@"Alphe1:%d Alpha2:%d",i,j);
                NSLog(@"alphe1Old:%f alphe1New:%f",alphe1Old,alphe1New);
                NSLog(@"alphe2Old:%f alphe2New:%f",alphe2Old,alphe2New);
                NSLog(@"Bias:%f",bias);
                NSLog(@"W:%@",w);
                NSLog(@"====nonBoundaryAry:%ld BoundAry:%ld====",[nonBound count],[bound count]);
                
                inSMOStop = [self checkAlphaOutOfKKT:aryXi aryYi:aryYi aryAlpha:aryAlphe wAry:w b:bias valueC:cValue];
                
                if (inSMOStop) {
                    NSLog(@"inSMOStop");
//                    NSLog(@"W:%@",wAry);
                    break;
                }
                
            } while ([nonBound count] + [bound count] > 0 );

//            w = [wAry mutableCopy];
            if (inSMOStop) {
                break;
            }
        }
        

    }
    

}


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
