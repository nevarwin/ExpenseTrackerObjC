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

static inline NSString *ETStringFromNumberOrString(id obj, NSString *defaultString) {
    if ([obj isKindOfClass:[NSString class]]) {
        return (NSString *)obj;
    }
    if ([obj isKindOfClass:[NSDecimalNumber class]] || [obj isKindOfClass:[NSNumber class]]) {
        return [(NSNumber *)obj stringValue];
    }
    return defaultString;
}

@interface BudgetDisplayViewController () <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>

@end

@implementation BudgetDisplayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Set background color to match Health app
    self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];
    self.title = self.isEditMode ? @"Edit Budget" : @"Add Budget";
    
    // Build a lookup dictionary for allocations by category objectID
    NSMutableDictionary *allocationByCategoryID = [NSMutableDictionary dictionary];
    for (BudgetAllocation *allocation in self.budget.allocations) {
        allocationByCategoryID[allocation.category] = allocation;
        NSLog(@"allocationByCategoryID: %@", allocationByCategoryID);
    }
    
    // Usage in viewDidLoad
    self.income = [NSMutableArray array];
    self.expenses = [NSMutableArray array];
    self.incomeAmounts = [NSMutableArray array];
    self.expensesAmounts = [NSMutableArray array];
    self.incomeUsedAmounts = [NSMutableArray array];
    self.expensesUsedAmounts = [NSMutableArray array];

    for (Category *category in self.budget.category) {
        [self processCategory:category isIncome:category.isIncome];
    }
    
    self.headerLabelTextField.delegate = self;
    self.rightButton.enabled = self.headerLabelTextField.text.length == 0 ? NO : YES;
    [self setupHeaderView];
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

// Helper method to process a category
- (void)processCategory:(Category *)category isIncome:(BOOL)isIncome {
    NSMutableArray *names = isIncome ? self.income : self.expenses;
    NSMutableArray *amounts = isIncome ? self.incomeAmounts : self.expensesAmounts;
    NSMutableArray *usedAmounts = isIncome ? self.incomeUsedAmounts : self.expensesUsedAmounts;

    [names addObject:category.name];
    if (category.allocations.count > 0) {
        for (BudgetAllocation *allocation in category.allocations) {
            [amounts addObject:allocation.allocatedAmount ?: [NSDecimalNumber zero]];
            [usedAmounts addObject:allocation.usedAmount ?: [NSDecimalNumber zero]];
        }
    } else {
        // Add default zero if no allocations
        [amounts addObject:[NSDecimalNumber zero]];
        [usedAmounts addObject:[NSDecimalNumber zero]];
    }
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
    self.headerLabelTextField.placeholder = @"Budget Name";
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
    UITableViewCell *cell = (UITableViewCell *)textField.superview.superview;
    NSIndexPath *indexPath = [self.budgetDisplayTableView indexPathForCell:cell];
    NSString *attributeKey = textField.accessibilityIdentifier;
    
    if (attributeKey) {
        // Handle expense/income value update here
        if (indexPath.section == 0) {
            self.expensesAmounts[indexPath.row] = textField.text;
        } else {
            self.incomeAmounts[indexPath.row] = textField.text;
        }
    } else {
        self.budget.name = textField.text ?: @"";
    }
}


