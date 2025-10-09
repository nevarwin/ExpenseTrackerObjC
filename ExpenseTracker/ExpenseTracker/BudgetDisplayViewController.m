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
#import "Transaction+CoreDataClass.h"
#import "BudgetAllocation+CoreDataClass.h"
#import "CoreDataManager.h"
#import "AppDelegate.h"
#import "UIViewController+Alerts.h"
#import "PickerModalViewController.h"
#import "CurrencyFormatterUtil.h"

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
    // TODO: Add installment logic
    self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];
    self.title = self.isEditMode ? @"Budget" : @"Add Budget";
    
    
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
    
    if (self.isEditMode) {
        [self setupYearHeaderView];
        [self initializeCurrentDate];
        self.yearHeaderView.hidden = !self.isEditMode;
    }
    
    [self setupHeaderView];
    [self setupBudgetInfoTableView];
    [self setupTableView];
    [self selectEmptyScreen];
    
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
    [self.budgetDisplayTableView reloadData];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    // Adjust height based on content
    self.budgetInfoTableViewHeightConstraint.constant = self.budgetInfoTableView.contentSize.height;
}


# pragma mark - Helper

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
// TODO: Update the fetching based on the month and year
- (void)didTapPreviousMonth {
    self.currentDateComponents.month -= 1;
    if (self.currentDateComponents.month < 1) {
        self.currentDateComponents.month = 12;
        self.currentDateComponents.year -= 1;
    }
    [self updateHeaderLabels];
}

- (void)didTapNextMonth {
    self.currentDateComponents.month += 1;
    if (self.currentDateComponents.month > 12) {
        self.currentDateComponents.month = 1;
        self.currentDateComponents.year += 1;
    }
    [self updateHeaderLabels];
}

- (void)showYearPicker {
    NSInteger startYear = 2000;
    NSInteger range = 50; // 2000–2049
    
    NSMutableArray *years = [NSMutableArray array];
    for (NSInteger i = 0; i < range; i++) {
        [years addObject:[NSString stringWithFormat:@"%ld", (long)(startYear + i)]];
    }
    
    PickerModalViewController *vc = [[PickerModalViewController alloc] init];
    vc.items = years;
    vc.selectedIndex = self.currentDateComponents.year - startYear;
    
    __weak typeof(self) weakSelf = self;
    vc.onDone = ^(NSInteger selectedIndex) {
        weakSelf.currentDateComponents.year = startYear + selectedIndex;
        [weakSelf updateHeaderLabels];
        [self updateHeaderLabels];
    };
    
    [self presentViewController:vc animated:YES completion:nil];
}


- (void)showMonthPicker {
    NSArray *months = @[@"January",@"February",@"March",@"April",@"May",@"June",
                        @"July",@"August",@"September",@"October",@"November",@"December"];
    
    PickerModalViewController *vc = [[PickerModalViewController alloc] init];
    vc.items = months;
    vc.selectedIndex = self.currentDateComponents.month - 1; // 1-based → 0-based
    
    __weak typeof(self) weakSelf = self;
    vc.onDone = ^(NSInteger selectedIndex) {
        weakSelf.currentDateComponents.month = selectedIndex + 1;
        [weakSelf updateHeaderLabels];
        [self updateHeaderLabels];
    };
    
    [self presentViewController:vc animated:YES completion:nil];
}


- (void)initializeCurrentDate {
    NSDate *today = [NSDate date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    self.currentDateComponents = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth fromDate:today];
    [self updateHeaderLabels];
}


- (void)updateHeaderLabels {
    NSArray *months = @[@"January",@"February",@"March",@"April",@"May",@"June",
                        @"July",@"August",@"September",@"October",@"November",@"December"];
    NSInteger monthIndex = self.currentDateComponents.month - 1;
    self.monthLabel.text = months[monthIndex];
    self.yearLabel.text = [NSString stringWithFormat:@"%ld", (long)self.currentDateComponents.year];
}

