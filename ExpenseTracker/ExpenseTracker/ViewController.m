//
//  ViewController.m
//  ExpenseTracker
//
//  Created by raven on 6/26/25.
//

#import "ViewController.h"
#import "Transaction+CoreDataClass.h"
#import "Category+CoreDataClass.h"
#import "TransactionsViewController.h"
#import "AppDelegate.h"
#import "CoreDataManager.h"
#import "PickerModalViewController.h"

@interface ViewController () <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate>

- (void)updateFetchPredicateForSegment;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupHeaderView];
    [self setupYearHeaderView];
    [self setupSegmentControls];
    [self setupWeekSegmentControls];
    [self initializeCurrentDate];
    [self setupTableView];
    [self weekSegmentChange:self.weekSegmentControl];
    
    self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];
}

// TODO: Pagination
// TODO: Skeleton
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"TransactionsViewController"]) {
        UINavigationController *navController = segue.destinationViewController;
        TransactionsViewController *secondVC = (TransactionsViewController *)navController.topViewController;
        secondVC.isEditMode = NO;
        secondVC.delegate = self;
    }
}

#pragma mark - Init current date
- (void)initializeCurrentDate {
    NSDate *today = [NSDate date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    self.currentDateComponents = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth fromDate:today];
    
    calendar.firstWeekday = 2; // 1 = Sunday, 2 = Monday
    
    // 1. Build a date from current year + month (day = 1)
    NSDateComponents *components = [[NSDateComponents alloc] init];
    components.year = self.currentDateComponents.year;
    components.month = self.currentDateComponents.month;
    components.day = 1;
    NSDate *startOfMonth = [calendar dateFromComponents:components];
    
    // 2. Get the weekday of the first day
    NSDateComponents *weekdayComponents = [calendar components:NSCalendarUnitWeekday fromDate:startOfMonth];
    NSInteger weekday = weekdayComponents.weekday;
    
    // 3. Backtrack to Monday of that week (the first day visible in the calendar grid)
    NSInteger daysToSubtract = (weekday == 1) ? 6 : (weekday - 2);
    NSDate *firstMonday = [calendar dateByAddingUnit:NSCalendarUnitDay
                                               value:-daysToSubtract
                                              toDate:startOfMonth
                                             options:0];
    
    // 4. Find which week 'today' falls into.
    // Use `startOfDayForDate:` to compare dates at midnight and avoid time-of-day issues.
    NSDate *startOfToday = [calendar startOfDayForDate:today];
    
    // 5. Calculate the number of days between the start of the grid (firstMonday) and today.
    // `firstMonday` is already at midnight, so we can use it directly.
    NSDateComponents *dayDifferenceComponents = [calendar components:NSCalendarUnitDay
                                                            fromDate:firstMonday
                                                              toDate:startOfToday
                                                             options:0];
    NSInteger dayDifference = dayDifferenceComponents.day;
    
    // 6. Divide by 7 to get the week index.
    // (e.g., days 0-6 are index 0, days 7-13 are index 1, etc.)
    NSInteger weekIndex = 0;
    
    // Ensure today is not before the grid start (can happen on day 1 of a month)
    if (dayDifference >= 0) {
        weekIndex = dayDifference / 7;
    }
    
    // 7. Assign the calculated index.
    if (weekIndex < self.weekSegmentControl.numberOfSegments) {
        self.weekSegmentControl.selectedSegmentIndex = weekIndex;
        self.weekSegmentIndex = weekIndex;
    } else {
        NSLog(@"Error: Calculated week index (%ld) is out of bounds.", (long)weekIndex);
        self.weekSegmentControl.selectedSegmentIndex = 0;
        self.weekSegmentIndex = 0;
    }
    
    [self updateHeaderLabels];
}

#pragma mark - Update header
- (void)updateHeaderLabels {
    NSArray *months = @[@"January",@"February",@"March",@"April",@"May",@"June",
                        @"July",@"August",@"September",@"October",@"November",@"December"];
    NSInteger monthIndex = self.currentDateComponents.month - 1;
    self.monthLabel.text = months[monthIndex];
    self.yearLabel.text = [NSString stringWithFormat:@"%ld", (long)self.currentDateComponents.year];
}



