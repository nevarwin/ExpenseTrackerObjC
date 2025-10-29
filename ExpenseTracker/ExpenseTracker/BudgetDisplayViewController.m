//
//  BudgetDisplayViewController.m
//  ExpenseTracker
//
//  Created by raven on 8/26/25.
//

#import "BudgetDisplayViewController.h"
#import "Budget+CoreDataClass.h"
#import "Category+CoreDataClass.h"
#import "Transaction+CoreDataClass.h"
#import "CoreDataManager.h"
#import "AppDelegate.h"
#import "UIViewController+Alerts.h"
#import "PickerModalViewController.h"
#import "CurrencyFormatterUtil.h"
#import "CategoryViewController.h"
#import "UIViewController+Alerts.h"
#import "BudgetCategoryCell.h"

#define MAX_HEADER_TEXT_LENGTH 16

@interface BudgetDisplayViewController () <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>

@end

@implementation BudgetDisplayViewController

# pragma mark - viewDidLoad
- (void)viewDidLoad {
    [super viewDidLoad];
    // TODO: Handle empty state when no categories exist
    self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];
    self.title = self.isEditMode ? @"Budget" : @"Add Budget";
    self.expenseCategories = [NSMutableArray array];
    self.incomeCategories = [NSMutableArray array];
    self.rightButton.enabled = self.headerLabelTextField.text.length == 0 ? NO : YES;
    
    if (self.isEditMode) {
        [self setupYearHeaderView];
        [self initializeCurrentDate];
        self.yearHeaderView.hidden = !self.isEditMode;
        
        for (Category *category in self.budget.category) {
            if (category.isActive){
                if(category.isIncome ){
                    [self.incomeCategories addObject:category];
                } else {
                    [self.expenseCategories addObject:category];
                }
            }
        }
    }
    
    if (@available(iOS 26.0, *)) {
        NSLog(@"This is iOS 26 or newer. Loading new UI.");
    }
    
    [self fetchCategory];
    [self setupHeaderView];
    [self setupBudgetInfoTableView];
    [self setupTableView];
    [self selectEmptyScreen];
    
    [self.budgetDisplayTableView registerClass:[BudgetCategoryCell class]
                        forCellReuseIdentifier:@"BudgetCategoryCell"];
    
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

- (void)fetchCategory {
    [self.expenseCategories removeAllObjects];
    [self.incomeCategories removeAllObjects];
    
    for (Category *category in self.budget.category) {
        [self processCategory:category
                     isIncome:category.isIncome
                        month:self.currentDateComponents.month
                         year:self.currentDateComponents.year];
        
        if (category.isActive) {
            if (category.isIncome) {
                [self.incomeCategories addObject:category];
            } else {
                [self.expenseCategories addObject:category];
            }
        }
    }
    
    [self.budgetInfoTableView reloadData];
    [self.budgetDisplayTableView reloadData];
}

- (void)processCategory:(Category *)category
               isIncome:(BOOL)isIncome
                  month:(NSInteger)month
                   year:(NSInteger)year
{
    if (category.installmentEndDate) {
        BOOL isWithinRange = [self year:year month:month betweenStartDate:category.installmentStartDate andEndDate:category.installmentEndDate];
        
        if (!isWithinRange) {
            category.isActive = NO;
            return;
        }
        category.isActive = YES;
    }
    
    NSArray<Transaction *> *activeTransactions =
    [[category.transactions allObjects] filteredArrayUsingPredicate:
     [NSPredicate predicateWithBlock:^BOOL(Transaction *transaction, NSDictionary *bindings) {
        if (!transaction.isActive) return NO;
        NSDateComponents *components = [[NSCalendar currentCalendar]
                                        components:(NSCalendarUnitMonth | NSCalendarUnitYear)
                                        fromDate:transaction.date];
        return (components.month == month && components.year == year);
    }]];
    
    if (activeTransactions.count > 0) {
        NSDecimalNumber *totalUsed = [NSDecimalNumber zero];
        for (Transaction *transaction in activeTransactions) {
            totalUsed = [totalUsed decimalNumberByAdding:transaction.amount ?: [NSDecimalNumber zero]];
        }
        category.usedAmount = totalUsed;
    } else {
        category.usedAmount = [NSDecimalNumber zero];
    }
}

- (BOOL)year:(NSInteger)year
       month:(NSInteger)month
betweenStartDate:(NSDate *)startDate
  andEndDate:(NSDate *)endDate

