//
//  Transaction.m
//  ExpenseTracker
//
//  Created by XOO_Raven on 6/27/25.
//

#import <Foundation/Foundation.h>
#import "Transaction.h"

@implementation Transaction

@dynamic transactionId;
@dynamic amount;
@dynamic category;
@dynamic date;
@dynamic createdAt;
@dynamic updatedAt;
@dynamic isActive;
@dynamic type;

- (void)awakeFromInsert {
    [super awakeFromInsert];
    self.isActive = YES;
}

@end
