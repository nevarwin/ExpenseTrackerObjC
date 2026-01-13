//
//  CategoryTests.m
//  ExpenseTrackerTests
//
//  Created by raven on 1/13/26.
//

#import <XCTest/XCTest.h>
#import <CoreData/CoreData.h>
#import "Category+CoreDataClass.h"

@interface CategoryTests : XCTestCase
@property (nonatomic, strong) NSPersistentContainer *container;
@property (nonatomic, strong) NSManagedObjectContext *context;
@end

@implementation CategoryTests

- (void)setUp {
    [super setUp];
    
    // Setup in-memory Core Data stack
    NSManagedObjectModel *model = [NSManagedObjectModel mergedModelFromBundles:@[[NSBundle mainBundle]]];
    self.container = [[NSPersistentContainer alloc] initWithName:@"ExpenseTracker" managedObjectModel:model];
    
    NSPersistentStoreDescription *description = [[NSPersistentStoreDescription alloc] init];
    description.type = NSInMemoryStoreType;
    self.container.persistentStoreDescriptions = @[description];
    
    [self.container loadPersistentStoresWithCompletionHandler:^(NSPersistentStoreDescription *description, NSError *error) {
        XCTAssertNil(error);
    }];
    
    self.context = self.container.viewContext;
}

- (void)tearDown {
    self.container = nil;
    self.context = nil;
    [super tearDown];
}

- (void)testIsValidForDate_NonInstallment_ReturnsTrue {
    Category *category = [NSEntityDescription insertNewObjectForEntityForName:@"Category" inManagedObjectContext:self.context];
    category.isInstallment = NO;
    
    BOOL result = [category isValidForDate:[NSDate date]];
    XCTAssertTrue(result);
}

- (void)testIsValidForDate_Installment_BeforeStart_ReturnsTrue {
    // Current logic says: if NOT within valid range, then isValid=YES?
    // Wait, let's check the logic:
    // logic: isNotWithinInstallment (old) -> YES if outside range.
    // logic: isValidForDate (new) -> YES if within range.
    // Let's re-read the code logic to be sure.
    // "if (currentTotalMonths >= startTotalMonths && currentTotalMonths <= lastValidTotalMonths) { return YES; } return NO;"
    // So it returns YES if it IS within the installment period.
    // Wait, the Original Controller logic was `isNotWithinInstallment`.
    // If it was NOT within, it was filtered out?
    // Controller logic: `if (![self isNotWithinInstallment:transactionDate :category])`
    // If NOT (NotWithin) => If Within.
    // So we want to SHOW categories that ARE within the installment period.
    // Correct.
    
    Category *category = [NSEntityDescription insertNewObjectForEntityForName:@"Category" inManagedObjectContext:self.context];
    category.isInstallment = YES;
    category.installmentMonths = 3;
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *startDate = [calendar dateWithEra:1 year:2023 month:1 day:1 hour:0 minute:0 second:0 nanosecond:0];
    category.installmentStartDate = startDate;
    
    // Date before start (Dec 2022)
    NSDate *dateBefore = [calendar dateWithEra:1 year:2022 month:12 day:1 hour:0 minute:0 second:0 nanosecond:0];
    XCTAssertFalse([category isValidForDate:dateBefore], @"Should be invalid before start date");
}

- (void)testIsValidForDate_Installment_InsideRange_ReturnsTrue {
    Category *category = [NSEntityDescription insertNewObjectForEntityForName:@"Category" inManagedObjectContext:self.context];
    category.isInstallment = YES;
    category.installmentMonths = 3; // Jan, Feb, Mar
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *startDate = [calendar dateWithEra:1 year:2023 month:1 day:1 hour:0 minute:0 second:0 nanosecond:0];
    category.installmentStartDate = startDate;
    
    // Jan 2023
    XCTAssertTrue([category isValidForDate:startDate]);
    
    // Feb 2023
    NSDate *feb = [calendar dateWithEra:1 year:2023 month:2 day:1 hour:0 minute:0 second:0 nanosecond:0];
    XCTAssertTrue([category isValidForDate:feb]);
    
    // Mar 2023
    NSDate *mar = [calendar dateWithEra:1 year:2023 month:3 day:1 hour:0 minute:0 second:0 nanosecond:0];
    XCTAssertTrue([category isValidForDate:mar]);
}

- (void)testIsValidForDate_Installment_AfterRange_ReturnsFalse {
    Category *category = [NSEntityDescription insertNewObjectForEntityForName:@"Category" inManagedObjectContext:self.context];
    category.isInstallment = YES;
    category.installmentMonths = 3; // Jan, Feb, Mar
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *startDate = [calendar dateWithEra:1 year:2023 month:1 day:1 hour:0 minute:0 second:0 nanosecond:0];
    category.installmentStartDate = startDate;
    
    // April 2023
    NSDate *apr = [calendar dateWithEra:1 year:2023 month:4 day:1 hour:0 minute:0 second:0 nanosecond:0];
    XCTAssertFalse([category isValidForDate:apr]);
}

@end
