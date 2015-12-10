//
//  CWSMO.h
//  JWSVM-SMO
//
//  Created by Li Chen wei on 2015/12/10.
//  Copyright © 2015年 Enoch. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef enum kernelType{
    LinearKernel = 0,
    RBFKernel = 1,
}kernelType;


@interface CWSMO : NSObject
{
    NSMutableArray *w;
    double bias;
    NSMutableArray *aryAlphe;
    
    kernelType kernelMode;
    double sigma;
    double toleranceValue;
    double cValue;
    int iteration;
}
@property (nonatomic, retain) NSString *Tag; //為了多分類用

- (id)init;
- (id)initWithKernelMethod:(kernelType)kernelType sigmaValue:(double)sigmaValue maxIterations:(int)iterations relaxation:(double)c;

- (void)startTrain:(NSMutableArray *)aryXi aryYi:(NSMutableArray *)aryYi;

@end
