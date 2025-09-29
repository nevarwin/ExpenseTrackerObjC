// ExpenseTracker/ExpenseTracker/TransactionsViewController.m

#import "TransactionsViewController.h"
#import "AppDelegate.h"
#import "CoreDataManager.h"
#import "Budget+CoreDataClass.h"
#import "Category+CoreDataClass.h"
#import "BudgetAllocation+CoreDataClass.h"
#import "Transaction+CoreDataClass.h"
#import "PickerModalViewController.h"

@interface TransactionsViewController () <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource>
@property (nonatomic, assign) BOOL isDatePickerVisible;
@property (nonatomic, strong) NSDictionary *selectedBudget;
@property (nonatomic, strong) NSDictionary *selectedCategory;
@end

@implementation TransactionsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.amountTextField.delegate = self;
    self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];
    
    self.title = @"Transaction";
    NSString *rightButtonTitle = self.isEditMode ? @"Update" : @"Add";
    self.leftButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(leftButtonTapped)];
    self.rightButton = [[UIBarButtonItem alloc] initWithTitle:rightButtonTitle style:UIBarButtonItemStyleDone target:self action:@selector(rightButtonTapped)];
    self.navigationItem.leftBarButtonItem = self.leftButton;
    self.navigationItem.rightBarButtonItem = self.rightButton;
    self.selectedTypeIndex = 3;
    
    [self setupTableView];
    [self setupPickers];
    [self selectEmptyScreen];
    [self fetchCoreData];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self configureViewForMode];
}

- (void)setupTableView {
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleInsetGrouped];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.tableView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];
}

- (void)setupPickers {
    self.datePicker = [[UIDatePicker alloc] init];
    self.datePicker.datePickerMode = UIDatePickerModeDateAndTime;
    self.datePicker.locale = [NSLocale localeWithLocaleIdentifier:@"en_US"];
    self.categoryPicker = [[UIPickerView alloc] init];
    self.categoryPicker.delegate = self;
    self.categoryPicker.dataSource = self;
    self.amountTextField = [[UITextField alloc] init];
    self.amountTextField.placeholder = @"Enter amount";
    self.amountTextField.keyboardType = UIKeyboardTypeDecimalPad;
    self.amountTextField.delegate = self;
    self.typeValues = @[@"Expense", @"Income"];
    self.typePicker = [[UIPickerView alloc] init];
    self.typePicker.delegate = self;
    self.typePicker.dataSource = self;
}

- (void)selectEmptyScreen {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    tap.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tap];
}

- (void)fetchCoreData {
    NSManagedObjectContext *context = [[CoreDataManager sharedManager] viewContext];
    NSError *error = nil;
    self.budgets = [self getBudgetValues:context error:&error];
    self.category = [self getCategoryValues:context error:&error isIncome: self.selectedTypeIndex];
}


#pragma mark - UITextFieldDelegate
- (BOOL)textField:(UITextField *)textField
shouldChangeCharactersInRange:(NSRange)range
replacementString:(NSString *)string {
    if (textField == self.amountTextField) {
        NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
        NSString *digitsOnly = [[newString componentsSeparatedByCharactersInSet:
                                 [[NSCharacterSet decimalDigitCharacterSet] invertedSet]]
                                componentsJoinedByString:@""];
        if (digitsOnly.length > 8) {
            return NO;
        }
    }
    return YES;
}

