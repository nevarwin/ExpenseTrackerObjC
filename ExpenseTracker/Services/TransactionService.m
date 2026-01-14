
#import "TransactionService.h"
#import "CoreDataManager.h"

@implementation TransactionService

+ (instancetype)sharedService {
    static TransactionService *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[TransactionService alloc] init];
    });
    return sharedInstance;
}

- (NSManagedObjectContext *)context {
    return [[CoreDataManager sharedManager] viewContext];
}

- (NSArray<NSDictionary *> *)fetchBudgetsWithError:(NSError **)error {
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Budget"];
    fetchRequest.resultType = NSManagedObjectResultType;
    fetchRequest.propertiesToFetch = nil;
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"isActive == YES"];
    
    NSArray<Budget *> *results = [[self context] executeFetchRequest:fetchRequest error:error];
    if (!results) return nil;
    
    NSMutableArray *budgetsArray = [NSMutableArray array];
    for (Budget *budget in results) {
        if (budget.name) {
            [budgetsArray addObject:@{
                @"name": budget.name,
                @"objectID": budget.objectID
            }];
        }
    }
    return [budgetsArray copy];
}

- (NSArray<NSDictionary *> *)fetchCategoriesWithError:(NSError **)error 
                                             isIncome:(NSInteger)isIncome 
                                        transactionDate:(NSDate *)date 
                                            budgetID:(NSManagedObjectID *)budgetID 
                             excludedTransactionID:(nullable NSManagedObjectID *)excludedTransactionID {
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Category"];
    fetchRequest.resultType = NSManagedObjectResultType;
    fetchRequest.propertiesToFetch = nil;
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"isIncome == %@", @(isIncome)];
    
    NSArray<Category *> *results = [[self context] executeFetchRequest:fetchRequest error:error];
    if (!results) return nil;
    
    NSMutableArray *categoryArray = [NSMutableArray array];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    for (Category *category in results) {
        if (category.name && [budgetID isEqual:category.budget.objectID]) {
            
            BOOL shouldInclude = YES;
            
            // Check for duplicate installment transaction in the same month
            if (category.isInstallment && date) {
                NSInteger targetYear = [calendar component:NSCalendarUnitYear fromDate:date];
                NSInteger targetMonth = [calendar component:NSCalendarUnitMonth fromDate:date];
                
                for (Transaction *transaction in category.transactions) {
                    // Check if exclude (for edit mode)
                    if (excludedTransactionID && [transaction.objectID isEqual:excludedTransactionID]) {
                        continue;
                    }

                    if (!transaction.isActive) {
                        continue;
                    }
                    
                    NSInteger tYear = [calendar component:NSCalendarUnitYear fromDate:transaction.date];
                    NSInteger tMonth = [calendar component:NSCalendarUnitMonth fromDate:transaction.date];
                    
                    if (tYear == targetYear && tMonth == targetMonth) {
                        shouldInclude = NO;
                        break;
                    }
                }
            }
            
            if (shouldInclude && [category isValidForDate:date]) {
                [categoryArray addObject:@{
                    @"name": category.name,
                    @"objectID": category.objectID,
                    @"isIncome": @(category.isIncome)
                }];
            }
        }
    }
    return [categoryArray copy];
}

- (void)saveTransactionWithAmount:(NSDecimalNumber *)amount
                             desc:(NSString *)desc
                             date:(NSDate *)date
                           budget:(Budget *)budget
                         category:(Category *)category
                         isIncome:(BOOL)isIncome
               existingTransaction:(nullable Transaction *)existingTransaction
                       completion:(void (^)(BOOL success, NSError * _Nullable error, BOOL amountOverflow))completion {
    
    NSManagedObjectContext *context = [self context];
    
    Transaction *transaction = existingTransaction ? existingTransaction :
    [NSEntityDescription insertNewObjectForEntityForName:@"Transaction"
                                  inManagedObjectContext:context];
    
    // Logic for usedAmount update
    BOOL amountOverflow = NO;
    
    if (existingTransaction) {
        // If editing, subtract old amount first
         Budget *oldBudget = existingTransaction.budget; // Currently unused in logic but good to know
         Category *oldCategory = existingTransaction.category;
         
         NSDecimalNumber *usedAmount = oldCategory.usedAmount ?: [NSDecimalNumber zero];
         oldCategory.usedAmount = [usedAmount decimalNumberBySubtracting:existingTransaction.amount];
    }
    
    NSDecimalNumber *usedAmount = category.usedAmount ?: [NSDecimalNumber zero];
    NSDecimalNumber *totalUsedAmount = [usedAmount decimalNumberByAdding:amount];
    
    // "amountOverflow" check logic
    if ([totalUsedAmount compare:category.allocatedAmount] != NSOrderedDescending) {
        category.usedAmount = totalUsedAmount;
    } else {
        category.usedAmount = totalUsedAmount;
        amountOverflow = YES;
    }
    
    // Update Transaction
    transaction.amount = amount;
    transaction.desc = desc;
    transaction.date = date;
    transaction.budget = budget;
    transaction.category = category;
    transaction.category.isIncome = isIncome;
    
    [category addTransactionsObject:transaction];
    
    NSError *error = nil;
    if (![context save:&error]) {
        NSLog(@"Failed to save transaction: %@", error);
        if (completion) completion(NO, error, amountOverflow);
    } else {
        NSLog(@"Transaction saved: %@", transaction);
        if (completion) completion(YES, nil, amountOverflow);
    }
}

@end
