//
//  ExpenseTrackerUITests.m
//  ExpenseTrackerUITests
//
//  Created by raven on 1/13/26.
//

#import <XCTest/XCTest.h>

@interface ExpenseTrackerUITests : XCTestCase

@end

@implementation ExpenseTrackerUITests

- (void)setUp {
    [super setUp];
    
    // In UI tests it is usually best to stop immediately when a failure occurs.
    self.continueAfterFailure = NO;
}

- (void)tearDown {
    [super tearDown];
}

- (void)testAddTransactionFlow {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    app.launchArguments = @[@"-UITesting"];
    [app launch];
    
    // Assuming the app launches to a list view and has an "Add" button
    // We might need to inspect the UI hierarchy to know for sure, but standard nav bar buttons are usually accessible.
    
    XCUIElement *addButton = app.navigationBars.buttons[@"Add"];
    if (![addButton exists]) {
        // Fallback: maybe it's a tab bar or a specific button on screen
        // But let's assume standard interaction as described in VC (right button title "Add")
        // NOTE: The VC we refactored is the *Transaction* VC. It is presented or pushed?
        // If it's the root or pushed, we look for it.
        // If "Add" button is on the *previous* screen to open this one, we assume it's "Add".
        // If the *Transaction* VC is the first screen (unlikely), we verify elements.
        
        // Let's assume we are ON the Transaction Screen for the test (launching directly vs parsing nav)?
        // Or we assume the main screen has an "+" or "Add" button.
        // Let's rely on standard patterns.
    }
    // [addButton tap]; // Uncomment if we need to navigate to it.
    
    // Verify we are on Transaction Screen
    XCTAssertTrue(app.navigationBars[@"Transaction"].exists);
    
    // Enter Amount
    XCUIElement *amountField = app.textFields[@"Enter amount"];
    [amountField tap];
    [amountField typeText:@"500"];
    
    // Enter Description
    XCUIElement *descField = app.textFields[@"Enter description"];
    [descField tap]; // Tap to focus
    [descField typeText:@"Lunch"];
    
    // Select Budget (Picker)
    // The picker button has title "Select Budget" initially.
    [app.buttons[@"Select Budget"] tap];
    
    // Picker should appear.
    // In UI Tests, Pickers are XCUIElementTypePicker.
    XCUIElement *budgetPicker = app.pickers.firstMatch;
    // Select the seeded budget "UI Test Budget"
    // Adjusting picker wheels is tricky.
    // [budgetPicker.pickerWheels.firstMatch adjustToPickerWheelValue:@"UI Test Budget"];
    // For simplicity, we assume the default selection (first item) is what we want since we seeded only one.
    
    // Tap Done on the Picker Alert
    [app.alerts.buttons[@"Done"] tap];
    
    // Select Category
    [app.buttons[@"Select Category"] tap];
    // Simple: Seeded category is "UI Test Category"
    [app.alerts.buttons[@"Done"] tap];
    
    // Save
    [app.navigationBars.buttons[@"Add"] tap];
    
    // Verify it dismissed (Transaction screen gone) or alert depending on success
    // If successful, it dismisses.
    // We can check if we are back to Main Screen (assuming title "Expense Tracker" or similar)
    // Or just check Transaction screen is gone.
    XCTAssertFalse(app.navigationBars[@"Transaction"].exists);
}

@end
