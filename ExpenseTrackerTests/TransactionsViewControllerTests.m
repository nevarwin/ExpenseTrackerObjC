//
//  TransactionsViewControllerTests.m
//  ExpenseTrackerTests
//
//  Created by raven on 1/13/26.
//

#import <XCTest/XCTest.h>
#import "TransactionsViewController.h"
#import "TransactionService.h"
#import "CoreDataManager.h"
#import "Category+CoreDataClass.h"
#import "Budget+CoreDataClass.h"

// Mock Service
@interface MockTransactionService : TransactionService
@property (nonatomic, assign) BOOL saveCalled;
@property (nonatomic, assign) BOOL shouldFail;
@property (nonatomic, assign) BOOL shouldOverflow;
@property (nonatomic, copy) void (^saveCompletionBlock)(BOOL, NSError *, BOOL);
@end

@implementation MockTransactionService

- (void)saveTransactionWithAmount:(NSDecimalNumber *)amount
                             desc:(NSString *)desc
                             date:(NSDate *)date
                           budget:(Budget *)budget
                         category:(Category *)category
                         isIncome:(BOOL)isIncome
              existingTransaction:(Transaction *)existingTransaction
                       completion:(void (^)(BOOL, NSError * _Nullable, BOOL))completion {
    
    self.saveCalled = YES;
    self.saveCompletionBlock = completion;
    
    if (self.shouldFail) {
        NSError *error = [NSError errorWithDomain:@"TestDomain" code:1 userInfo:nil];
        completion(NO, error, NO);
    } else {
        completion(YES, nil, self.shouldOverflow);
    }
}
@end

// Tests
@interface TransactionsViewControllerTests : XCTestCase
@property (nonatomic, strong) TransactionsViewController *sut;
@property (nonatomic, strong) MockTransactionService *mockService;
@property (nonatomic, strong) NSManagedObjectContext *context;
@end

@implementation TransactionsViewControllerTests

- (void)setUp {
    [super setUp];
    
    // Setup in-memory DB for the Controller to find objects
    [[CoreDataManager sharedManager] useInMemoryStore];
    self.context = [[CoreDataManager sharedManager] viewContext];
    
    self.sut = [[TransactionsViewController alloc] init];
    self.mockService = [[MockTransactionService alloc] init];
    self.sut.service = self.mockService;
    
    // Load View
    [self.sut loadViewIfNeeded];
}

- (void)tearDown {
    self.sut = nil;
    self.mockService = nil;
    [super tearDown];
}

- (void)testSaveTransaction_WithValidInput_CallsServiceSave {
    // Arrange
    // Insert dummy data into in-memory store so the Controller can find it by ID
    Budget *budget = [NSEntityDescription insertNewObjectForEntityForName:@"Budget" inManagedObjectContext:self.context];
    budget.name = @"Test Budget";
    budget.isActive = YES;
    
    Category *category = [NSEntityDescription insertNewObjectForEntityForName:@"Category" inManagedObjectContext:self.context];
    category.name = @"Test Category";
    category.isIncome = NO;
    category.budget = budget;
    
    [self.context save:nil];
    
    // Setup Controller State
    self.sut.amountTextField.text = @"100";
    self.sut.datePicker.date = [NSDate date];
    self.sut.selectedBudgetIndex = budget.objectID;
    self.sut.selectedCategoryIndex = category.objectID;
    self.sut.selectedTypeIndex = 0; // Expense
    
    // Act
    [self.sut rightButtonTapped];
    
    // Assert
    XCTAssertTrue(self.mockService.saveCalled, @"Service save method should be called");
}

- (void)testSaveTransaction_WithInvalidInput_DoesNotCallService {
    // Arrange
    self.sut.amountTextField.text = @""; // Invalid
    
    // Act
    [self.sut rightButtonTapped];
    
    // Assert
    XCTAssertFalse(self.mockService.saveCalled, @"Service save method should NOT be called for invalid input");
}

@end