- (NSInteger)weekIndexForTodayInMonth:(NSInteger)month year:(NSInteger)year {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    calendar.firstWeekday = 2; // Monday
    
    // First day of month
    NSDateComponents *components = [[NSDateComponents alloc] init];
    components.year = year;
    components.month = month;
    components.day = 1;
    NSDate *startOfMonth = [calendar dateFromComponents:components];
    
    // Find first Monday *inside* the month
    NSDateComponents *weekdayComponents = [calendar components:NSCalendarUnitWeekday fromDate:startOfMonth];
    NSInteger weekday = weekdayComponents.weekday;
    NSInteger daysToAdd = (weekday == 2) ? 0 : (9 - weekday) % 7;
    NSDate *firstMonday = [calendar dateByAddingUnit:NSCalendarUnitDay
                                               value:daysToAdd
                                              toDate:startOfMonth
                                             options:0];
    
    // Today
    NSDate *today = [NSDate date];
    NSDateComponents *todayComp = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth fromDate:today];
    
    // Only compute if it's the same month & year
    if (todayComp.year == year && todayComp.month == month) {
        NSInteger daysDiff = [calendar components:NSCalendarUnitDay
                                         fromDate:firstMonday
                                           toDate:today
                                          options:0].day;
        if (daysDiff >= 0) {
            return daysDiff / 7; // week index (0-based)
        }
    }
    return 0; // default to week 0 if not current month
}

- (UILabel *)createLabelWithText:(NSString *)text bold:(BOOL)bold {
    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.text = text;
    label.font = bold ? [UIFont systemFontOfSize:16 weight:UIFontWeightBold] : [UIFont systemFontOfSize:14];
    label.textColor = [UIColor labelColor];
    return label;
}

- (NSString *)expensesAmountLabel{
    NSDecimalNumber *totalExpense = [self.expensesAmounts valueForKeyPath:@"@sum.self"];
    NSString *formattedExpenses = [[CurrencyFormatterUtil currencyFormatter] stringFromNumber:totalExpense];
    return formattedExpenses;
}

- (NSDecimalNumber *)incomeAmountLabel{
    NSDecimalNumber *totalIncomeUsed = [self.incomeUsedAmounts valueForKeyPath:@"@sum.self"];
    NSDecimalNumber *totalIncome = [self.incomeAmounts valueForKeyPath:@"@sum.self"];
    NSDecimalNumber *toDisplay = [totalIncomeUsed isEqualToNumber:[NSDecimalNumber zero]] ? totalIncome : totalIncomeUsed;
    return toDisplay;
}

- (NSDecimalNumber *)sumOfArray:(NSArray<NSDecimalNumber *> *)numbers {
    NSDecimalNumber *total = [NSDecimalNumber zero];
    for (NSDecimalNumber *num in numbers) {
        total = [total decimalNumberByAdding:num ?: [NSDecimalNumber zero]];
    }
    return total;
}

- (NSDecimalNumber *)totalUsedBudget {
    NSDecimalNumber *expenseUsedTotal = [self sumOfArray:self.expensesUsedAmounts];
    return expenseUsedTotal;
}

- (NSString *)totalBudget {
    NSDecimalNumber *netTotal = [[self incomeAmountLabel] decimalNumberBySubtracting:[self totalUsedBudget]];
    return [[CurrencyFormatterUtil currencyFormatter] stringFromNumber:netTotal];
}

- (NSArray<Category *> *)categoriesWithTransactionsForCurrentMonth {
    // Convert to NSArray
    NSArray *allTransactions = [self.budget.transactions allObjects];
    
    // Build start and end of month
    NSDateComponents *components = [[NSDateComponents alloc] init];
    components.year = self.currentDateComponents.year;
    components.month = self.currentDateComponents.month;
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *startOfMonth = [calendar dateFromComponents:components];
    
    NSDateComponents *nextMonthComponents = [[NSDateComponents alloc] init];
    nextMonthComponents.month = 1;
    NSDate *endOfMonth = [calendar dateByAddingComponents:nextMonthComponents toDate:startOfMonth options:0];
    
    // Filter transactions for current month
    NSPredicate *datePredicate = [NSPredicate predicateWithFormat:@"date >= %@ AND date < %@", startOfMonth, endOfMonth];
    NSArray *filteredTransactions = [allTransactions filteredArrayUsingPredicate:datePredicate];
    
    // Sort by transaction date
    NSSortDescriptor *sortByDate = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES];
    NSArray *sortedTransactions = [filteredTransactions sortedArrayUsingDescriptors:@[sortByDate]];
    
    // Collect categories from transactions, preserving order
    NSMutableOrderedSet<Category *> *orderedCategories = [NSMutableOrderedSet orderedSet];
    for (Transaction *txn in sortedTransactions) {
        if (txn.category) {
            [orderedCategories addObject:txn.category];
        }
    }
    
    return [orderedCategories array];
}




