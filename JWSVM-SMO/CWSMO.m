//
//  CWSMO.m
//  JWSVM-SMO
//
//  Created by Li Chen wei on 2015/12/10.
//  Copyright © 2015年 Enoch. All rights reserved.
//

#import "CWSMO.h"

#import "SVMDataPoint.h"

@interface CWSMO ()

@property (nonatomic, strong) CWKernelAlgorithm *kernelMethod;
@property (nonatomic, strong) NSMutableArray <SVMDataPoint *>*points;
@property (nonatomic, strong) NSMutableArray *expectations;

@property (nonatomic) double targetValue;
@property (nonatomic) double targetNewValue;

@end

@implementation CWSMO

#pragma mark - init Default

- (id)init
{
    self = [super init];
    if (self) {
        
        _kernelMethod = [CWKernelAlgorithm new];
        _points = [NSMutableArray new];
        
        bias = -1;
        _methodType = KernelTypeLinear;
        _kernelMethod.sigma = 1.0;
        iteration = 1000;
        toleranceValue = 0.0001;
        cValue = 10;
        _Tag = @"0";
        
    }
    return self;
}

- (id)initWithKernelMethod:(KernelType)kernelType sigmaValue:(double)sigmaValue maxIterations:(int)iterations relaxation:(double)c;
{
    self = [self init];
    
    if (self) {
        _methodType = kernelType;
        
        if (sigmaValue <= 0) {
            _kernelMethod.sigma = 1;
        }else{
            _kernelMethod.sigma = sigmaValue;
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
    
    //如果這個CWSMO NSObject是一個新的話，就初始化所有的值
    if (w == nil && bias == -1) {
        w = [NSMutableArray new];
        bias = 0;
        
        for (int j = 0; j < [[aryXi objectAtIndex:0] count]; j = j + 1) {
            [w addObject:@"0"];
        }
    }
    
    for (int index = 0; index < [aryXi count]; index = index + 1) {
        
        [_points addObject:[[SVMDataPoint alloc] initWithX:[aryXi objectAtIndex:index] expectations:[[aryYi objectAtIndex:index] integerValue]]];
        
    }

    BOOL trainCompleted  = YES;
    _targetValue           = 0;
    _targetNewValue        = 0;
    
    //外圍迭代，當迭代到最大還未收斂，則強制收斂
    for (int sprint = 0; sprint < iteration; sprint = sprint +1) {
        trainCompleted = YES;
        //這邊採用啟發式方法來做
        for (int tour = 0; tour < [_points count] ; tour = tour +1) {
            
            SVMDataPoint *point1 = [_points objectAtIndex:tour];
            
            //尋找到第一筆不符合KKT條件
            if (![self checkKKTWithPoint:point1]) {
                
                trainCompleted = NO;
                
                SVMDataPoint *point2 = [self selectSecondUpadtePointWithoutPoint:point1];
                NSInteger index2 = [_points indexOfObject:point2];
                
                //更新選擇point2點的alpha
                double newPointAlpha2 = [self updateAlpha2Withpoint2:point2 x1Index:point1];
                //確認point2點的newAlpha在我們的範圍裡面
                newPointAlpha2 = [self checkRangeWithNewAlpha:newPointAlpha2 point1:point1 point2:point2];
                //更新選擇point1點的alpha
                double newPointAlpha1 = [self updateAlpha1WithPoint1:point1 point2:point2 alpha2New:newPointAlpha2];
                
                [self updateWWithPoint1:point1 alpha1New:newPointAlpha1 point2:point2 alpha2New:newPointAlpha2];
                
                [self updateBiasWithPoint1:point1 alpha1New:newPointAlpha1 point2:point2 alpha2New:newPointAlpha2];
                
                [point1 updateAlpha:newPointAlpha1];
                [point2 updateAlpha:newPointAlpha2];
                
                [_points replaceObjectAtIndex:tour withObject:point1];
                [_points replaceObjectAtIndex:index2 withObject:point2];
                
            }
            
        }
        
        if (trainCompleted || [self stopSVMIteration]) {
            NSLog(@"Weight:%@ Bias:%lf",w,bias);
            return;
        }
    }
    

}

//確認該點是否符合KKT條件
- (BOOL)checkKKTWithPoint:(SVMDataPoint *)point
{
    double valueOut = 0.0;
    
    //    valueOut = point.y * [point getErrorWithBias:bias points:_points kernelType:_methodType];
    //以下結果跟上述一樣
    for (int index = 0; index < [point.x count]; index = index + 1) {
        valueOut = valueOut + [[point.x objectAtIndex:index] doubleValue] * [[w objectAtIndex:index] doubleValue];
    }
    
    valueOut = point.y * (valueOut +bias);
    
    
    if (point.alpha  == 0 && valueOut + toleranceValue >= 1) {
        return YES;
    }else if (point.alpha  == cValue && valueOut - toleranceValue <= 1){
        return YES;
    }else if (point.alpha > 0 && point.alpha < cValue && fabs(valueOut - 1) < toleranceValue  ){
        return YES;
    }else{
        return NO;
    }
    
}

//選擇搭配的第二筆數據
- (SVMDataPoint *)selectSecondUpadtePointWithoutPoint:(SVMDataPoint *)point
{
    NSInteger selectPoint = 0;
    NSInteger pointOneIndex = [_points indexOfObject:point];
    if (![point isEqual:[_points lastObject]]) {
        //如果不為最後一筆的話，就找出|E1-E2|最大的
        selectPoint = [self selectMaxErrorIndexWithPoint:point startIndex:(int)(pointOneIndex +1)];
    }else{
        //如果為最後一筆的話，就隨機挑點來當作第二調整點
        selectPoint = arc4random() % [_points count];
        if (selectPoint == pointOneIndex) {
            
            //如果挑到的點不為最後一筆的話，就統一加一
            //如果挑到的點為最後一筆的話，就減一
            if (selectPoint != [_points count]-1) {
                selectPoint = selectPoint +1;
            }else{
                selectPoint = selectPoint -1;
            }
        }
    }
    
    return [_points objectAtIndex:selectPoint];
}

//找出Array中符合誤差值|E1-E2|最大者
- (int)selectMaxErrorIndexWithPoint:(SVMDataPoint *)point startIndex:(int)startIndex{
    
    int maxIndex = startIndex;
    double maxError = 0.0, tempError = 0.0;
    double pointE = [point getErrorWithBias:bias points:_points kernelType:_methodType];
    
    for (int index = startIndex; index < [_points count] ; index = index + 1) {
        SVMDataPoint *tempPoint = [_points objectAtIndex:index];
        double tempE = [tempPoint getErrorWithBias:bias points:_points kernelType:_methodType];
        tempError = fabs(pointE - tempE);
        
        if (tempError > maxError) {
            maxError = tempError;
            maxIndex = index;
        }
    }

    return maxIndex;
}


//更新Alpha2
- (double)updateAlpha2Withpoint2:(SVMDataPoint *)point2 x1Index:(SVMDataPoint *)point1
{
    double alpha2New;
    double K11 = 0, K22 = 0, K12 = 0;
    double e1 = [point1 getErrorWithBias:bias points:_points kernelType:_methodType];
    double e2 = [point2 getErrorWithBias:bias points:_points kernelType:_methodType];
    
    
    K11 = [_kernelMethod algorithmWithData:point1.x data2:point1.x];
    K22 = [_kernelMethod algorithmWithData:point2.x data2:point2.x];
    K12 = [_kernelMethod algorithmWithData:point1.x data2:point2.x];
    
    alpha2New = point2.alpha + ((point2.y * (e1 - e2)) / (K11 + K22 - 2*K12));
    
    return alpha2New;
}

//確認新的alpha2在我們要的範圍內
- (double)checkRangeWithNewAlpha:(double)alpha2New point1:(SVMDataPoint *)point1 point2:(SVMDataPoint *)point2
{
    double maxValue,minValue;
    
    if ((point1.y * point2.y) == 1) {
        minValue = MAX(0, point2.alpha + point1.alpha - cValue);
        maxValue = MIN(cValue, point2.alpha + point1.alpha);
    }else{
        minValue = MAX(0, point2.alpha - point1.alpha);
        maxValue = MIN(cValue, cValue + point2.alpha - point1.alpha);
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
- (double)updateAlpha1WithPoint1:(SVMDataPoint *)point1 point2:(SVMDataPoint *)point2 alpha2New:(double)alpha2New
{
    double alpha1New = point1.alpha + (point2.y * point1.y * (point2.alpha - alpha2New));
    
    return alpha1New;
}


//更新W
- (void)updateWWithPoint1:(SVMDataPoint *)point1 alpha1New:(double)alpha1New point2:(SVMDataPoint *)point2 alpha2New:(double)alpha2New
{
    double updateWi = 0.0;
    
    for (int inputX = 0; inputX < [w count]; inputX ++) {
        
        updateWi = [[w objectAtIndex:inputX] doubleValue] + (alpha1New - point1.alpha) * point1.y * [[point1.x objectAtIndex:inputX] doubleValue] + (alpha2New - point2.alpha) * point2.y * [[point2.x objectAtIndex:inputX] doubleValue];
        
        [w replaceObjectAtIndex:inputX withObject:[NSNumber numberWithDouble:updateWi]];
    }
    
}

//更新誤差值bias
- (void)updateBiasWithPoint1:(SVMDataPoint *)point1 alpha1New:(double)alpha1New point2:(SVMDataPoint *)point2 alpha2New:(double)alpha2New
{
    
    double b1New = 0.0,b2New = 0.0;
    double y1a1Value =  point1.y * (alpha1New - point1.alpha);
    double y2a2Value =  point2.y * (alpha2New - point2.alpha);
    double oldE1 = [point1 getErrorWithBias:bias points:_points kernelType:_methodType];
    double oldE2 = [point2 getErrorWithBias:bias points:_points kernelType:_methodType];
    
    b1New = bias - oldE1 - y1a1Value * [_kernelMethod algorithmWithData:point1.x data2:point1.x] - y2a2Value * [_kernelMethod algorithmWithData:point1.x data2:point2.x];
    
    b2New = bias - oldE2 - y1a1Value * [_kernelMethod algorithmWithData:point1.x data2:point2.x] - y2a2Value * [_kernelMethod algorithmWithData:point2.x data2:point2.x];
    
    if (alpha1New > 0 && alpha1New < cValue) {
        bias = b1New;
    }else if (alpha2New > 0 && alpha2New < cValue){
        bias = b2New;
    }else{
        bias = (b2New + b1New)/2;
    }
}


//終止條件
//當我的目標函式變化小於設定的閥值時即終止
//可參考：https://zh.wikipedia.org/wiki/序列最小优化算法
- (BOOL)stopSVMIteration
{
    double tempValue = 0.0;
    for (int index = 0; index < [w count]; index = index + 1) {
        _targetNewValue = _targetNewValue + [[w objectAtIndex:index] doubleValue] * [[w objectAtIndex:index] doubleValue];
    }
    _targetNewValue = _targetNewValue/2;
    
    for (SVMDataPoint *point in _points) {
        for (int index = 0; index < [w count]; index = index + 1) {
            tempValue = tempValue + [[w objectAtIndex:index] doubleValue] * [[point.x objectAtIndex:index] doubleValue];
        }
        
        tempValue = point.y * (tempValue +bias) - 1;
    }
    
    _targetNewValue = _targetNewValue - tempValue;
    
    
    if (_targetValue != 0 && (_targetNewValue -_targetValue)/_targetNewValue < toleranceValue) {
        return YES;
    }else{
        _targetValue = _targetNewValue;
        return NO;
    }
    
}

@end