#pragma mark - Configure View for Edit Mode
- (void)configureViewForMode {
    NSManagedObjectContext *context = [[CoreDataManager sharedManager] viewContext];
    NSError *error = nil;
    
    if (self.isEditMode && self.existingTransaction) {
        // Amount
        self.amountTextField.text = [NSString stringWithFormat:@"%@", self.existingTransaction.amount];
        
        // Date
        [self.datePicker setDate:self.existingTransaction.date];
        
        // Type
        self.selectedTypeIndex = self.existingTransaction.category.isIncome;
        UIButton *typeButton = [self buttonForRow:3];
        typeButton.enabled = YES;
        [typeButton setTitle:self.typeValues[self.selectedTypeIndex] forState:UIControlStateNormal];
        
        // Budget
        self.budgetValues = [self getBudgetValues:context error:&error];
        self.selectedBudgetIndex = self.existingTransaction.budget.objectID;
        UIButton *budgetButton = [self buttonForRow:2];
        if (self.existingTransaction.budget.objectID) {
            [budgetButton setTitle:self.existingTransaction.budget.name forState:UIControlStateNormal];
        }
        
        // Category
        self.category = [self getCategoryValues:context error:&error isIncome:self.existingTransaction.category.isIncome];
        self.categoryValues = [self.category valueForKey:@"name"];
        
        self.selectedCategoryIndex = self.existingTransaction.category.objectID;
        
        UIButton *categoryButton = [self buttonForRow:4];
        categoryButton.enabled = YES;
        if (self.existingTransaction.category.objectID) {
            [categoryButton setTitle:self.existingTransaction.category.name forState:UIControlStateNormal];
        }
    }
}

#pragma mark - Helper
- (UIButton *)buttonForRow:(NSInteger)row {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    for (UIView *view in cell.contentView.subviews) {
        if ([view isKindOfClass:[UIButton class]]) {
            return (UIButton *)view;
        }
    }
    return nil;
}

- (NSArray<NSDictionary *> *)getBudgetValues:(NSManagedObjectContext *)context error:(NSError **)error {
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Budget"];
    fetchRequest.resultType = NSManagedObjectResultType;
    fetchRequest.propertiesToFetch = nil;
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"isActive == YES"];
    
    NSArray<Budget *> *results = [context executeFetchRequest:fetchRequest error:error];
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