#pragma mark - Actions

- (void)addButtonTapped {
    UINavigationController *navController = [self.storyboard instantiateViewControllerWithIdentifier:@"TransactionNavController"];
    
    TransactionsViewController *transactionVC = (TransactionsViewController *)navController.topViewController;
    
    transactionVC.delegate = self;
    [self presentViewController:navController animated:YES completion:nil];
}

- (void)didTapPreviousMonth {
    self.currentDateComponents.month -= 1;
    if (self.currentDateComponents.month < 1) {
        self.currentDateComponents.month = 12;
        self.currentDateComponents.year -= 1;
    }
    [self refreshMonthChange];
}

- (void)didTapNextMonth {
    self.currentDateComponents.month += 1;
    if (self.currentDateComponents.month > 12) {
        self.currentDateComponents.month = 1;
        self.currentDateComponents.year += 1;
    }
    [self refreshMonthChange];
}

- (void)refreshMonthChange {
    [self updateHeaderLabels];
    [self weekSegmentChange:self.weekSegmentControl];
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
        [self refreshMonthChange];
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
        [self refreshMonthChange];
    };
    
    [self presentViewController:vc animated:YES completion:nil];
}


#pragma mark - setupHeaderView
- (void)setupHeaderView {
    // Create header container
    self.headerContainer = [[UIView alloc] init];
    UIView *headerContainer = self.headerContainer;
    headerContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:headerContainer];
    
    // Setup header label (left side)
    self.headerLabel = [[UILabel alloc] init];
    self.headerLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.headerLabel.text = @"Transactions";
    self.headerLabel.font = [UIFont systemFontOfSize:34 weight:UIFontWeightBold];
    self.headerLabel.textColor = [UIColor labelColor];
    [headerContainer addSubview:self.headerLabel];
    
    // Setup add button (right side)
    self.addButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.addButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.addButton.titleLabel.font = [UIFont boldSystemFontOfSize:17];
    [self.addButton setTitle:@"Add Data" forState:UIControlStateNormal];
    [self.addButton addTarget:self action:@selector(addButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    self.addButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    [self.addButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
    [headerContainer addSubview:self.addButton];
    
    // Setup constraints for header container
    [NSLayoutConstraint activateConstraints:@[
        [headerContainer.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [headerContainer.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [headerContainer.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
        [headerContainer.heightAnchor constraintEqualToConstant:60]
    ]];
    
    // Setup constraints for header label
    [NSLayoutConstraint activateConstraints:@[
        [self.headerLabel.leadingAnchor constraintEqualToAnchor:headerContainer.leadingAnchor],
        [self.headerLabel.centerYAnchor constraintEqualToAnchor:headerContainer.centerYAnchor],
        [self.headerLabel.trailingAnchor constraintEqualToAnchor:self.addButton.leadingAnchor constant:-10]
    ]];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.addButton.trailingAnchor constraintEqualToAnchor:headerContainer.trailingAnchor],
        [self.addButton.centerYAnchor constraintEqualToAnchor:headerContainer.centerYAnchor],
    ]];
}

- (void)setupYearHeaderView {
    // --- Container for header ---
    self.yearHeaderView = [[UIView alloc] init];
    self.yearHeaderView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.yearHeaderView];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.yearHeaderView.topAnchor constraintEqualToAnchor:self.headerContainer.bottomAnchor constant:16.0],
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


#pragma mark - setupSegmetControls

- (void)setupSegmentControls {
    self.typeSegmentControl = [[UISegmentedControl alloc] initWithItems:@[@"Expense", @"Income", @"All"]];
    self.typeSegmentControl.translatesAutoresizingMaskIntoConstraints = NO;
    self.typeSegmentControl.selectedSegmentIndex = 2;
    
    [self.typeSegmentControl addTarget:self
                                action:@selector(typeSegmentChange:)
                      forControlEvents:UIControlEventValueChanged];
    
    [self.view addSubview:self.typeSegmentControl];
    
    [NSLayoutConstraint activateConstraints:@[
        // Type segment at top, under safe area
        [self.typeSegmentControl.topAnchor constraintEqualToAnchor:self.yearHeaderView.bottomAnchor constant:8.0],
        [self.typeSegmentControl.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16.0],
        [self.typeSegmentControl.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16.0],
        [self.typeSegmentControl.heightAnchor constraintEqualToConstant:32.0],
        
    ]];
    
    self.typeSegmentIndex = self.typeSegmentControl.selectedSegmentIndex;
}

- (void)setupWeekSegmentControls {
    self.weekSegmentControl = [[UISegmentedControl alloc] initWithItems:@[@"Week 1", @"Week 2", @"Week 3", @"Week 4", @"Week 5"]];
    self.weekSegmentControl.translatesAutoresizingMaskIntoConstraints = NO;

    [self.weekSegmentControl addTarget:self
                                action:@selector(weekSegmentChange:)
                      forControlEvents:UIControlEventValueChanged];
    
    [self.view addSubview:self.weekSegmentControl];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.weekSegmentControl.topAnchor constraintEqualToAnchor:self.typeSegmentControl.bottomAnchor constant:8.0],
        [self.weekSegmentControl.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16.0],
        [self.weekSegmentControl.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16.0],
        [self.weekSegmentControl.heightAnchor constraintEqualToConstant:32.0],
    ]];
    
    self.weekSegmentIndex = self.weekSegmentControl.selectedSegmentIndex;
}

