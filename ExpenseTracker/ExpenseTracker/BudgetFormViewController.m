//
//  BudgetFormViewController.m
//  ExpenseTracker
//
//  Created by raven on 8/6/25.
//

#import "CoreDataManager.h"
#import "BudgetFormViewController.h"
#import <CoreData/CoreData.h>

@interface BudgetFormViewController () <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>

@end

@implementation BudgetFormViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    NSManagedObjectContext *context = [[CoreDataManager sharedManager] viewContext];
    NSError *error = nil;
    
    // Income Fetch Request
    NSFetchRequest *incomeFetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Category"];
    incomeFetchRequest.resultType = NSManagedObjectResultType;
    incomeFetchRequest.propertiesToFetch = nil;
    incomeFetchRequest.predicate = [NSPredicate predicateWithFormat:@"isIncome == YES"];

    self.income = [context executeFetchRequest:incomeFetchRequest error:&error];
    if (error) {
        NSLog(@"Error fetching income categories: %@", error.localizedDescription);
    }
    
    // Expense Fetch Request
    NSFetchRequest *expenseFetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Category"];
    expenseFetchRequest.resultType = NSManagedObjectResultType;
    expenseFetchRequest.propertiesToFetch = nil;
    expenseFetchRequest.predicate = [NSPredicate predicateWithFormat:@"isIncome == NO"];

    self.expenses = [context executeFetchRequest:expenseFetchRequest error:&error];
    if (error) {
        NSLog(@"Error fetching expense categories: %@", error.localizedDescription);
    }
    
    // Initialize properties
    self.budgetName = @"";
    
    // Setup UI
    self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];
    self.title = @"Add Budget";
    
    // Navigation bar buttons
    self.rightButton = [[UIBarButtonItem alloc]
                        initWithTitle:@"Save"
                        style:UIBarButtonItemStyleDone
                        target:self
                        action:@selector(rightButtonTapped)];
    self.navigationItem.rightBarButtonItem = self.rightButton;
    
    // Disable save button initially until form is valid
    self.rightButton.enabled = NO;
    
    // Setup table view
    [self setupTableView];
    [self selectEmptyScreen];
    
    // Add observer for keyboard notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
}

- (void)setupTableView {
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero
                                                  style:UITableViewStyleInsetGrouped];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [UIColor systemGroupedBackgroundColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    [self.view addSubview:self.tableView];
    
    // Register cell classes
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"TextFieldCell"];
    
    // Setup constraints
    [NSLayoutConstraint activateConstraints:@[
        [self.tableView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];
    
}

#pragma mark - Keyboard Notifications
// Keyboard handlers
- (void)keyboardWillShow:(NSNotification *)notification {
    CGRect kbFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat kbHeight = kbFrame.size.height;
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, kbHeight, 0);
    self.tableView.scrollIndicatorInsets = self.tableView.contentInset;
}

- (void)keyboardWillHide:(NSNotification *)notification {
    self.tableView.contentInset = UIEdgeInsetsZero;
    self.tableView.scrollIndicatorInsets = UIEdgeInsetsZero;
}

// UITextFieldDelegate
- (void)textFieldDidBeginEditing:(UITextField *)textField {
    UITableViewCell *cell = (UITableViewCell *)textField.superview.superview;
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    [self.tableView scrollToRowAtIndexPath:indexPath
                          atScrollPosition:UITableViewScrollPositionMiddle
                                  animated:YES];
}

- (void)selectEmptyScreen {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    tap.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tap];
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) return 1;
    if (section == 1) return 1;
    if (section == 2) return 1;
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // cellForRowAtIndexPath
    if (indexPath.section == 0) {
        // Only one row for budget name
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TextFieldCell" forIndexPath:indexPath];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        for (UIView *subview in cell.contentView.subviews) {
            [subview removeFromSuperview];
        }
        UITextField *textField = [[UITextField alloc] init];
        textField.translatesAutoresizingMaskIntoConstraints = NO;
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.placeholder = @"Budget Name";
        textField.text = self.budgetName;
        textField.delegate = self;
        [textField addTarget:self action:@selector(textFieldChanged:) forControlEvents:UIControlEventEditingChanged];
        [cell.contentView addSubview:textField];
        [NSLayoutConstraint activateConstraints:@[
            [textField.topAnchor constraintEqualToAnchor:cell.contentView.topAnchor],
            [textField.leadingAnchor constraintEqualToAnchor:cell.contentView.leadingAnchor constant:16],
            [textField.trailingAnchor constraintEqualToAnchor:cell.contentView.trailingAnchor constant:-16],
            [textField.bottomAnchor constraintEqualToAnchor:cell.contentView.bottomAnchor]
        ]];
        return cell;
    } else if (indexPath.section == 1) {
        // Expense attributes
        NSString *attributeName = self.expenses[indexPath.row];
        return [self configuredTextFieldCellForTableView:tableView
                                               indexPath:indexPath
                                             placeholder:[attributeName capitalizedString]
                                            keyboardType:UIKeyboardTypeDecimalPad
                                           attributeName:attributeName];
    } else if (indexPath.section == 2) {
        // Income attributes
        NSString *attributeName = self.income[indexPath.row];
        return [self configuredTextFieldCellForTableView:tableView
                                               indexPath:indexPath
                                             placeholder:[attributeName capitalizedString]
                                            keyboardType:UIKeyboardTypeDecimalPad
                                           attributeName:attributeName];
    }
    return [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DefaultCell"];
}

