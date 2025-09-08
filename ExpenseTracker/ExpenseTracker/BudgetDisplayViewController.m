//
//  BudgetDisplayViewController.m
//  ExpenseTracker
//
//  Created by raven on 8/26/25.
//

#import "BudgetDisplayViewController.h"
#import "Budget+CoreDataClass.h"
#import <HealthKit/HealthKit.h>
#import "Category+CoreDataClass.h"
#import "BudgetAllocation+CoreDataClass.h"
#import "CoreDataManager.h"

#define MAX_HEADER_TEXT_LENGTH 16

@interface BudgetDisplayViewController () <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>

@end

@implementation BudgetDisplayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Set background color to match Health app
    self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];
    
    // Build a lookup dictionary for allocations by category objectID
    NSMutableDictionary *allocationByCategoryID = [NSMutableDictionary dictionary];
    for (BudgetAllocation *allocation in self.budget.allocations) {
        allocationByCategoryID[allocation.category] = allocation;
        NSLog(@"allocationByCategoryID: %@", allocationByCategoryID);
    }
    NSLog(@"allocation: %@", self.budget.allocations);

    self.income = [NSMutableArray array];
    self.expenses = [NSMutableArray array];
    self.incomeAmounts = [NSMutableArray array];
    self.expensesAmounts = [NSMutableArray array];

    for (Category *category in self.budget.category) {
        if (category.isIncome == 1) {
            self.incomeCount++;
            [self.income addObject:category.name];
            BudgetAllocation *allocation = allocationByCategoryID[category.objectID];
            if (allocation) {
                [self.incomeAmounts addObject:allocation.allocatedAmount];
            }
        } else {
            self.expenseCount++;
            [self.expenses addObject:category.name];
            BudgetAllocation *allocation = allocationByCategoryID[category.objectID];
            if (allocation) {
                [self.expensesAmounts addObject:allocation.allocatedAmount];
            }
        }
    }
    
    NSLog(@"incomeAmounts: %@", self.incomeAmounts);
    NSLog(@"expensesAmounts: %@", self.expensesAmounts);
    
    
    self.headerLabelTextField.delegate = self;
    [self setupHeaderView];
    [self setupTableView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
}

- (void)setupHeaderView {
    // Create header container
    self.headerContainer = [[UIView alloc] init];
    _headerContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_headerContainer];
    
    // Setup header label text field (left side)
    self.headerLabelTextField = [[UITextField alloc] init];
    self.headerLabelTextField.translatesAutoresizingMaskIntoConstraints = NO;
    self.headerLabelTextField.text = self.budget.name;
    self.headerLabelTextField.font = [UIFont systemFontOfSize:34 weight:UIFontWeightBold];
    self.headerLabelTextField.textColor = [UIColor labelColor];
    [_headerContainer addSubview:self.headerLabelTextField];
    
    
    // Navigation bar buttons
    self.rightButton = [[UIBarButtonItem alloc]
                        initWithTitle:@"Save"
                        style:UIBarButtonItemStyleDone
                        target:self
                        action:@selector(addButtonTapped)];
    self.navigationItem.rightBarButtonItem = self.rightButton;
    
    // Setup constraints for header container
    [NSLayoutConstraint activateConstraints:@[
        [_headerContainer.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [_headerContainer.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [_headerContainer.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
        [_headerContainer.heightAnchor constraintEqualToConstant:60]
    ]];
    
    // Setup constraints for header label text field
    [NSLayoutConstraint activateConstraints:@[
        [self.headerLabelTextField.leadingAnchor constraintEqualToAnchor:_headerContainer.leadingAnchor],
        [self.headerLabelTextField.centerYAnchor constraintEqualToAnchor:_headerContainer.centerYAnchor],
    ]];
}

- (void)setupTableView {
    self.budgetDisplayTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleInsetGrouped];
    self.budgetDisplayTableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.budgetDisplayTableView.delegate = self;
    self.budgetDisplayTableView.dataSource = self;
    [self.view addSubview:self.budgetDisplayTableView];
    
    [self.budgetDisplayTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"TextFieldCell"];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.budgetDisplayTableView.topAnchor constraintEqualToAnchor:_headerContainer.bottomAnchor],
        [self.budgetDisplayTableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.budgetDisplayTableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.budgetDisplayTableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];
}

#pragma mark - UITextFieldDelegate

// TODO: Add limit to text fields
#define MAXLENGTH 10
- (BOOL)textField:(UITextField *) textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSUInteger oldLength = [textField.text length];
    NSUInteger replacementLength = [string length];
    NSUInteger rangeLength = range.length;
    NSUInteger newLength = oldLength - rangeLength + replacementLength;
    BOOL returnKey = [string rangeOfString: @"\n"].location != NSNotFound;
    return newLength <= MAXLENGTH || returnKey;
}

