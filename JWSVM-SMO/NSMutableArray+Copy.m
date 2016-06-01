//
//  NSMutableArray+Copy.m
//  JWSVM-SMO
//
//  Created by enoch_lee on 2016/6/1.
//  Copyright © 2016年 Enoch. All rights reserved.
//

#import "NSMutableArray+Copy.h"

@implementation NSMutableArray (Copy)

- (instancetype)deepCopy{
    
    NSMutableArray *newArray = [NSMutableArray array];
    [self enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [newArray addObject:[obj copy]];
    }];
    
    return newArray;
}

@end