{
    // Get the current calendar
    NSCalendar *calendar = [NSCalendar currentCalendar];
    if (startDate) {
        NSDateComponents *startComponents = [calendar components:(NSCalendarUnitMonth | NSCalendarUnitYear)
                                                        fromDate:startDate];
        NSInteger startYear = startComponents.year;
        NSInteger startMonth = startComponents.month;
        
        // Check if it's *before* the start date (which is invalid)
        if (year < startYear) {
            return NO; // Year is too early
        }
        if (year == startYear && month < startMonth) {
            return NO; // Same year, but month is too early
        }
    }
    
    if (endDate) {
        NSDateComponents *endComponents = [calendar components:(NSCalendarUnitMonth | NSCalendarUnitYear)
                                                      fromDate:endDate];
        NSInteger endYear = endComponents.year;
        NSInteger endMonth = endComponents.month;
        
        // Check if it's *after* the end date (which is invalid)
        if (year > endYear) {
            return NO; // Year is too late
        }
        if (year == endYear && month > endMonth) {
            return NO; // Same year, but month is too late
        }
    }
    
    return YES;
}

- (void)didTapPreviousMonth {
    self.currentDateComponents.month -= 1;
    if (self.currentDateComponents.month < 1) {
        self.currentDateComponents.month = 12;
        self.currentDateComponents.year -= 1;
    }
    [self fetchCategory];
    [self updateHeaderLabels];
}

- (void)didTapNextMonth {
    self.currentDateComponents.month += 1;
    if (self.currentDateComponents.month > 12) {
        self.currentDateComponents.month = 1;
        self.currentDateComponents.year += 1;
    }
    [self fetchCategory];
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
        [self fetchCategory];
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
        [self fetchCategory];
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

- (NSString *)expensesAmountLabel {
    NSDecimalNumber *totalExpense = [NSDecimalNumber zero];
    
    for (Category *expense in self.expenseCategories) {
        totalExpense = [totalExpense decimalNumberByAdding:expense.allocatedAmount ?: [NSDecimalNumber zero]];
    }
    
    NSString *formattedExpenses = [[CurrencyFormatterUtil currencyFormatter] stringFromNumber:totalExpense];
    return formattedExpenses;
}

- (NSDecimalNumber *)incomeAmountLabel{
    NSDecimalNumber *totalIncomeUsed = [NSDecimalNumber zero];
    NSDecimalNumber *totalIncome = [NSDecimalNumber zero];
    
    for (Category *income in self.incomeCategories) {
        totalIncomeUsed = [totalIncomeUsed decimalNumberByAdding:income.usedAmount ?: [NSDecimalNumber zero]];
        totalIncome = [totalIncome decimalNumberByAdding:income.allocatedAmount ?: [NSDecimalNumber zero]];
    }
    
    NSDecimalNumber *toDisplay = ([totalIncomeUsed isEqualToNumber:[NSDecimalNumber zero]] || [totalIncome compare:totalIncomeUsed] == NSOrderedDescending) ? totalIncome : totalIncomeUsed;
    return toDisplay;
}

- (NSDecimalNumber *)totalUsedBudget {
    NSDecimalNumber *expenseUsedTotal = [NSDecimalNumber zero];
    
    for (Category *expense in self.expenseCategories) {
        expenseUsedTotal = [expenseUsedTotal decimalNumberByAdding:expense.usedAmount ?: [NSDecimalNumber zero]];
    }
    
    return expenseUsedTotal;
}

- (NSString *)totalBudget {
    NSDecimalNumber *netTotal = [[self incomeAmountLabel] decimalNumberBySubtracting:[self totalUsedBudget]];
    return [[CurrencyFormatterUtil currencyFormatter] stringFromNumber:netTotal];
}


# pragma mark - SetUps

- (void)setupHeaderView {
    self.headerLabelTextField = [[UITextField alloc] init];
    self.headerLabelTextField.delegate = self;
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
    self.yearHeaderView = [[UIView alloc] init];
    self.yearHeaderView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.yearHeaderView];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.yearHeaderView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.yearHeaderView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16.0],
        [self.yearHeaderView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16.0],
        [self.yearHeaderView.heightAnchor constraintEqualToConstant:40.0]
    ]];
    
    UIButton *leftButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [leftButton setTitle:@"◀︎" forState:UIControlStateNormal];
    leftButton.titleLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightBold];
    leftButton.translatesAutoresizingMaskIntoConstraints = NO;
    [leftButton addTarget:self action:@selector(didTapPreviousMonth) forControlEvents:UIControlEventTouchUpInside];
    [self.yearHeaderView addSubview:leftButton];
    
    UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [rightButton setTitle:@"▶︎" forState:UIControlStateNormal];
    rightButton.titleLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightBold];
    rightButton.translatesAutoresizingMaskIntoConstraints = NO;
    [rightButton addTarget:self action:@selector(didTapNextMonth) forControlEvents:UIControlEventTouchUpInside];
    [self.yearHeaderView addSubview:rightButton];
    
    self.monthLabel = [[UILabel alloc] init];
    self.monthLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.monthLabel.font = [UIFont systemFontOfSize:22 weight:UIFontWeightSemibold];
    self.monthLabel.textAlignment = NSTextAlignmentCenter;
    self.monthLabel.userInteractionEnabled = YES;
    [self.yearHeaderView addSubview:self.monthLabel];
    
    UITapGestureRecognizer *monthTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showMonthPicker)];
    [self.monthLabel addGestureRecognizer:monthTap];
    
    self.yearLabel = [[UILabel alloc] init];
    self.yearLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.yearLabel.font = [UIFont systemFontOfSize:22 weight:UIFontWeightSemibold];
    self.yearLabel.textAlignment = NSTextAlignmentCenter;
    self.yearLabel.userInteractionEnabled = YES;
    [self.yearHeaderView addSubview:self.yearLabel];
    
    UITapGestureRecognizer *yearTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showYearPicker)];
    [self.yearLabel addGestureRecognizer:yearTap];
    
    self.monthTextField = [[UITextField alloc] initWithFrame:CGRectZero];
    self.yearTextField = [[UITextField alloc] initWithFrame:CGRectZero];
    [self.view addSubview:self.monthTextField];
    [self.view addSubview:self.yearTextField];
    
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