# pragma mark - SetUps

- (void)setupHeaderView {
    self.headerLabelTextField = [[UITextField alloc] init];
    self.headerLabelTextField.translatesAutoresizingMaskIntoConstraints = NO;
    self.headerLabelTextField.text = self.budget.name;
    self.headerLabelTextField.font = [UIFont systemFontOfSize:34 weight:UIFontWeightBold];
    self.headerLabelTextField.textColor = [UIColor labelColor];
    self.headerLabelTextField.placeholder = @"Budget Name";
    [self.view addSubview:self.headerLabelTextField];
    
    // Navigation bar buttons
    self.rightButton = [[UIBarButtonItem alloc]
                        initWithTitle:@"Save"
                        style:UIBarButtonItemStyleDone
                        target:self
                        action:@selector(saveButtonTapped)];
    self.navigationItem.rightBarButtonItem = self.rightButton;
    
    CGFloat horizontalPadding = 20.0;
    [NSLayoutConstraint activateConstraints:@[
        self.isEditMode ? [self.headerLabelTextField.topAnchor constraintEqualToAnchor:self.yearHeaderView.bottomAnchor constant:8] : [self.headerLabelTextField.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.headerLabelTextField.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:horizontalPadding],
        [self.headerLabelTextField.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-horizontalPadding]
    ]];
    
    [self.headerLabelTextField setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [self.headerLabelTextField setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
}

- (void)setupBudgetInfoTableView {
    self.budgetInfoTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleInsetGrouped];
    self.budgetInfoTableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.budgetInfoTableView.delegate = self;
    self.budgetInfoTableView.dataSource = self;
    self.budgetInfoTableView.scrollEnabled = NO;
    self.budgetInfoTableView.allowsSelection = NO;
    self.budgetInfoTableView.editing = NO;
    [self.view addSubview:self.budgetInfoTableView];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.budgetInfoTableView.topAnchor constraintEqualToAnchor:self.headerLabelTextField.bottomAnchor],
        [self.budgetInfoTableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.budgetInfoTableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
    ]];
    // Create height constraint (initially 0)
    self.budgetInfoTableViewHeightConstraint = [self.budgetInfoTableView.heightAnchor constraintEqualToConstant:0];
    self.budgetInfoTableViewHeightConstraint.active = YES;
}

- (void)setupTableView {
    self.budgetDisplayTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleInsetGrouped];
    self.budgetDisplayTableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.budgetDisplayTableView.delegate = self;
    self.budgetDisplayTableView.dataSource = self;
    [self.view addSubview:self.budgetDisplayTableView];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.budgetDisplayTableView.topAnchor constraintEqualToAnchor:self.budgetInfoTableView.bottomAnchor],
        [self.budgetDisplayTableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.budgetDisplayTableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.budgetDisplayTableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-16.0]
    ]];
}

