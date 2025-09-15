//
//  Budget+CoreDataProperties.m
//  ExpenseTracker
//
//  Created by XOO_Raven on 9/15/25.
//
//

#import "Budget+CoreDataProperties.h"

@implementation Budget (CoreDataProperties)

+ (NSFetchRequest<Budget *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"Budget"];
}

@dynamic createdAt;
@dynamic isActive;
@dynamic name;
@dynamic remainingAmount;
@dynamic totalAmount;
@dynamic updatedAt;
@dynamic allocations;
@dynamic category;
@dynamic transactions;

@end