#pragma mark - UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (tableView == self.budgetInfoTableView) return 1;
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.budgetDisplayTableView){
        if (section == 0) return self.expenseCategories.count;
        if (section == 1) return self.incomeCategories.count;
    }
    if (tableView == self.budgetInfoTableView) return 4;
    return 0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.budgetInfoTableView) return;
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self updateCategoryCell:nil indexPath:indexPath];
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
    
    BudgetCategoryCell *cell = [tableView dequeueReusableCellWithIdentifier:@"BudgetCategoryCell" forIndexPath:indexPath];
    
    if (indexPath.section == 0) {
        // Expense attributes
        Category *expenseCategory = (indexPath.row < self.expenseCategories.count)
        ? self.expenseCategories[indexPath.row]
        : nil;
        
        NSString *expenseName = expenseCategory.name ?: @"";
        NSDecimalNumber *expenseAmount = expenseCategory.allocatedAmount ?: [NSDecimalNumber zero];
        NSDecimalNumber *expenseUsedAmount = expenseCategory.usedAmount ?: [NSDecimalNumber zero];
        
        [cell configureWithPlaceholder:expenseName
                                 value:expenseAmount
                            usedAmount:expenseUsedAmount];
        
    } else if (indexPath.section == 1) {
        // Income attributes
        Category *incomeCategory = (indexPath.row < self.incomeCategories.count)
        ? self.incomeCategories[indexPath.row]
        : nil;
        
        NSString *incomeName = incomeCategory.name ?: @"";
        NSDecimalNumber *incomeAmount = incomeCategory.allocatedAmount ?: [NSDecimalNumber zero];
        NSDecimalNumber *incomeUsedAmount = incomeCategory.usedAmount ?: [NSDecimalNumber zero];
        
        [cell configureWithPlaceholder:incomeName
                                 value:incomeAmount
                            usedAmount:incomeUsedAmount];
        
    }
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
        [plusButton addTarget:self action:@selector(plusButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
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
        [self.expenseCategories removeObjectAtIndex:indexPath.row];
    } else {
        [self.incomeCategories removeObjectAtIndex:indexPath.row];
    }
    [self.budgetDisplayTableView deleteRowsAtIndexPaths:@[indexPath]
                                       withRowAnimation:UITableViewRowAnimationFade];
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
    return 88;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.budgetInfoTableView) {
        return NO;
    }
    return YES;
}