- (UITableViewCell *)configuredTextFieldCellForTableView:(UITableView *)tableView
                                               indexPath:(NSIndexPath *)indexPath
                                             placeholder:(NSString *)placeholder
                                            keyboardType:(UIKeyboardType)keyboardType
                                           attributeName:(NSString *)attributeName {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TextFieldCell" forIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    // Remove old views
    for (UIView *subview in cell.contentView.subviews) {
        [subview removeFromSuperview];
    }
    
    UITextField *textField = [[UITextField alloc] init];
    textField.delegate = self;
    textField.translatesAutoresizingMaskIntoConstraints = NO;
    textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    textField.tag = 100 + indexPath.row;
    textField.placeholder = placeholder;
    textField.keyboardType = keyboardType;
    textField.accessibilityIdentifier = attributeName; // store key for later use
    [textField addTarget:self action:@selector(textFieldChanged:) forControlEvents:UIControlEventEditingChanged];
    
    [cell.contentView addSubview:textField];
    
    [NSLayoutConstraint activateConstraints:@[
        [textField.topAnchor constraintEqualToAnchor:cell.contentView.topAnchor],
        [textField.leadingAnchor constraintEqualToAnchor:cell.contentView.leadingAnchor constant:16],
        [textField.trailingAnchor constraintEqualToAnchor:cell.contentView.trailingAnchor constant:-16],
        [textField.bottomAnchor constraintEqualToAnchor:cell.contentView.bottomAnchor]
    ]];
    
    return cell;
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return @"BUDGET DETAILS";
        case 1:
            return @"EXPENSES";
        case 2:
            return @"INCOME";
        default:
            return nil;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == 0) {
        return @"Enter a name for your budget";
    }
    return nil;
}

#pragma mark - UITextFieldDelegate
- (BOOL)textField:(UITextField *)textField
shouldChangeCharactersInRange:(NSRange)range
replacementString:(NSString *)string{
    if (textField.keyboardType == UIKeyboardTypeDecimalPad) {
        NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
        NSString *digitsOnly = [[newString componentsSeparatedByCharactersInSet:
                                 [[NSCharacterSet decimalDigitCharacterSet] invertedSet]]
                                componentsJoinedByString:@""];
        if (digitsOnly.length > 8) {
            return NO;
        }
    }
    
    if (textField.keyboardType == UIKeyboardTypeAlphabet){
        // Define the maximum character limit
        NSInteger maxLength = 10; // Change this to your desired limit
        
        // Calculate the new length of the text
        NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
        
        // Check if the new length exceeds the limit
        return newString.length <= maxLength;
    }
    return YES;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44;
}


#pragma mark - Event Handlers

- (void)textFieldChanged:(UITextField *)textField {
    NSString *attributeKey = textField.accessibilityIdentifier;
    if (attributeKey) {
        // Expense or income field
        NSDecimalNumber *decimalValue = [NSDecimalNumber decimalNumberWithString:textField.text];
    } else {
        // Budget name field
        self.budgetName = textField.text ?: @"";
    }
    
    
    [self validateForm];
}

- (void)validateForm {
    BOOL hasBudgetName = self.budgetName.length > 0;
    
    // Check at least one valid income value
    BOOL hasValidIncome = NO;
    for (NSString *key in self.income) {
        NSDecimalNumber *value = 0;
        if (value && [value isKindOfClass:[NSDecimalNumber class]] &&
            ![value isEqualToNumber:[NSDecimalNumber notANumber]] &&
            [value compare:[NSDecimalNumber zero]] == NSOrderedDescending) {
            hasValidIncome = YES;
            break;
        }
    }
    
    // Check at least one valid expense value
    BOOL hasValidExpense = NO;
    for (NSString *key in self.expenses) {
        NSDecimalNumber *value = 0;
        if (value && [value isKindOfClass:[NSDecimalNumber class]] &&
            ![value isEqualToNumber:[NSDecimalNumber notANumber]] &&
            [value compare:[NSDecimalNumber zero]] == NSOrderedDescending) {
            hasValidExpense = YES;
            break;
        }
    }
    
    self.rightButton.enabled = hasBudgetName && hasValidIncome && hasValidExpense;
}

#pragma mark - Actions

- (void)rightButtonTapped {
    // Create Budget object
    NSManagedObject *budget = [NSEntityDescription insertNewObjectForEntityForName:@"Budget" inManagedObjectContext:self.managedObjectContext];
    [budget setValue:self.budgetName forKey:@"name"];
    [budget setValue:[NSDate date] forKey:@"createdAt"];
    
    // Create Expenses object
    NSManagedObject *expenses = [NSEntityDescription insertNewObjectForEntityForName:@"Category" inManagedObjectContext:self.managedObjectContext];
    for (NSString *key in self.expenses) {
        [expenses setValue:self.expenses forKey:key];
    }
    
    // Save context
    NSError *error = nil;
    if (![self.managedObjectContext save:&error]) {
        NSLog(@"Failed to save budget: %@", error);
    }
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)dismissKeyboard {
    [self.view endEditing:YES];
}

@end