- (NSArray<NSDictionary *> *)getCategoryValues:(NSManagedObjectContext *)context error:(NSError **)error isIncome:(NSInteger)isIncome {
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Category"];
    fetchRequest.resultType = NSManagedObjectResultType;
    fetchRequest.propertiesToFetch = nil;
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"isIncome == %@", @(isIncome)];
    
    NSArray<Category *> *results = [context executeFetchRequest:fetchRequest error:error];
    if (!results) return nil;
    NSMutableArray *categoryArray = [NSMutableArray array];
    for (Category *category in results) {
        if (category.name && self.selectedBudgetIndex == category.budget.objectID && self.selectedBudgetIndex != nil) {
            [categoryArray addObject:@{
                @"name": category.name,
                @"objectID": category.objectID,
                @"isIncome": @(category.isIncome)
            }];
        }
    }
    return [categoryArray copy];
}

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:ok];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)saveTransactionWithAmount:(NSDecimalNumber *)amount
                             date:(NSDate *)date
                           budget:(Budget *)budget
                         category:(Category *)category
                             type:(BOOL)type {
    
    NSManagedObjectContext *context = [[CoreDataManager sharedManager] viewContext];
    
    Transaction *transaction = self.isEditMode ? self.existingTransaction :
    [NSEntityDescription insertNewObjectForEntityForName:@"Transaction"
                                  inManagedObjectContext:context];
    
    transaction.amount = amount;
    transaction.date = date;
    transaction.budget = budget;
    transaction.category = category;
    transaction.category.isIncome = type;
    
    NSError *error = nil;
    if (![context save:&error]) {
        NSLog(@"Failed to save transaction: %@", error);
    } else {
        NSLog(@"Transaction saved: %@", transaction);
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}




#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return 1; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return 5; }

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellId = @"FormCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellId];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    for (UIView *subview in cell.contentView.subviews) {
        [subview removeFromSuperview];
        
    }
    
    switch (indexPath.row) {
        case 0: // Date
            cell.textLabel.text = @"Date";
            [cell.contentView addSubview:self.datePicker];
            self.datePicker.translatesAutoresizingMaskIntoConstraints = NO;
            [NSLayoutConstraint activateConstraints:@[
                [self.datePicker.trailingAnchor constraintEqualToAnchor:cell.contentView.trailingAnchor constant:-16],
                [self.datePicker.centerYAnchor constraintEqualToAnchor:cell.contentView.centerYAnchor],
            ]];
            break;
        case 1: // Amount
        {
            UILabel *pesoLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 16, 20)];
            pesoLabel.text = @"₱";
            pesoLabel.font = self.amountTextField.font;
            pesoLabel.textAlignment = NSTextAlignmentLeft;
            pesoLabel.textColor = [UIColor systemTealColor];
            cell.textLabel.text = @"Amount";
            [cell.contentView addSubview:self.amountTextField];
            
            self.amountTextField.leftView = pesoLabel;
            self.amountTextField.leftViewMode = UITextFieldViewModeAlways;
            self.amountTextField.textColor = [UIColor systemTealColor];
            self.amountTextField.translatesAutoresizingMaskIntoConstraints = NO;
            self.amountTextField.font = [UIFont monospacedDigitSystemFontOfSize:17 weight:UIFontWeightRegular];
            self.amountTextField.textAlignment = NSTextAlignmentRight;
            self.amountTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
            [NSLayoutConstraint activateConstraints:@[
                [self.amountTextField.trailingAnchor constraintEqualToAnchor:cell.contentView.trailingAnchor constant:-16],
                [self.amountTextField.centerYAnchor constraintEqualToAnchor:cell.contentView.centerYAnchor],
                [self.amountTextField.widthAnchor constraintEqualToConstant:120]
            ]];
            break;
        }
        case 2: // Budget
        {
            cell.textLabel.text = @"Budget";
            UIButton *typeButton = [UIButton buttonWithType:UIButtonTypeSystem];
            [typeButton setTitle:@"Select Budget" forState:UIControlStateNormal];
            typeButton.translatesAutoresizingMaskIntoConstraints = NO;
            typeButton.tag = 0;
            typeButton.enabled = self.budgets.count == 0 ? NO : YES;
            [typeButton addTarget:self action:@selector(pickerButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
            [cell.contentView addSubview:typeButton];
            
            [NSLayoutConstraint activateConstraints:@[
                [typeButton.trailingAnchor constraintEqualToAnchor:cell.contentView.trailingAnchor constant:-16],
                [typeButton.centerYAnchor constraintEqualToAnchor:cell.contentView.centerYAnchor]
            ]];
            break;
        }
        case 3: // Type
        {
            cell.textLabel.text = @"Type";
            UIButton *typeButton = [UIButton buttonWithType:UIButtonTypeSystem];
            [typeButton setTitle:@"Select Type" forState:UIControlStateNormal];
            typeButton.translatesAutoresizingMaskIntoConstraints = NO;
            typeButton.tag = 1;
            typeButton.enabled = self.selectedBudgetIndex == nil ? NO : YES;
            [typeButton addTarget:self action:@selector(pickerButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
            [cell.contentView addSubview:typeButton];
            
            [NSLayoutConstraint activateConstraints:@[
                [typeButton.trailingAnchor constraintEqualToAnchor:cell.contentView.trailingAnchor constant:-16],
                [typeButton.centerYAnchor constraintEqualToAnchor:cell.contentView.centerYAnchor]
            ]];
            break;
        }
        case 4: // Category
            cell.textLabel.text = @"Category";
            UIButton *typeButton = [UIButton buttonWithType:UIButtonTypeSystem];
            [typeButton setTitle:@"Select Category" forState:UIControlStateNormal];
            typeButton.translatesAutoresizingMaskIntoConstraints = NO;
            typeButton.tag = 2;
            typeButton.enabled = self.selectedTypeIndex == 3 ? NO : YES;
            [typeButton addTarget:self action:@selector(pickerButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
            [cell.contentView addSubview:typeButton];
            
            [NSLayoutConstraint activateConstraints:@[
                [typeButton.trailingAnchor constraintEqualToAnchor:cell.contentView.trailingAnchor constant:-16],
                [typeButton.centerYAnchor constraintEqualToAnchor:cell.contentView.centerYAnchor]
            ]];
            break;
    }
    return cell;
}

#pragma mark - Picker Button

- (NSString *)titleForPickerWithSender:(UIButton *)sender {
    switch (sender.tag) {
        case 0: return @"Budget";
        case 1: return @"Type";
        case 2: return @"Category";
        default: return [sender titleForState:UIControlStateNormal];
    }
}

- (BOOL)checkAndShowEmptyBudgetAlertIfNeeded {
    if (self.currentPickerMode == 0 && self.budgetValues.count == 0) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"An error occurred."
                                                                       message:@"There is no existing budget. Please add a budget to proceed."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK"
                                                     style:UIAlertActionStyleDefault
                                                   handler:nil];
        [alert addAction:ok];
        [self presentViewController:alert animated:YES completion:nil];
        return YES;
    }
    return NO;
}

- (UIPickerView *)createPickerForAlert:(UIAlertController *)alert {
    UIPickerView *picker = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 40, alert.view.bounds.size.width - 20, 140)];
    picker.dataSource = self;
    picker.delegate = self;
    return picker;
}