#pragma mark - Actions
- (void)plusButtonTapped:(UIButton *)sender {
    // Present CategoryViewController for adding a new category
    CategoryViewController *categoryVC = [[CategoryViewController alloc] init];
    
    NSManagedObjectContext *context = [[CoreDataManager sharedManager] viewContext];
    Category *newCategory = [NSEntityDescription insertNewObjectForEntityForName:@"Category"
                                                          inManagedObjectContext:context];
    
    categoryVC.isIncome = sender.tag;
    categoryVC.budget = self.budget;
    categoryVC.isEditMode = NO;
    
    categoryVC.onCategoryAdded = ^(Category *category) {
        newCategory.name = category.name;
        newCategory.isInstallment = category.isInstallment;
        newCategory.installmentMonths = category.installmentMonths;
        newCategory.installmentStartDate = category.installmentStartDate;
        newCategory.isIncome = category.isIncome;
        newCategory.monthlyPayment = category.monthlyPayment;
        newCategory.allocatedAmount = category.isInstallment ? category.monthlyPayment : category.allocatedAmount;
        newCategory.createdAt = category.createdAt;
        newCategory.totalInstallmentAmount = category.allocatedAmount;
        newCategory.installmentEndDate = category.installmentEndDate;
        
        if (category.isIncome) {
            [self.incomeCategories addObject:newCategory];
        } else {
            [self.expenseCategories addObject:newCategory];
        }
        
        [self.budgetDisplayTableView reloadData];
        [self.budgetInfoTableView reloadData];
    };
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:categoryVC];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)updateCategoryCell:(UIButton *)sender indexPath:(NSIndexPath *)indexPath {
    Category *categoryToEdit;
    BOOL isIncome;
    if (indexPath.section == 0) {
        isIncome = NO;
        categoryToEdit = self.expenseCategories[indexPath.row];
    } else if (indexPath.section == 1) {
        isIncome = YES;
        categoryToEdit = self.incomeCategories[indexPath.row];
    } else {
        return;
    }
    
    CategoryViewController *categoryVC = [[CategoryViewController alloc] init];
    
    categoryVC.categoryToEdit = categoryToEdit;
    categoryVC.isIncome = isIncome;
    categoryVC.budget = self.budget;
    categoryVC.isEditMode = YES;
    
    categoryVC.onCategoryAdded = ^(Category *category) {
        categoryToEdit.name = category.name;
        categoryToEdit.isInstallment = category.isInstallment;
        categoryToEdit.installmentMonths = category.installmentMonths;
        categoryToEdit.installmentStartDate = category.installmentStartDate;
        categoryToEdit.isIncome = category.isIncome;
        categoryToEdit.monthlyPayment = category.monthlyPayment;
        categoryToEdit.allocatedAmount = category.isInstallment ? category.monthlyPayment : category.allocatedAmount;
        categoryToEdit.createdAt = category.createdAt;
        categoryToEdit.totalInstallmentAmount = category.allocatedAmount;
        categoryToEdit.installmentEndDate = category.installmentEndDate;
        
        [self.budgetDisplayTableView reloadData];
        [self.budgetInfoTableView reloadData];
    };
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:categoryVC];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)saveButtonTapped {
    NSString *budgetName = self.headerLabelTextField.text;
    NSDecimalNumber *totalAmount = [NSDecimalNumber decimalNumberWithString:@"0"];
    
    for (Category *income in self.incomeCategories){
        totalAmount = [totalAmount decimalNumberByAdding:income.allocatedAmount];
    }
    
    if (budgetName.length == 0) {
        [self showAlertWithTitle:@"Invalid budget name" message:@"Please enter a valid budget name."];
        return;
    }
    
    if (self.expenseCategories.count == 0 || self.incomeCategories.count == 0) {
        [self showAlertWithTitle:@"Invalid expense or income" message:@"Please enter a valid expense or income."];
        return;
    }
    
    NSManagedObjectContext *context = [[CoreDataManager sharedManager] viewContext];
    Budget *budget = self.isEditMode ? self.budget : [NSEntityDescription insertNewObjectForEntityForName:@"Budget" inManagedObjectContext:context];
    NSDate *dateNow = [NSDate date];
    
    budget.name = budgetName;
    budget.createdAt = dateNow;
    budget.totalAmount = totalAmount;
    
    NSMutableSet *categoriesSet = [NSMutableSet set];
    
    // Add expense categories
    for (Category *category in self.expenseCategories) {
        NSLog(@"Category: %@", category);
        [categoriesSet addObject:category];
    }
    
    // Add income categories
    for (Category *category in self.incomeCategories) {
        [categoriesSet addObject:category];
    }
    
    // Assign to budget
    budget.category = categoriesSet;
    
    // Save context
    NSError *error = nil;
    if (![context save:&error]) {
        NSLog(@"Failed to save context: %@", error.localizedDescription);
        [self showAlertWithTitle:@"An error occured!"
                         message:@"Failed to save data."];
        return;
    } else {
        NSLog(@"budget saved: %@", budget);
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


# pragma mark - UITextFieldDelegate
- (void)textFieldDidBeginEditing:(UITextField *)textField {
    UITableViewCell *cell = (UITableViewCell *)textField.superview.superview;
    NSIndexPath *indexPath = [self.budgetDisplayTableView indexPathForCell:cell];
    [self.budgetDisplayTableView scrollToRowAtIndexPath:indexPath
                                       atScrollPosition:UITableViewScrollPositionMiddle
                                               animated:YES];
}


- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (textField == self.headerLabelTextField) {
        NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
        
        if (newString.length > 16 && self.presentedViewController == nil) {
            [self showAlertWithTitle:@"Limit Reached"
                             message:@"ou can only enter up to 16 characters."];
            return NO;
        }
    }
    return YES;
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
