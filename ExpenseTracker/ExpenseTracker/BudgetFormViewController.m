//
//  BudgetFormViewController.m
//  ExpenseTracker
//
//  Created by raven on 8/6/25.
//

#import "BudgetFormViewController.h"
#import <CoreData/CoreData.h>


@protocol BudgetFormViewControllerDelegate <NSObject>
- (void)budgetFormViewController:(BudgetFormViewController *)controller didSaveBudget:(id)budget;
- (void)budgetFormViewControllerDidCancel:(BudgetFormViewController *)controller;
@end

@interface BudgetFormViewController () <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>

@end

@implementation BudgetFormViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    NSEntityDescription *expenseEntity = [NSEntityDescription entityForName:@"Expenses" inManagedObjectContext:self.managedObjectContext];
    NSEntityDescription *incomeEntity = [NSEntityDescription entityForName:@"Income" inManagedObjectContext:self.managedObjectContext];
    
    self.expenseAttributes = expenseEntity.attributesByName;
    self.incomeAttributes = incomeEntity.attributesByName;
    
    self.expenseValues = [NSMutableDictionary dictionary];
    for (NSString *key in self.expenseAttributes) {
        self.expenseValues[key] = [NSDecimalNumber zero];
    }
    self.incomeValues = [NSMutableDictionary dictionary];
    for (NSString *key in self.incomeAttributes) {
        self.incomeValues[key] = [NSDecimalNumber zero];
    }
    
    // Initialize properties
    self.selectedDate = [NSDate date];
    self.budgetName = @"";
    
    // Setup UI
    self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];
    self.title = self.isEditMode ? @"Edit Budget" : @"Add Budget";
    
    // Navigation bar buttons
    self.leftButton = [[UIBarButtonItem alloc]
                       initWithTitle:@"Cancel"
                       style:UIBarButtonItemStylePlain
                       target:self
                       action:@selector(leftButtonTapped)];
    self.navigationItem.leftBarButtonItem = self.leftButton;
    
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
    
    // Add tap gesture to dismiss keyboard
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]
                                          initWithTarget:self
                                          action:@selector(dismissKeyboard)];
    tapGesture.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tapGesture];
    
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
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"DateCell"];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"TimeCell"];
    
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


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) return 1;
    if (section == 1) return self.expenseAttributes.allKeys.count;
    if (section == 2) return self.incomeAttributes.allKeys.count;
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
        NSArray *expenseKeys = [self.expenseAttributes allKeys];
        NSString *attributeName = expenseKeys[indexPath.row];
        NSDecimalNumber *value = self.expenseValues[attributeName];
        return [self configuredTextFieldCellForTableView:tableView
                                               indexPath:indexPath
                                             placeholder:[attributeName capitalizedString]
                                            keyboardType:UIKeyboardTypeDecimalPad
                                                   value:value
                                           attributeName:attributeName];
    } else if (indexPath.section == 2) {
        // Income attributes
        NSArray *incomeKeys = [self.incomeAttributes allKeys];
        NSString *attributeName = incomeKeys[indexPath.row];
        NSDecimalNumber *value = self.incomeValues[attributeName];
        return [self configuredTextFieldCellForTableView:tableView
                                               indexPath:indexPath
                                             placeholder:[attributeName capitalizedString]
                                            keyboardType:UIKeyboardTypeDecimalPad
                                                   value:value
                                           attributeName:attributeName];
    }
    return [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DefaultCell"];
}

- (UITableViewCell *)configuredTextFieldCellForTableView:(UITableView *)tableView
                                               indexPath:(NSIndexPath *)indexPath
                                             placeholder:(NSString *)placeholder
                                            keyboardType:(UIKeyboardType)keyboardType
                                                   value:(NSDecimalNumber *)value
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
        
        if ([self.expenseAttributes objectForKey:attributeKey]) {
            self.expenseValues[attributeKey] = (decimalValue && ![decimalValue isEqualToNumber:[NSDecimalNumber notANumber]]) ? decimalValue : [NSDecimalNumber zero];
            
        } else if ([self.incomeAttributes objectForKey:attributeKey]) {
            self.incomeValues[attributeKey] = (decimalValue && ![decimalValue isEqualToNumber:[NSDecimalNumber notANumber]]) ? decimalValue : [NSDecimalNumber zero];
        }
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
    for (NSString *key in self.incomeAttributes) {
        NSDecimalNumber *value = self.incomeValues[key];
        if (value && [value isKindOfClass:[NSDecimalNumber class]] &&
            ![value isEqualToNumber:[NSDecimalNumber notANumber]] &&
            [value compare:[NSDecimalNumber zero]] == NSOrderedDescending) {
            hasValidIncome = YES;
            break;
        }
    }
    self.rightButton.enabled = hasBudgetName && hasValidIncome;
}

#pragma mark - Actions

- (void)rightButtonTapped {
    // Create budget object - replace with your actual Budget model
    NSDictionary *budgetData = @{
        @"name": self.budgetName,
        @"date": self.selectedDate
    };
    
    // Notify delegate
    if ([self.delegate respondsToSelector:@selector(budgetFormViewController:didSaveBudget:)]) {
        [self.delegate budgetFormViewController:self didSaveBudget:budgetData];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)leftButtonTapped {
    if ([self.delegate respondsToSelector:@selector(budgetFormViewControllerDidCancel:)]) {
        [self.delegate budgetFormViewControllerDidCancel:self];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)dismissKeyboard {
    [self.view endEditing:YES];
}

@end
