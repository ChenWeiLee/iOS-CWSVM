//
//  CWSMO.m
//  JWSVM-SMO
//
//  Created by Li Chen wei on 2015/12/10.
//  Copyright © 2015年 Enoch. All rights reserved.
//

#import "CWSMO.h"

#import "CWPattern.h"
#import "NSMutableArray+Copy.h"


typedef NS_ENUM(NSInteger, MutableClassifyType) {
    MutableClassifyTypeOneToOne,
    MutableClassifyTypeOneToOther
};

@interface CWSMO ()

@property (nonatomic, strong) CWKernelAlgorithm *kernelMethod;
@property (nonatomic, strong) NSMutableArray <id<CWPatternErrorCalculator> > *trainingPatterns;
@property (nonatomic, strong) NSMutableArray *expectations;

@property (nonatomic) double targetValue;
@property (nonatomic) double targetNewValue;

@property (nonatomic, strong) NSMutableArray *mainPatterns;
@property (nonatomic, strong) NSMutableArray *matchPatterns;

@property (nonatomic) double mainTarget;
@property (nonatomic) double matchTarget;

@property (nonatomic) MutableClassifyType classifyType;

@end

@implementation CWSMO

#pragma mark - init Default

- (id)init
{
    self = [super init];
    if (self) {
        
        _kernelMethod = [CWKernelAlgorithm new];
        _trainingPatterns = [NSMutableArray new];
        
        _mainPatterns = [NSMutableArray new];
        _matchPatterns = [NSMutableArray new];

        bias = -1;
        _methodType = KernelTypeLinear;
        _kernelMethod.sigma = 1.0;
        iteration = 1000;
        toleranceValue = 0.0001;
        cValue = 10;
        _tag = @"0";

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

- (double)classifyValueWithData:(id<CWPattern>)pattern
{
    double result = [self algorithmValue:pattern];
    
    switch (_classifyType) {
        case MutableClassifyTypeOneToOne:
        {
            return result >= 0 ? _mainTarget : _matchTarget ;
        }
            break;
        case MutableClassifyTypeOneToOther:
        default:
            return result;
            break;
    }
    
}

- (double)algorithmValue:(id<CWPattern>)pattern
{
    return [_kernelMethod algorithmWithData:[pattern features] data2:w];
}

#pragma mark - Start Train SMO-Step Method

- (void)startTrainingOneToOneWithMainData:(NSMutableArray <id<CWPattern>>*)tPatterns otherData:(NSMutableArray <id<CWPattern>>*)fPatterns
{
    _classifyType = MutableClassifyTypeOneToOne;
    
    _mainTarget = [[tPatterns objectAtIndex:0] targetValue];
    _matchTarget = [[fPatterns objectAtIndex:0] targetValue];
    
    [self startTrainingWithMainData:tPatterns otherData:fPatterns];
}

- (void)startTrainingOneToOtherWithMainData:(NSMutableArray <id<CWPattern>>*)tPatterns otherData:(NSMutableArray <id<CWPattern>>*)fPatterns
{
    _classifyType = MutableClassifyTypeOneToOther;

    [self startTrainingWithMainData:tPatterns otherData:fPatterns];
}

- (void)startTrainingWithMainData:(NSMutableArray <id<CWPattern>>*)tPatterns otherData:(NSMutableArray <id<CWPattern>>*)fPatterns
{
    _mainPatterns  = [tPatterns deepCopy];
    _matchPatterns = [fPatterns deepCopy];
    
    [_mainPatterns enumerateObjectsUsingBlock:^(id<CWPattern>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.targetValue = 1;
    }];
    
    [_matchPatterns enumerateObjectsUsingBlock:^(id<CWPattern>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.targetValue = -1;
    }];
    
    [_trainingPatterns addObjectsFromArray:_mainPatterns];
    [_trainingPatterns addObjectsFromArray:_matchPatterns];
    
    [self initWithTrainData];
    [self trainingData];
}

- (void)startTrainingWithData:(NSMutableArray <NSMutableArray *>*)aryXi aryYi:(NSMutableArray *)aryYi
{
    
    if ([aryXi count] == 0) {
        return;
    }
    
    for (int index = 0; index < [aryXi count]; index = index + 1) {
        
        [_trainingPatterns addObject:[[CWPattern alloc] initWithX:[aryXi objectAtIndex:index] expectations:[[aryYi objectAtIndex:index] integerValue] alpha:0.0]];
        
    }
    
    [self initWithTrainData];
    [self trainingData];
}

- (void)initWithTrainData
{
    //如果這個CWSMO NSObject是一個新的話，就初始化所有的值
    if (w == nil && bias == -1) {
        w = [NSMutableArray new];
        bias = 0;
        
        for (int j = 0; j < [[[_trainingPatterns objectAtIndex:0] features] count]; j = j + 1) {
            [w addObject:@"0"];
        }
    }
}

- (void)trainingData
{
    
    BOOL trainCompleted  = YES;
    _targetValue           = 0;
    _targetNewValue        = 0;
    
    //外圍迭代，當迭代到最大還未收斂，則強制收斂
    for (int sprint = 0; sprint < iteration; sprint = sprint +1) {
        trainCompleted = YES;
        //這邊採用啟發式方法來做
        for (int tour = 0; tour < [_trainingPatterns count] ; tour = tour +1) {
            
            id<CWPatternErrorCalculator> point1 = [_trainingPatterns objectAtIndex:tour];
            
            //尋找到第一筆不符合KKT條件
            if (![self checkKKTWithPoint:point1]) {
                
                trainCompleted = NO;
                
                //使用Random的方式來挑選第二更新點
                id<CWPatternErrorCalculator> point2 = [self randomSelectSecondUpdatePoint:point1];
                NSInteger index2 = [_trainingPatterns indexOfObject:point2];
                
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
                
                [_trainingPatterns replaceObjectAtIndex:tour withObject:point1];
                [_trainingPatterns replaceObjectAtIndex:index2 withObject:point2];
                
            }
            
        }
        
        //目前只使用KKT條件來做終止條件
        if (trainCompleted) {
            NSLog(@"Weight:%@ Bias:%lf",w,bias);
            return;
        }
    }

}

#pragma mark - 選擇第二筆更新數據

//選擇搭配的第二筆數據 |E1 - E2|
- (id<CWPatternErrorCalculator>)selectSecondUpadtePointWithoutPoint:(id<CWPatternErrorCalculator>)point
{
    NSInteger pointOneIndex = [_trainingPatterns indexOfObject:point];
    if (![point isEqual:[_trainingPatterns lastObject]]) {
        //如果不為最後一筆的話，就找出|E1-E2|最大的
        return [self selectMaxErrorIndexWithPoint:point startIndex:(int)(pointOneIndex +1)];
    }else{
        //如果為最後一筆的話，就隨機挑點來當作第二調整點
        return [self randomSelectSecondUpdatePoint:point];
    }
    
}
//隨機挑點
- (id<CWPatternErrorCalculator>)randomSelectSecondUpdatePoint:(id<CWPatternErrorCalculator>)point
{
    NSInteger pointIndex = [_trainingPatterns indexOfObject:point];
    NSInteger selectPoint = 0;
    do {
        selectPoint = arc4random() % [_trainingPatterns count];
    } while (selectPoint == pointIndex);
    
    return [_trainingPatterns objectAtIndex:selectPoint];
}

//找出Array中符合誤差值|E1-E2|最大者
- (id<CWPatternErrorCalculator>)selectMaxErrorIndexWithPoint:(id<CWPatternErrorCalculator>)point startIndex:(int)startIndex{
    
    int maxIndex = startIndex;
    double maxError = 0.0, tempError = 0.0;
    NSMutableArray <id<CWPattern>> * patterns = [_trainingPatterns mutableCopy];
    double pointE = [point error:bias patterns:patterns];
    
    for (int index = startIndex; index < [_trainingPatterns count] ; index = index + 1) {
        id<CWPatternErrorCalculator> tempPoint = [_trainingPatterns objectAtIndex:index];
        double tempE = [tempPoint error:bias patterns:patterns];
        tempError = fabs(pointE - tempE);
        
        if (tempError > maxError) {
            maxError = tempError;
            maxIndex = index;
        }
    }

    return [_trainingPatterns objectAtIndex:maxIndex];
}

#pragma mark - 更新第二筆數據
//更新Alpha2
- (double)updateAlpha2Withpoint2:(id<CWPatternErrorCalculator>)point2 x1Index:(id<CWPatternErrorCalculator>)point1
{
    double alpha2New;
    double K11 = 0, K22 = 0, K12 = 0;
    NSMutableArray <id<CWPattern>> * patterns = [_trainingPatterns mutableCopy];
    double e1 = [point1 error:bias patterns:patterns];
    double e2 = [point2 error:bias patterns:patterns];
    
    
    K11 = [_kernelMethod algorithmWithData:point1.features data2:point1.features];
    K22 = [_kernelMethod algorithmWithData:point2.features data2:point2.features];
    K12 = [_kernelMethod algorithmWithData:point1.features data2:point2.features];
    
    alpha2New = point2.alpha + (([point2 targetValue]* (e1 - e2)) / (K11 + K22 - 2*K12));
    
    return alpha2New;
}

//確認新的alpha2在我們要的範圍內
- (double)checkRangeWithNewAlpha:(double)alpha2New point1:(id<CWPatternErrorCalculator>)point1 point2:(id<CWPatternErrorCalculator>)point2
{
    double maxValue,minValue;
    
    if (([point1 targetValue] * [point2 targetValue]) == 1) {
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
#pragma mark - 更新第一筆數據

//更新Alpha1
- (double)updateAlpha1WithPoint1:(id<CWPatternErrorCalculator>)point1 point2:(id<CWPatternErrorCalculator>)point2 alpha2New:(double)alpha2New
{
    double alpha1New = point1.alpha  + (point2.targetValue  * point1.targetValue * (point2.alpha - alpha2New));
    
    return alpha1New;
}

#pragma mark - 更新權重及偏權值
//更新權重W
- (void)updateWWithPoint1:(id<CWPatternErrorCalculator>)point1 alpha1New:(double)alpha1New point2:(id<CWPatternErrorCalculator>)point2 alpha2New:(double)alpha2New
{
    double updateWi = 0.0;
    
    for (int inputX = 0; inputX < [w count]; inputX ++) {
        
        updateWi = [[w objectAtIndex:inputX] doubleValue] + (alpha1New - point1.alpha) * point1.targetValue * [[point1.features objectAtIndex:inputX] doubleValue] + (alpha2New - point2.alpha) * point2.targetValue * [[point2.features objectAtIndex:inputX] doubleValue];
        
        [w replaceObjectAtIndex:inputX withObject:[NSNumber numberWithDouble:updateWi]];
    }
    
}

//更新誤差值bias
- (void)updateBiasWithPoint1:(id<CWPatternErrorCalculator>)point1 alpha1New:(double)alpha1New point2:(id<CWPatternErrorCalculator>)point2 alpha2New:(double)alpha2New
{
    
    double b1New = 0.0,b2New = 0.0;
    double y1a1Value =  point1.targetValue * (alpha1New - point1.alpha);
    double y2a2Value =  point2.targetValue * (alpha2New - point2.alpha);
    NSMutableArray <id<CWPattern>> * patterns = [_trainingPatterns mutableCopy];

    double oldE1 = [point1 error:bias patterns:patterns];
    double oldE2 = [point2 error:bias patterns:patterns];
    
    b1New = bias - oldE1 - y1a1Value * [_kernelMethod algorithmWithData:point1.features data2:point1.features] - y2a2Value * [_kernelMethod algorithmWithData:point1.features data2:point2.features];
    
    b2New = bias - oldE2 - y1a1Value * [_kernelMethod algorithmWithData:point1.features data2:point2.features] - y2a2Value * [_kernelMethod algorithmWithData:point2.features data2:point2.features];
    
    if (alpha1New > 0 && alpha1New < cValue) {
        bias = b1New;
    }else if (alpha2New > 0 && alpha2New < cValue){
        bias = b2New;
    }else{
        bias = (b2New + b1New)/2;
    }
}

#pragma mark - 終止條件

//確認該點是否符合KKT條件
- (BOOL)checkKKTWithPoint:(id<CWPatternErrorCalculator>)point
{
    double checkValue = 0.0;
    
    NSMutableArray <id<CWPattern>> * patterns = [_trainingPatterns mutableCopy];
    // yi * Ei
    checkValue = point.targetValue * [point error:bias patterns:patterns];
    
    if ((checkValue < -toleranceValue && point.alpha < cValue) || (checkValue > toleranceValue && point.alpha > 0)) {
        return NO;
    }else{
        return YES;
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
    
    for (CWPattern *point in _trainingPatterns) {
        for (int index = 0; index < [w count]; index = index + 1) {
            tempValue = tempValue + [[w objectAtIndex:index] doubleValue] * [[point.features objectAtIndex:index] doubleValue];
        }
        
        tempValue = point.targetValue * (tempValue +bias) - 1;
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