#pragma mark - UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) return self.expenses.count;
    if (section == 1) return self.income.count;
    return 0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSLog(@"tableView indexPath: %@", indexPath);
    
    [self plusButtonTapped:nil indexPath:indexPath];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        // Expense attributes
        NSString *expenseName = (indexPath.row < self.expenses.count) ? self.expenses[indexPath.row] : @"";
        NSDecimalNumber *expenseAmount = (indexPath.row < self.expensesAmounts.count) ? self.expensesAmounts[indexPath.row] : [NSDecimalNumber zero];
        NSDecimalNumber *expenseUsedAmount = (indexPath.row < self.expensesUsedAmounts.count) ? self.expensesUsedAmounts[indexPath.row] : [NSDecimalNumber zero];
        
        return [self configuredTextFieldCellForTableView:tableView
                                               indexPath:indexPath
                                             placeholder:expenseName
                                            keyboardType:UIKeyboardTypeDecimalPad
                                                   value:expenseAmount
                                              usedAmount:expenseUsedAmount
        ];
    } else if (indexPath.section == 1) {
        // Income attributes
        NSString *incomeName = (indexPath.row < self.income.count) ? self.income[indexPath.row] : @"";
        NSDecimalNumber *incomeAmount = (indexPath.row < self.incomeAmounts.count) ? self.incomeAmounts[indexPath.row] : [NSDecimalNumber zero];
        NSDecimalNumber *incomeUsedAmount = (indexPath.row < self.incomeUsedAmounts.count) ? self.incomeUsedAmounts[indexPath.row] : [NSDecimalNumber zero];
        
        return [self configuredTextFieldCellForTableView:tableView
                                               indexPath:indexPath
                                             placeholder:incomeName
                                            keyboardType:UIKeyboardTypeDecimalPad
                                                   value:incomeAmount
                                              usedAmount:incomeUsedAmount
        ];
        
    }
    return [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"TextFieldCell"];
}

