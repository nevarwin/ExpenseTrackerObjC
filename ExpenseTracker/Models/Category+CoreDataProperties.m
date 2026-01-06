//
//  Category+CoreDataProperties.m
//  ExpenseTracker
//
//  Created by raven on 1/6/26.
//
//

#import "Category+CoreDataProperties.h"

@implementation Category (CoreDataProperties)

+ (NSFetchRequest<Category *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"Category"];
}

@dynamic allocatedAmount;
@dynamic createdAt;
@dynamic installmentEndDate;
@dynamic installmentMonths;
@dynamic installmentStartDate;
@dynamic isActive;
@dynamic isIncome;
@dynamic isInstallment;
@dynamic monthlyPayment;
@dynamic name;
@dynamic totalInstallmentAmount;
@dynamic updatedAt;
@dynamic usedAmount;
@dynamic budget;
@dynamic transactions;

@end