- (void)typeSegmentChange:(UISegmentedControl *)sender{
    self.typeSegmentIndex = sender.selectedSegmentIndex;
    [self updateFetchPredicateForSegment];
    [self.transactionTableView reloadData];
}

- (void)weekSegmentChange:(UISegmentedControl *)sender{
    self.weekSegmentIndex = sender.selectedSegmentIndex;
    [self updateFetchPredicateForSegment];
    [self.transactionTableView reloadData];
}

- (void)updateFetchPredicateForSegment {
    NSManagedObjectContext *context = [[CoreDataManager sharedManager] viewContext];
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Transaction"];
    
    NSMutableArray<NSPredicate *> *predicates = [NSMutableArray array];
    
    // Always fetch only active transactions
    [predicates addObject:[NSPredicate predicateWithFormat:@"isActive == YES"]];
    
    // 0 = Expense, 1 = Income, 2 = All
    if (self.typeSegmentIndex != 2) {
        BOOL isIncome = (self.typeSegmentIndex == 1);
        [predicates addObject:[NSPredicate predicateWithFormat:@"category.isIncome == %@", @(isIncome)]];
    }
    
    if (self.weekSegmentIndex >= 0) {
        NSCalendar *calendar = [NSCalendar currentCalendar];
        calendar.firstWeekday = 2; // 1 = Sunday, 2 = Monday
        
        // 1. Build a date from current year + month (day = 1)
        NSDateComponents *components = [[NSDateComponents alloc] init];
        components.year = self.currentDateComponents.year;
        components.month = self.currentDateComponents.month;
        components.day = 1;
        
        NSDate *startOfMonth = [calendar dateFromComponents:components];
        
        // 2. Get the weekday of the first day
        NSDateComponents *weekdayComponents = [calendar components:NSCalendarUnitWeekday fromDate:startOfMonth];
        NSInteger weekday = weekdayComponents.weekday;
        
        // 3. Backtrack to Monday of that week
        NSInteger daysToSubtract = (weekday == 1) ? 6 : (weekday - 2);
        NSDate *firstMonday = [calendar dateByAddingUnit:NSCalendarUnitDay
                                                   value:-daysToSubtract
                                                  toDate:startOfMonth
                                                 options:0];
        
        // 4. Compute week start & end based on segment index
        NSDate *weekStart = [calendar dateByAddingUnit:NSCalendarUnitDay
                                                 value:(self.weekSegmentIndex * 7)
                                                toDate:firstMonday
                                               options:0];
        
        NSDate *weekEnd = [calendar dateByAddingUnit:NSCalendarUnitDay
                                               value:7
                                              toDate:weekStart
                                             options:0];
        
        NSDate *weekEndMinusOneDay = [calendar dateByAddingUnit:NSCalendarUnitDay
                                                          value:-1
                                                         toDate:weekEnd
                                                        options:0];

        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"MMM dd";
        
        NSString *startString = [formatter stringFromDate:weekStart];
        NSString *endString   = [formatter stringFromDate:weekEndMinusOneDay];
        
        self.dateRange = [NSString stringWithFormat:@"From: %@ - %@",
                          startString, endString];
        
        [predicates addObject:[NSPredicate predicateWithFormat:@"date >= %@ AND date < %@", weekStart, weekEnd]];
    }
    
    fetchRequest.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:predicates];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:NO]];
    
    // Recreate the fetched results controller with the new request
    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                    managedObjectContext:context
                                                                      sectionNameKeyPath:nil
                                                                               cacheName:nil];
    _fetchedResultsController.delegate = self;
    
    NSError *error = nil;
    if (![_fetchedResultsController performFetch:&error]) {
        NSLog(@"Unresolved fetch error %@, %@", error, error.userInfo);
    }
}


