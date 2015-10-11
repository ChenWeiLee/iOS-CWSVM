//
//  CWSVM.h
//  JWSVM-SMO
//
//  Created by Li Chen wei on 2015/10/11.
//  Copyright © 2015年 Enoch. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CWSVM : NSObject

@property (nonatomic, retain) NSArray *inputAry;
@property (nonatomic, retain) NSArray *outputAry;
@property (nonatomic, retain) NSArray *results;


- (id)init;
- (void)printW_And_b;
- (void)initValue:(int)maxIter;
- (void)startSMO:(NSMutableArray *)xAry outputYAry:(NSMutableArray *)yAry cValue:(float)cValue;
- (float)calculateXiTXj:(NSMutableArray *)xi j:(NSMutableArray *)xj;

-(void)startTraining;
-(void)cancelTraining;
-(void)classifyPatterns:(NSArray *)_patterns;
-(void)verifyPatterns:(NSArray *)_patterns;

@end