- (void)textFieldChanged:(UITextField *)textField {
    NSString *attributeKey = textField.accessibilityIdentifier;
    if (attributeKey) {
        // Expense or income field
        NSDecimalNumber *decimalValue = [NSDecimalNumber decimalNumberWithString:textField.text];
        
        //        if ([self.expenseAttributes objectForKey:attributeKey]) {
        //            self.expenseValues[attributeKey] = (decimalValue && ![decimalValue isEqualToNumber:[NSDecimalNumber notANumber]]) ? decimalValue : [NSDecimalNumber zero];
        //
        //        } else if ([self.incomeAttributes objectForKey:attributeKey]) {
        //            self.incomeValues[attributeKey] = (decimalValue && ![decimalValue isEqualToNumber:[NSDecimalNumber notANumber]]) ? decimalValue : [NSDecimalNumber zero];
        //        }
    } else {
        // Budget name field
        self.budget.name = textField.text ?: @"";
    }
}


#pragma mark - UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) return self.expenseCount;
    if (section == 1) return self.incomeCount;
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // cellForRowAtIndexPath
    if (indexPath.section == 0) {
        // Expense attributes
        NSString *expenseName = self.expenses[indexPath.row];
        NSDecimalNumber *expenseAmount = self.expensesAmounts[indexPath.row];
        
        return [self configuredTextFieldCellForTableView:tableView
                                               indexPath:indexPath
                                             placeholder:[expenseName capitalizedString]
                                            keyboardType:UIKeyboardTypeDecimalPad
//                                                   value:expenseAmount
        ];
    } else if (indexPath.section == 1) {
        // Income attributes
        NSString *incomeName = self.income[indexPath.row];
        NSDecimalNumber *incomeAmount = self.incomeAmounts[indexPath.row];
        
        return [self configuredTextFieldCellForTableView:tableView
                                               indexPath:indexPath
                                             placeholder:[incomeName capitalizedString]
                                            keyboardType:UIKeyboardTypeDecimalPad
//                                                   value:incomeAmount
        ];
        
    }
    return [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DefaultCell"];
}

- (UITableViewCell *)configuredTextFieldCellForTableView:(UITableView *)tableView
                                               indexPath:(NSIndexPath *)indexPath
                                             placeholder:(NSString *)placeholder
                                            keyboardType:(UIKeyboardType)keyboardType
//                                                   value:(NSDecimalNumber *)value
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TextFieldCell" forIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.text = placeholder;
    
    // Remove old views
    for (UIView *subview in cell.contentView.subviews) {
        [subview removeFromSuperview];
    }
    
    UITextField *textField = [[UITextField alloc] init];
    textField.delegate = self;
    //    textField.text = value.stringValue;
    textField.translatesAutoresizingMaskIntoConstraints = NO;
    textField.tag = 100 + indexPath.row;
    textField.keyboardType = keyboardType;
    [textField addTarget:self action:@selector(textFieldChanged:) forControlEvents:UIControlEventEditingChanged];
    textField.font = [UIFont monospacedDigitSystemFontOfSize:17 weight:UIFontWeightRegular];
    textField.textAlignment = NSTextAlignmentRight;
    
    [cell.contentView addSubview:textField];
    
    [textField setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [NSLayoutConstraint activateConstraints:@[
        [textField.centerYAnchor constraintEqualToAnchor:cell.contentView.centerYAnchor],
        [textField.trailingAnchor constraintEqualToAnchor:cell.contentView.trailingAnchor constant:-16],
        [textField.widthAnchor constraintEqualToConstant:120],
    ]];
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return @"EXPENSES";
        case 1:
            return @"INCOME";
        default:
            return nil;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44;
}


#pragma mark - Actions

- (void)addButtonTapped {
    if (![self.budget.objectID isEqual:self.budget.objectID]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Invalid"
                                                                       message:@"An error occured."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK"
                                                     style:UIAlertActionStyleDefault
                                                   handler:nil];
        
        [alert addAction:ok];
        
        [self presentViewController:alert animated:YES completion:nil];
    }
    
    // Save context
    NSError *error = nil;
    if (![self.managedObjectContext save:&error]) {
        NSLog(@"Failed to save context: %@", error.localizedDescription);
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"An error occured!"
                                                                       message:@"Failed to save data."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK"
                                                     style:UIAlertActionStyleDefault
                                                   handler:nil];
        
        [alert addAction:ok];
        
        [self presentViewController:alert animated:YES completion:nil];
    }
    
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Keyboard Notifications
// Keyboard handlers
- (void)keyboardWillShow:(NSNotification *)notification {
    CGRect kbFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat kbHeight = kbFrame.size.height;
    self.budgetDisplayTableView.contentInset = UIEdgeInsetsMake(0, 0, kbHeight, 0);
    self.budgetDisplayTableView.scrollIndicatorInsets = self.budgetDisplayTableView.contentInset;
}

- (void)keyboardWillHide:(NSNotification *)notification {
    self.budgetDisplayTableView.contentInset = UIEdgeInsetsZero;
    self.budgetDisplayTableView.scrollIndicatorInsets = UIEdgeInsetsZero;
}

// UITextFieldDelegate
- (void)textFieldDidBeginEditing:(UITextField *)textField {
    UITableViewCell *cell = (UITableViewCell *)textField.superview.superview;
    NSIndexPath *indexPath = [self.budgetDisplayTableView indexPathForCell:cell];
    [self.budgetDisplayTableView scrollToRowAtIndexPath:indexPath
                                       atScrollPosition:UITableViewScrollPositionMiddle
                                               animated:YES];
}


@end