- (UITableViewCell *)configuredTextFieldCellForTableView:(UITableView *)tableView
                                               indexPath:(NSIndexPath *)indexPath
                                             placeholder:(NSString *)placeholder
                                            keyboardType:(UIKeyboardType)keyboardType
                                                   value:(NSDecimalNumber *)value
                                              usedAmount:(NSDecimalNumber *)usedAmount
{
    static NSString *cellIdentifier = @"TextFieldCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    cell.textLabel.text = placeholder;
//    cell.detailTextLabel.text = [NSString stringWithFormat:@"Used Amount: %@", [(NSDecimalNumber *)usedAmount stringValue]];
    cell.detailTextLabel.textColor = [UIColor systemGrayColor];
    
    NSInteger tag = 100;
    UITextField *textField = [cell.contentView viewWithTag:tag];
    
    if (!textField) {
        textField = [[UITextField alloc] init];
        textField.tag = tag;
        textField.translatesAutoresizingMaskIntoConstraints = NO;
        textField.font = [UIFont monospacedDigitSystemFontOfSize:17 weight:UIFontWeightRegular];
        textField.textAlignment = NSTextAlignmentRight;
        textField.textColor = [UIColor systemTealColor];
        textField.delegate = self;
        [textField addTarget:self action:@selector(textFieldChanged:) forControlEvents:UIControlEventEditingChanged];
        
        UILabel *pesoLabel = [[UILabel alloc] init];
        pesoLabel.text = @"₱";
        pesoLabel.font = textField.font;
        pesoLabel.textAlignment = NSTextAlignmentLeft;
        pesoLabel.textColor = [UIColor systemTealColor];
        [pesoLabel sizeToFit];
        
        textField.leftView = pesoLabel;
        textField.leftViewMode = UITextFieldViewModeAlways;
        
        [cell.contentView addSubview:textField];
        
        [NSLayoutConstraint activateConstraints:@[
            [textField.centerYAnchor constraintEqualToAnchor:cell.contentView.centerYAnchor],
            [textField.trailingAnchor constraintEqualToAnchor:cell.contentView.trailingAnchor constant:-16],
            [textField.widthAnchor constraintEqualToConstant:80]
        ]];
    }
    
    NSString *usedAmountString = ETStringFromNumberOrString(usedAmount, @"0");
    cell.detailTextLabel.text = [NSString stringWithFormat:@"Used Amount: %@", usedAmountString];

    // Configure the text each time
    textField.text = ETStringFromNumberOrString(value, @"");
    
    textField.placeholder = placeholder;
    textField.keyboardType = keyboardType;
    textField.accessibilityIdentifier = (indexPath.section == 0) ? @"expenseAmount" : @"incomeAmount";
    
    return cell;
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *headerView = [[UIView alloc] init];
    headerView.backgroundColor = [UIColor clearColor];
    
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    titleLabel.font = [UIFont boldSystemFontOfSize:[UIFont preferredFontForTextStyle:UIFontTextStyleFootnote].pointSize];
    titleLabel.textColor = [UIColor secondaryLabelColor];
    titleLabel.textAlignment = NSTextAlignmentLeft;
    [titleLabel setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [titleLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    
    NSDecimalNumber *totalExpense = [self.expensesAmounts valueForKeyPath:@"@sum.self"];
    NSDecimalNumber *totalIncome = [self.incomeAmounts valueForKeyPath:@"@sum.self"];
    
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterCurrencyStyle;
    
    NSString *formattedExpenses = [formatter stringFromNumber:totalExpense];
    NSString *formattedIncome = [formatter stringFromNumber:totalIncome];
    
    NSString *expensesTitleLabel = [NSString stringWithFormat:@"EXPENSES - %@", formattedExpenses];
    NSString *incomeTitleLabel = [NSString stringWithFormat:@"INCOME - %@", formattedIncome];
    
    switch (section) {
        case 0:
            titleLabel.text = expensesTitleLabel;
            break;
        case 1:
            titleLabel.text = incomeTitleLabel;
            break;
        default:
            titleLabel.text = @"";
    }
    
    [headerView addSubview:titleLabel];
    
    NSMutableArray<NSLayoutConstraint *> *constraints = [NSMutableArray array];
    
    [constraints addObjectsFromArray:@[
        [titleLabel.leadingAnchor constraintEqualToAnchor:headerView.leadingAnchor constant:16],
        [titleLabel.centerYAnchor constraintEqualToAnchor:headerView.centerYAnchor]
    ]];
    
    if (section == 0 || section == 1) {
        UIButton *plusButton = [UIButton buttonWithType:UIButtonTypeContactAdd];
        plusButton.translatesAutoresizingMaskIntoConstraints = NO;
        plusButton.tag = section;
        [plusButton addTarget:self action:@selector(plusButtonTapped:indexPath:) forControlEvents:UIControlEventTouchUpInside];
        [headerView addSubview:plusButton];
        
        [constraints addObjectsFromArray:@[
            [plusButton.trailingAnchor constraintEqualToAnchor:headerView.trailingAnchor constant:-16],
            [plusButton.centerYAnchor constraintEqualToAnchor:headerView.centerYAnchor],
            [titleLabel.trailingAnchor constraintLessThanOrEqualToAnchor:plusButton.leadingAnchor constant:-8]
        ]];
    } else {
        [constraints addObject:[titleLabel.trailingAnchor constraintLessThanOrEqualToAnchor:headerView.trailingAnchor constant:-16]];
    }
    
    // Fixed height
    [constraints addObject:[headerView.heightAnchor constraintEqualToConstant:44]];
    [NSLayoutConstraint activateConstraints:constraints];
    
    return headerView;
}

// Deleting via swipe gesture
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle != UITableViewCellEditingStyleDelete) {
        NSLog(@"editingStyle: %ld", (long)editingStyle);
        return;
    }
    if(indexPath.section == 0){
        [self.expenses removeObjectAtIndex:indexPath.row];
        [self.expensesAmounts removeObjectAtIndex:indexPath.row];
        if (indexPath.row < self.expensesUsedAmounts.count) {
            [self.expensesUsedAmounts removeObjectAtIndex:indexPath.row];
        }
    } else {
        [self.income removeObjectAtIndex:indexPath.row];
        [self.incomeAmounts removeObjectAtIndex:indexPath.row];
        if (indexPath.row < self.incomeUsedAmounts.count) {
            [self.incomeUsedAmounts removeObjectAtIndex:indexPath.row];
        }
    }
    [self.budgetDisplayTableView reloadData];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}


#pragma mark - Actions