- (UIAlertAction *)createDoneActionForPicker:(UIPickerView *)picker sender:(UIButton *)sender context:(NSManagedObjectContext *)context {
    return [UIAlertAction actionWithTitle:@"Done" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSInteger selectedRow = [picker selectedRowInComponent:0];
        NSError *error = nil;
        
        switch (sender.tag) {
            case 0: { // Budget
                NSDictionary *selectedBudget = self.budgets[selectedRow];
                self.selectedBudgetIndex = selectedBudget[@"objectID"];
                [sender setTitle:self.budgetValues[selectedRow] forState:UIControlStateNormal];
                
                [self.tableView reloadRowsAtIndexPaths:@[
                    [NSIndexPath indexPathForRow:3 inSection:0],
                    [NSIndexPath indexPathForRow:4 inSection:0]
                ] withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            }
            case 1: { // Type
                self.selectedTypeIndex = selectedRow;
                [sender setTitle:self.typeValues[selectedRow] forState:UIControlStateNormal];
                
                self.category = [self getCategoryValues:context error:&error isIncome:self.selectedTypeIndex];
                [self.tableView reloadRowsAtIndexPaths:@[
                    [NSIndexPath indexPathForRow:4 inSection:0]
                ] withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            }
            case 2: { // Category
                NSDictionary *selectedCategory = self.category[selectedRow];
                self.selectedCategoryIndex = selectedCategory[@"objectID"];
                [sender setTitle:self.categoryValues[selectedRow] forState:UIControlStateNormal];
                break;
            }
            default:
                break;
        }
    }];
}


- (void)pickerButtonTapped:(UIButton *)sender {
    NSManagedObjectContext *context = [[CoreDataManager sharedManager] viewContext];
    self.currentPickerMode = sender.tag;

    PickerModalViewController *pickerVC = [[PickerModalViewController alloc] init];
    pickerVC.modalPresentationStyle = UIModalPresentationPageSheet;

    if (@available(iOS 15.0, *)) {
        UISheetPresentationController *sheet = pickerVC.sheetPresentationController;
        sheet.detents = @[UISheetPresentationControllerDetent.mediumDetent];
        sheet.prefersGrabberVisible = YES;
        sheet.preferredCornerRadius = 16.0;
    }

    if (sender.tag == 0) {
        pickerVC.items = [self.budgets valueForKey:@"name"];
        pickerVC.selectedIndex = 0;
        pickerVC.onDone = ^(NSInteger selectedIndex) {
            NSDictionary *selectedBudget = self.budgets[selectedIndex];
            self.selectedBudgetIndex = selectedBudget[@"objectID"];
            [sender setTitle:selectedBudget[@"name"] forState:UIControlStateNormal];
            [self.tableView reloadRowsAtIndexPaths:@[
                [NSIndexPath indexPathForRow:3 inSection:0],
                [NSIndexPath indexPathForRow:4 inSection:0]
            ] withRowAnimation:UITableViewRowAnimationAutomatic];
        };
    } else if (sender.tag == 1) {
        pickerVC.items = self.typeValues;
        pickerVC.selectedIndex = self.selectedTypeIndex;
        pickerVC.onDone = ^(NSInteger selectedIndex) {
            self.selectedTypeIndex = selectedIndex;
            [sender setTitle:self.typeValues[selectedIndex] forState:UIControlStateNormal];
            self.category = [self getCategoryValues:context error:nil isIncome:self.selectedTypeIndex];
            [self.tableView reloadRowsAtIndexPaths:@[
                [NSIndexPath indexPathForRow:4 inSection:0]
            ] withRowAnimation:UITableViewRowAnimationAutomatic];
        };
    } else if (sender.tag == 2) {
        pickerVC.items = [self.category valueForKey:@"name"];
        pickerVC.selectedIndex = 0;
        pickerVC.onDone = ^(NSInteger selectedIndex) {
            NSDictionary *selectedCategory = self.category[selectedIndex];
            self.selectedCategoryIndex = selectedCategory[@"objectID"];
            [sender setTitle:selectedCategory[@"name"] forState:UIControlStateNormal];
        };
    }

    [self presentViewController:pickerVC animated:YES completion:nil];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
}

#pragma mark - UIPickerViewDataSource/Delegate

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    if(self.currentPickerMode == 0) return self.budgetValues.count;
    if(self.currentPickerMode == 1) return self.typeValues.count;
    if(self.currentPickerMode == 2) return self.categoryValues.count;
    return 0;
}
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if(self.currentPickerMode == 0) return self.budgetValues[row];
    if(self.currentPickerMode == 1) return self.typeValues[row];
    if(self.currentPickerMode == 2) return self.categoryValues[row];
    return 0;
}
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    
}
#pragma mark - Actions