#pragma mark - setupTableView
- (void)setupTableView {
    // Setup table view for budget items - use inset grouped style like Health app
    self.transactionTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleInsetGrouped];
    self.transactionTableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.transactionTableView.delegate = self;
    self.transactionTableView.dataSource = self;
    
    // Clear background to match the parent view background
    self.transactionTableView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.transactionTableView];
    
    // Register cell with subtitle style to show budget amounts
    [self.transactionTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"BudgetCell"];
    
    // Setup constraints for table view
    [NSLayoutConstraint activateConstraints:@[
        [self.transactionTableView.topAnchor constraintEqualToAnchor:self.weekSegmentControl.bottomAnchor constant:8.0],
        [self.transactionTableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.transactionTableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.transactionTableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];
}




#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
    return [sectionInfo numberOfObjects];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[self.fetchedResultsController sections] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *cellIdentifier = @"TransactionsCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    Transaction *transaction = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    // Date formatter
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"EEE, MMM d";
    NSString *formattedDate = [dateFormatter stringFromDate:transaction.date];
    
    // Type indicator emoji
    NSString *typeIndicator = transaction.category.isIncome == 0 ? @"💸" : @"💰";
    
    // Create a label for the date
    UILabel *amountLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 20)];
    NSNumberFormatter *currencyFormatter = [[NSNumberFormatter alloc] init];
    currencyFormatter.numberStyle = NSNumberFormatterCurrencyStyle;
    currencyFormatter.currencyCode = @"PHP";
    
    NSString *formattedAmount = [currencyFormatter stringFromNumber:transaction.amount];
    NSString *sign = transaction.category.isIncome ? @"+" : @"–";
    amountLabel.text = [NSString stringWithFormat:@"%@ %@", sign, formattedAmount];
    
    amountLabel.font = [UIFont boldSystemFontOfSize:20];
    amountLabel.textAlignment = NSTextAlignmentRight;
    amountLabel.textColor = transaction.category.isIncome ? [UIColor colorWithRed:40.0/255.0
                                                                            green:167.0/255.0
                                                                             blue:69.0/255.0
                                                                            alpha:1.0] : [UIColor colorWithRed:220.0/255.0
                                                                                                         green:53.0/255.0
                                                                                                          blue:69.0/255.0
                                                                                                         alpha:1.0];
    [amountLabel sizeToFit];
    cell.accessoryView = amountLabel;
    
    cell.imageView.image = [self emojiToImage:typeIndicator];
    
    cell.textLabel.text = transaction.category.name;
    cell.textLabel.font = [UIFont boldSystemFontOfSize:18];
    
    cell.detailTextLabel.text = formattedDate;
    cell.detailTextLabel.font = [UIFont systemFontOfSize:14];
    cell.detailTextLabel.textColor = [UIColor secondaryLabelColor];
    
    return cell;
}