- (void)plusButtonTapped:(UIButton *)sender indexPath:(NSIndexPath *)indexPath {
    NSInteger section = sender.tag;
    NSInteger row = NSNotFound;
    NSString *actionTitle = @"Add";
    
    if ([indexPath isKindOfClass:[NSIndexPath class]]) {
        NSIndexPath *correctIndexPath = (NSIndexPath *)indexPath;
        row = correctIndexPath.row;
        section = correctIndexPath.section;
        actionTitle = @"Update";
    }
    
    
    NSString *title = (section == 0) ? @"Expense" : @"Income";
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:@"Enter details"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"Enter name";
        if (row != NSNotFound) {
            if (section == 0) {
                if (row < self.expenses.count) {
                    textField.text = self.expenses[row];
                }
            } else if (section == 1) {
                if (row < self.income.count) {
                    textField.text = self.income[row];
                }
            }
        }
    }];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        UILabel *pesoLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 16, 20)];
        pesoLabel.text = @"₱";
        pesoLabel.font = textField.font;
        pesoLabel.textAlignment = NSTextAlignmentLeft;
        pesoLabel.textColor = [UIColor systemTealColor];
        
        textField.leftView = pesoLabel;
        textField.leftViewMode = UITextFieldViewModeAlways;
        textField.placeholder = @"Enter amount";
        textField.keyboardType = UIKeyboardTypeDecimalPad;
        if (row != NSNotFound) {
            if (section == 0) {
                if (row < self.expensesAmounts.count) {
                    id value = self.expensesAmounts[row];
                    if ([value isKindOfClass:[NSDecimalNumber class]]) {
                        textField.text = [(NSDecimalNumber *)value stringValue];
                    } else if ([value isKindOfClass:[NSString class]]) {
                        textField.text = (NSString *)value;
                    } else {
                        textField.text = @"";
                    }
                }
            } else if (section == 1) {
                if (row < self.incomeAmounts.count) {
                    id value = self.incomeAmounts[row];
                    if ([value isKindOfClass:[NSDecimalNumber class]]) {
                        textField.text = [(NSDecimalNumber *)value stringValue];
                    } else if ([value isKindOfClass:[NSString class]]) {
                        textField.text = (NSString *)value;
                    } else {
                        textField.text = @"";
                    }
                }
            }
        }
    }];
    
    UIAlertAction *ok = [UIAlertAction actionWithTitle:actionTitle
                                                 style:UIAlertActionStyleDefault
                                               handler:^(UIAlertAction * _Nonnull action) {
        UITextField *nameField = alert.textFields.firstObject;
        UITextField *amountField = alert.textFields[1];
        
        NSString *name = nameField.text;
        NSString *amount = amountField.text;
        
        if (name.length <= 0 && amount.length <= 0) {
            return;
        }
        
        if ([actionTitle isEqual:@"Update"]) {
            if (row == NSNotFound) {
                return; // Safety: should not happen, but avoid using an invalid row
            }
            if (section == 0) {
                if (row < self.expenses.count) self.expenses[row] = name;
                if (row < self.expensesAmounts.count) self.expensesAmounts[row] = amount;
            } else {
                if (row < self.income.count) self.income[row] = name;
                if (row < self.incomeAmounts.count) self.incomeAmounts[row] = amount;
            }
        } else {
            if (section == 0) {
                [self.expenses addObject:name ?: @""];
                [self.expensesAmounts addObject:amount ?: @""];
                [self.expensesUsedAmounts addObject:[NSDecimalNumber zero]];
            } else {
                [self.income addObject:name ?: @""];
                [self.incomeAmounts addObject:amount ?: @""];
                [self.incomeUsedAmounts addObject:[NSDecimalNumber zero]];
            }
        }
        
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:section];
        [self.budgetDisplayTableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
    }];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel"
                                                     style:UIAlertActionStyleCancel
                                                   handler:nil];
    
    [alert addAction:cancel];
    [alert addAction:ok];
    
    [self presentViewController:alert animated:YES completion:nil];
}


