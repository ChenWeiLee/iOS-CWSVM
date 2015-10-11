//
//  CWSMO.h
//  JWSVM-SMO
//
//  Created by Li Chen wei on 2015/10/11.
//  Copyright © 2015年 Enoch. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CWSMO : NSObject


- (id)initWithXi:(NSMutableArray *)arrayXi withYi:(NSMutableArray *)arrayYi;
- (void)updateValueSMO;
@end