- (void)setupYearHeaderView {
    // --- Container for header ---
    self.yearHeaderView = [[UIView alloc] init];
    self.yearHeaderView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.yearHeaderView];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.yearHeaderView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.yearHeaderView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16.0],
        [self.yearHeaderView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16.0],
        [self.yearHeaderView.heightAnchor constraintEqualToConstant:40.0]
    ]];
    
    // --- Left button ---
    UIButton *leftButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [leftButton setTitle:@"◀︎" forState:UIControlStateNormal];
    leftButton.titleLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightBold];
    leftButton.translatesAutoresizingMaskIntoConstraints = NO;
    [leftButton addTarget:self action:@selector(didTapPreviousMonth) forControlEvents:UIControlEventTouchUpInside];
    [self.yearHeaderView addSubview:leftButton];
    
    // --- Right button ---
    UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [rightButton setTitle:@"▶︎" forState:UIControlStateNormal];
    rightButton.titleLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightBold];
    rightButton.translatesAutoresizingMaskIntoConstraints = NO;
    [rightButton addTarget:self action:@selector(didTapNextMonth) forControlEvents:UIControlEventTouchUpInside];
    [self.yearHeaderView addSubview:rightButton];
    
    // --- Month label ---
    self.monthLabel = [[UILabel alloc] init];
    self.monthLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.monthLabel.font = [UIFont systemFontOfSize:22 weight:UIFontWeightSemibold];
    self.monthLabel.textAlignment = NSTextAlignmentCenter;
    self.monthLabel.userInteractionEnabled = YES;
    [self.yearHeaderView addSubview:self.monthLabel];
    
    UITapGestureRecognizer *monthTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showMonthPicker)];
    [self.monthLabel addGestureRecognizer:monthTap];
    
    // --- Year label ---
    self.yearLabel = [[UILabel alloc] init];
    self.yearLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.yearLabel.font = [UIFont systemFontOfSize:22 weight:UIFontWeightSemibold];
    self.yearLabel.textAlignment = NSTextAlignmentCenter;
    self.yearLabel.userInteractionEnabled = YES;
    [self.yearHeaderView addSubview:self.yearLabel];
    
    UITapGestureRecognizer *yearTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showYearPicker)];
    [self.yearLabel addGestureRecognizer:yearTap];
    
    // --- Hidden textfields to show pickers ---
    self.monthTextField = [[UITextField alloc] initWithFrame:CGRectZero];
    self.yearTextField = [[UITextField alloc] initWithFrame:CGRectZero];
    [self.view addSubview:self.monthTextField];
    [self.view addSubview:self.yearTextField];
    
    // --- Layout ---
    [NSLayoutConstraint activateConstraints:@[
        [leftButton.centerYAnchor constraintEqualToAnchor:self.yearHeaderView.centerYAnchor],
        [leftButton.leadingAnchor constraintEqualToAnchor:self.yearHeaderView.leadingAnchor],
        [leftButton.widthAnchor constraintEqualToConstant:40],
        
        [rightButton.centerYAnchor constraintEqualToAnchor:self.yearHeaderView.centerYAnchor],
        [rightButton.trailingAnchor constraintEqualToAnchor:self.yearHeaderView.trailingAnchor],
        [rightButton.widthAnchor constraintEqualToConstant:40],
        
        [self.monthLabel.centerYAnchor constraintEqualToAnchor:self.yearHeaderView.centerYAnchor],
        [self.monthLabel.trailingAnchor constraintEqualToAnchor:self.yearLabel.leadingAnchor constant:-8.0],
        
        [self.yearLabel.centerYAnchor constraintEqualToAnchor:self.yearHeaderView.centerYAnchor],
        [self.yearLabel.centerXAnchor constraintEqualToAnchor:self.yearHeaderView.centerXAnchor constant:40.0]
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
    if (tableView == self.budgetInfoTableView) return 1;
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.budgetDisplayTableView){
        if (section == 0) return self.expenses.count;
        if (section == 1) return self.income.count;
    }
    if (tableView == self.budgetInfoTableView) return 4;
    return 0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.budgetInfoTableView) return;
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self plusButtonTapped:nil indexPath:indexPath];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.budgetInfoTableView) {
        static NSString *cellIdentifier = @"BudgetInfoCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        
        if (!cell){
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        
        switch (indexPath.row) {
            case 0:
                cell.textLabel.text = @"Remaining Budget";
                cell.detailTextLabel.text = [self totalBudget];
                break;
            case 1:
                cell.textLabel.text = @"Total Used Budget";
                cell.detailTextLabel.text = [[[CurrencyFormatterUtil currencyFormatter] stringFromNumber:[self totalUsedBudget]] copy];
                break;
            case 2:
                cell.textLabel.text = @"Expenses";
                cell.detailTextLabel.text = [self expensesAmountLabel];
                break;
            case 3:
                cell.textLabel.text = @"Income";
                cell.detailTextLabel.text = [[[CurrencyFormatterUtil currencyFormatter] stringFromNumber:[self incomeAmountLabel]] copy];
                break;
            default:
                break;
        }
        
        return cell;
    }
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
    
    // Convert both to NSNumber for safe comparison
    NSNumber *usedAmountNum = ([usedAmount isKindOfClass:[NSNumber class]]) ? usedAmount : @([[usedAmount description] doubleValue]);
    NSNumber *valueNum = ([value isKindOfClass:[NSNumber class]]) ? value : @([[value description] doubleValue]);
    NSNumber *remainingAmount = @([valueNum doubleValue] - [usedAmountNum doubleValue]);
    
    // Format the strings
    NSString *usedAmountString = ETStringFromNumberOrString(usedAmount, @"0");
    NSString *remainingAmountString = ETStringFromNumberOrString(remainingAmount, @"0");
    
    // Full texts
    NSString *usedAmountText = [NSString stringWithFormat:@"Used Amount: %@", usedAmountString];
    NSString *remainingAmountText = [NSString stringWithFormat:@"Remaining Amount: %@", remainingAmountString];
    
    // Build one combined string with a newline
    NSString *combinedText = [NSString stringWithFormat:@"%@\n%@", usedAmountText, remainingAmountText];
    NSMutableAttributedString *attributedCombinedText = [[NSMutableAttributedString alloc] initWithString:combinedText];
    
    // Find ranges
    NSRange usedRange = [combinedText rangeOfString:usedAmountString];
    NSRange remainingRange = [combinedText rangeOfString:remainingAmountString];
    
    // Decide color for used amount
    UIColor *amountColor = ([usedAmountNum compare:valueNum] == NSOrderedDescending) ?
    [UIColor colorWithRed:220.0/255.0
                    green:53.0/255.0
                     blue:69.0/255.0
                    alpha:1.0] :
    (([usedAmountNum isEqualToNumber:@0]) ?
     [UIColor systemGrayColor] :
     [UIColor colorWithRed:40.0/255.0
                     green:167.0/255.0
                      blue:69.0/255.0
                     alpha:1.0]);
    
    // Apply colors
    [attributedCombinedText addAttribute:NSForegroundColorAttributeName value:[UIColor labelColor] range:usedRange];
    [attributedCombinedText addAttribute:NSForegroundColorAttributeName value:amountColor range:remainingRange];
    
    // Use multiline in label
    cell.detailTextLabel.numberOfLines = 0; // allow wrapping
    cell.detailTextLabel.attributedText = attributedCombinedText;
    
    // Configure text field
    textField.text = ETStringFromNumberOrString(value, @"");
    
    textField.placeholder = placeholder;
    textField.keyboardType = keyboardType;
    textField.accessibilityIdentifier = (indexPath.section == 0) ? @"expenseAmount" : @"incomeAmount";
    
    return cell;
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (tableView == self.budgetInfoTableView) return nil;
    UIView *headerView = [[UIView alloc] init];
    headerView.backgroundColor = [UIColor clearColor];
    
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    titleLabel.font = [UIFont boldSystemFontOfSize:[UIFont preferredFontForTextStyle:UIFontTextStyleFootnote].pointSize];
    titleLabel.textColor = [UIColor secondaryLabelColor];
    titleLabel.textAlignment = NSTextAlignmentLeft;
    [titleLabel setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [titleLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    
    NSString *expensesTitleLabel = [NSString stringWithFormat:@"EXPENSES - %@", [self expensesAmountLabel]];
    NSString *incomeTitleLabel = [NSString stringWithFormat:@"INCOME - %@",
                                  [[CurrencyFormatterUtil currencyFormatter] stringFromNumber:[self incomeAmountLabel]]];
    
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
    if (tableView == self.budgetInfoTableView) return;
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
    [self.budgetInfoTableView reloadData];
    [self.budgetDisplayTableView reloadData];
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (tableView == self.budgetInfoTableView) return nil;
    NSInteger lastSection = [tableView numberOfSections] - 1;
    
    if (section != lastSection) {
        return nil;
    }
    
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 50)];
    footerView.backgroundColor = [UIColor clearColor];
    
    UIButton *exportButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [exportButton setTitle:@"Export Budget" forState:UIControlStateNormal];
    exportButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    exportButton.translatesAutoresizingMaskIntoConstraints = NO;
    exportButton.tag = section;
    
    [exportButton addTarget:self action:@selector(exportButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    
    [footerView addSubview:exportButton];
    
    [NSLayoutConstraint activateConstraints:@[
        [exportButton.centerXAnchor constraintEqualToAnchor:footerView.centerXAnchor],
        [exportButton.centerYAnchor constraintEqualToAnchor:footerView.centerYAnchor],
    ]];
    
    return footerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (tableView == self.budgetInfoTableView) return 0.01f;
    NSInteger lastSection = [tableView numberOfSections] - 1;
    if (section == lastSection) {
        return 50;
    }
    return 0.01f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.budgetInfoTableView) return 40;
    return 80;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.budgetInfoTableView) {
        return NO;
    }
    return YES;
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
    
    // TODO: Make the name unique and add validation, max characters
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
        
        if (name.length <= 0 || amount.length <= 0) {
            [self showAlertWithTitle:@"Warning" message:@"All fields are required."];
            return;
        }
        
        if ([actionTitle isEqual:@"Update"]) {
            if (row == NSNotFound) {
                return;
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
        [self.budgetInfoTableView reloadData];
        [self.budgetDisplayTableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
    }];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel"
                                                     style:UIAlertActionStyleCancel
                                                   handler:nil];
    
    [alert addAction:cancel];
    [alert addAction:ok];
    
    [self presentViewController:alert animated:YES completion:nil];
}