// Helper method to convert emoji to image
- (UIImage *)emojiToImage:(NSString *)emoji {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    label.text = emoji;
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont systemFontOfSize:24];
    
    UIGraphicsBeginImageContextWithOptions(label.bounds.size, NO, 0.0);
    [label.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    // Instantiate the navigation controller
    UINavigationController *navController = [self.storyboard instantiateViewControllerWithIdentifier:@"TransactionNavController"];
    
    // Get your TransactionsViewController from the nav controller
    TransactionsViewController *transactionVC = (TransactionsViewController *)navController.topViewController;
    
    transactionVC.delegate = self;
    // Fetch the Transaction object directly from NSFetchedResultsController
    Transaction *selectedTransaction = [self.fetchedResultsController objectAtIndexPath:indexPath];
    transactionVC.existingTransaction = selectedTransaction;
    transactionVC.isEditMode = YES;
    [self presentViewController:navController animated:YES completion:nil];
    
}

// Deleting via swipe gesture
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSDecimalNumber *previousAmount = [NSDecimalNumber zero];
        // Fetch the Transaction object directly from NSFetchedResultsController
        Transaction *transactionToDelete = [self.fetchedResultsController objectAtIndexPath:indexPath];
        
        NSManagedObjectContext *context = [[CoreDataManager sharedManager] viewContext];
        
        //[context deleteObject:transactionToDelete]; // Actual Deletion
        transactionToDelete.isActive = NO;
        
        NSSet *categories = [NSSet setWithObject:transactionToDelete.category];
        for (Category *category in categories){
            previousAmount = category.usedAmount;
            category.usedAmount = [previousAmount decimalNumberBySubtracting:transactionToDelete.amount];
            
            if ([category.usedAmount compare:[NSDecimalNumber zero]] == NSOrderedAscending) {
                category.usedAmount = [NSDecimalNumber zero];
            }
        }
        
        NSError *error = nil;
        BOOL success = [context save:&error];
        
        if (!success) {
            // Save failed
            transactionToDelete.isActive = YES;
            for (Category *category in categories){
                category.usedAmount = previousAmount;
            }
            NSLog(@"Error deleting transaction: %@, %@", error, error.userInfo);
        } else {
            // Save succeeded
            NSLog(@"Transaction successfully deleted.");
        }
        
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (self.dateRange == nil){
        self.dateRange = @"";
    }
    return [NSString stringWithFormat:@"Transactions %@", self.dateRange];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return @"";
}



#pragma mark - FetchResultsController
- (NSFetchedResultsController *)fetchedResultsController {
    if (_fetchedResultsController) {
        return _fetchedResultsController;
    }
    
    NSManagedObjectContext *context = [[CoreDataManager sharedManager] viewContext];
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Transaction"];
    
    // Add predicate to only fetch active transactions
    NSPredicate *activePredicate = [NSPredicate predicateWithFormat:@"isActive == YES"];
    fetchRequest.predicate = activePredicate;
    
    // Sort: newest first
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:NO];
    fetchRequest.sortDescriptors = @[sort];
    
    _fetchedResultsController = [[NSFetchedResultsController alloc]
                                 initWithFetchRequest:fetchRequest
                                 managedObjectContext:context
                                 sectionNameKeyPath:nil
                                 cacheName:nil];
    _fetchedResultsController.delegate = self;
    
    NSError *error = nil;
    if (![_fetchedResultsController performFetch:&error]) {
        NSLog(@"Unresolved error %@, %@", error, error.userInfo);
        abort();
    }
    
    return _fetchedResultsController;
}



#pragma mark - NSFetchResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.transactionTableView beginUpdates];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.transactionTableView endUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    UITableView *tableView = self.transactionTableView;
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:@[newIndexPath]
                             withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:@[indexPath]
                             withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [tableView reloadRowsAtIndexPaths:@[indexPath]
                             withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView moveRowAtIndexPath:indexPath toIndexPath:newIndexPath];
            break;
    }
}

@end