- (void)leftButtonTapped { [self dismissViewControllerAnimated:YES completion:nil]; }
- (void)rightButtonTapped {
    NSManagedObjectContext *context = [[CoreDataManager sharedManager] viewContext];
    NSError *error = nil;
    NSDecimalNumber *totalUsedAmount = [NSDecimalNumber zero];
    BOOL amountOverflow = NO;
    
    NSInteger type = self.selectedTypeIndex;
    NSManagedObjectID *budgetID = self.selectedBudgetIndex;
    NSManagedObjectID *categoryID = self.selectedCategoryIndex;
    
    NSDate *date = self.datePicker.date;
    
    if ([self.amountTextField.text  isEqual: @""] ||
        [self.amountTextField.text  isEqual: @"0"] ||
        self.selectedBudgetIndex == nil ||
        [self.amountTextField.text  isEqual: @""]  ||
        self.selectedCategoryIndex == nil ||
        !date) {
        
        [self showAlertWithTitle:@"Invalid Input" message:@"Please fill all fields correctly."];
        return;
    }
    
    Budget *budget = (Budget *)[context existingObjectWithID:budgetID error:&error];
    Category *category = (Category *)[context existingObjectWithID:categoryID error:&error];
    
    // Parse amount as NSDecimalNumber using NSNumberFormatter for safety
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    NSNumber *amountNumber = [formatter numberFromString:self.amountTextField.text];
    NSDecimalNumber *amount = [NSDecimalNumber decimalNumberWithDecimal:amountNumber.decimalValue];
    
    for (BudgetAllocation *allocation in category.allocations) {
        NSDecimalNumber *usedAmount = allocation.usedAmount ?: [NSDecimalNumber zero];

        if (self.isEditMode){
            usedAmount = [usedAmount decimalNumberBySubtracting:self.existingTransaction.amount];
        }
        
        totalUsedAmount = [usedAmount decimalNumberByAdding:amount];
        
        if ([totalUsedAmount compare:allocation.allocatedAmount] != NSOrderedDescending) {
            allocation.usedAmount = totalUsedAmount;
        } else {
            allocation.usedAmount = totalUsedAmount;
            amountOverflow = YES;
        }
    }
    
    if (amountOverflow) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Amount exceeded"
                                                                       message:@"The amount exceeds the budget allocated, but the transaction will still be saved."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK"
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * _Nonnull action) {
            [self saveTransactionWithAmount:amount
                                       date:date
                                     budget:budget
                                   category:category
                                       type:type];
        }];
        
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel"
                                                         style:UIAlertActionStyleCancel
                                                       handler:nil];
        
        [alert addAction:cancel];
        [alert addAction:ok];
        
        [self presentViewController:alert animated:YES completion:nil];
        
        return;
    }
    
    [self saveTransactionWithAmount:amount
                               date:date
                             budget:budget
                           category:category
                               type:type];
}

- (void)dismissKeyboard {
    [self.view endEditing:YES];
}

@end
