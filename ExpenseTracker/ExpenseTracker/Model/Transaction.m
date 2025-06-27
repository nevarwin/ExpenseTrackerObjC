//
//  Transaction.m
//  ExpenseTracker
//
//  Created by XOO_Raven on 6/27/25.
//

#import <Foundation/Foundation.h>
#import "Transaction.h"

@implementation Transaction

- (instancetype)initWithAmount:(NSInteger *)amount
                      category:(NSString *)category
                    createdAt:(NSDate *)createdAt{
    
    self = [super init];
    if (self) {
        _amount = amount;
        _category = category;
        _createdAt = createdAt;
    }
    return self;
}

@end