- (void)addButtonTapped {
    NSString *budgetName = self.headerLabelTextField.text;
    NSDecimalNumber *totalAmount = [NSDecimalNumber decimalNumberWithString:@"0"];
    
    for (NSDecimalNumber *amount in self.incomeAmounts){
        totalAmount = [totalAmount decimalNumberByAdding:amount];
    }
    
    
    if (budgetName.length == 0) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Invalid budget name"
                                                                       message:@"Please enter a valid budget name."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK"
                                                     style:UIAlertActionStyleDefault
                                                   handler:nil];
        
        [alert addAction:ok];
        
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    
    if (self.expenses.count == 0 || self.income.count == 0) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Invalid expense or income"
                                                                       message:@"Please enter a valid expense or income."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK"
                                                     style:UIAlertActionStyleDefault
                                                   handler:nil];
        
        [alert addAction:ok];
        
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    
    NSManagedObjectContext *context = [[CoreDataManager sharedManager] viewContext];
    Budget *budget = self.isEditMode ? self.budget : [NSEntityDescription insertNewObjectForEntityForName:@"Budget" inManagedObjectContext:context];
    
    budget.name = budgetName;
    budget.createdAt = [NSDate date];
    budget.totalAmount = totalAmount;
    
    NSMutableSet *categoriesSet = [NSMutableSet set];
    
    for (NSInteger i = 0; i < self.expenses.count; i++) {
        Category *expenseCategory = [NSEntityDescription insertNewObjectForEntityForName:@"Category" inManagedObjectContext:context];
        expenseCategory.name = self.expenses[i];
        expenseCategory.isIncome = NO;
        expenseCategory.createdAt = [NSDate date];
        
        BudgetAllocation *expenseAllocation = [NSEntityDescription insertNewObjectForEntityForName:@"BudgetAllocation" inManagedObjectContext:context];
        
        id value = self.expensesAmounts[i];
        if ([value isKindOfClass:[NSDecimalNumber class]]) {
            expenseAllocation.allocatedAmount = value;
        } else if ([value isKindOfClass:[NSString class]]) {
            expenseAllocation.allocatedAmount = [NSDecimalNumber decimalNumberWithString:(NSString *)value];
        } else {
            expenseAllocation.allocatedAmount = [NSDecimalNumber zero];
        }
        
        expenseAllocation.createdAt = [NSDate date];
        
        expenseCategory.allocations = [NSSet setWithObject:expenseAllocation];
        [categoriesSet addObject:expenseCategory];
    }
    
    for (NSInteger i = 0; i < self.income.count; i++) {
        Category *incomeCategory = [NSEntityDescription insertNewObjectForEntityForName:@"Category" inManagedObjectContext:context];
        incomeCategory.name = self.income[i];
        incomeCategory.isIncome = YES;
        incomeCategory.createdAt = [NSDate date];
        
        BudgetAllocation *incomeAllocation = [NSEntityDescription insertNewObjectForEntityForName:@"BudgetAllocation" inManagedObjectContext:context];
        
        id value = self.incomeAmounts[i];
        if ([value isKindOfClass:[NSDecimalNumber class]]) {
            incomeAllocation.allocatedAmount = value;
        } else if ([value isKindOfClass:[NSString class]]) {
            incomeAllocation.allocatedAmount = [NSDecimalNumber decimalNumberWithString:(NSString *)value];
        } else {
            incomeAllocation.allocatedAmount = [NSDecimalNumber zero];
        }
        
        incomeAllocation.createdAt = [NSDate date];
        
        incomeCategory.allocations = [NSSet setWithObject:incomeAllocation];
        [categoriesSet addObject:incomeCategory];
    }
    
    budget.category = categoriesSet;
    
    // Save context
    NSError *error = nil;
    if (![context save:&error]) {
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

- (void)selectEmptyScreen {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    tap.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tap];
}

- (void)dismissKeyboard {
    [self.view endEditing:YES];
}

@end