- (void)saveButtonTapped {
    NSString *budgetName = self.headerLabelTextField.text;
    NSDecimalNumber *totalAmount = [NSDecimalNumber decimalNumberWithString:@"0"];
    
    for (NSDecimalNumber *amount in self.incomeAmounts){
        totalAmount = [totalAmount decimalNumberByAdding:amount];
    }
    
    
    if (budgetName.length == 0) {
        [self showAlertWithTitle:@"Invalid budget name" message:@"Please enter a valid budget name."];
        return;
    }
    
    if (self.expenses.count == 0 || self.income.count == 0) {
        [self showAlertWithTitle:@"Invalid expense or income" message:@"Please enter a valid expense or income."];
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
        
        id usedAmount = self.expensesUsedAmounts[i];
        if ([usedAmount isKindOfClass:[NSDecimalNumber class]]) {
            expenseAllocation.usedAmount = usedAmount;
        } else if ([usedAmount isKindOfClass:[NSString class]]) {
            expenseAllocation.usedAmount = [NSDecimalNumber decimalNumberWithString:(NSString *)usedAmount];
        } else {
            expenseAllocation.usedAmount = [NSDecimalNumber zero];
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
        
        id usedAmount = self.incomeUsedAmounts[i];
        if ([usedAmount isKindOfClass:[NSDecimalNumber class]]) {
            incomeAllocation.usedAmount = usedAmount;
        } else if ([usedAmount isKindOfClass:[NSString class]]) {
            incomeAllocation.usedAmount = [NSDecimalNumber decimalNumberWithString:(NSString *)usedAmount];
        } else {
            incomeAllocation.usedAmount = [NSDecimalNumber zero];
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
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSPersistentContainer *persistentContainer = appDelegate.persistentContainer;
    
    NSPersistentStore *store = persistentContainer.persistentStoreCoordinator.persistentStores.firstObject;
    NSLog(@"Core Data store URL: %@", store.URL);
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)exportButtonTapped{
    
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


