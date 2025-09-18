//
//  BudgetViewController.m
//
//  Created by raven on 8/4/25.
//

#import "BudgetViewController.h"
#import "AppDelegate.h"
#import "Budget+CoreDataClass.h"
#import "Transaction+CoreDataClass.h"
#import "BudgetAllocation+CoreDataClass.h"
#import "Category+CoreDataClass.h"
#import "BudgetDisplayViewController.h"
#import "CoreDataManager.h"
#import "BudgetDisplayViewController.h"

@interface BudgetViewController () <UITableViewDelegate, UITableViewDataSource, BudgetDisplayViewControllerDelegate>
@property (nonatomic, strong) NSArray<Budget *> *budgets;
@end

@implementation BudgetViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Set background color to match Health app
    self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];
    
    // Setup UI components
    [self setupHeaderView];
    [self setupTableView];
    [self fetchBudgets];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
}


- (void)fetchBudgets {
    NSError *error = nil;
    NSManagedObjectContext *context = [[CoreDataManager sharedManager] viewContext];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Budget"];
    NSPredicate *activePredicate = [NSPredicate predicateWithFormat:@"isActive == YES"];
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:NO];
    
    request.predicate = activePredicate;
    request.sortDescriptors = @[sort];
    
    self.budgets = [context executeFetchRequest:request error:&error];
    
    [self.budgetTableView reloadData];
}

- (void)setupHeaderView {
    // Create header container
    UIView *headerContainer = [[UIView alloc] init];
    headerContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:headerContainer];
    
    // Setup header label (left side)
    self.headerLabel = [[UILabel alloc] init];
    self.headerLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.headerLabel.text = @"Budgets";
    self.headerLabel.font = [UIFont systemFontOfSize:34 weight:UIFontWeightBold];
    self.headerLabel.textColor = [UIColor labelColor];
    [headerContainer addSubview:self.headerLabel];
    
    // Setup add button (right side)
    self.addButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.addButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.addButton setImage:[UIImage systemImageNamed:@"plus.circle.fill"] forState:UIControlStateNormal];
    self.addButton.tintColor = [UIColor systemTealColor];
    [self.addButton addTarget:self action:@selector(addButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    self.addButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    // Increase button size to match Health app
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
    
    // Setup constraints for add button - make it larger like in Health app
    [NSLayoutConstraint activateConstraints:@[
        [self.addButton.trailingAnchor constraintEqualToAnchor:headerContainer.trailingAnchor],
        [self.addButton.centerYAnchor constraintEqualToAnchor:headerContainer.centerYAnchor],
        [self.addButton.widthAnchor constraintEqualToConstant:44],
        [self.addButton.heightAnchor constraintEqualToConstant:44]
    ]];
}

- (void)setupTableView {
    // Setup table view for budget items - use inset grouped style like Health app
    self.budgetTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleInsetGrouped];
    self.budgetTableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.budgetTableView.delegate = self;
    self.budgetTableView.dataSource = self;
    // Clear background to match the parent view background
    self.budgetTableView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.budgetTableView];
    
    // Setup constraints for table view
    [NSLayoutConstraint activateConstraints:@[
        [self.budgetTableView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:70],
        [self.budgetTableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.budgetTableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.budgetTableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];
}

#pragma mark - Actions

- (void)addButtonTapped {
    // Initialize BudgetFormViewController
    BudgetDisplayViewController *budgetFormVC = [[BudgetDisplayViewController alloc] init];
    budgetFormVC.isEditMode = NO;
    budgetFormVC.managedObjectContext = self.managedObjectContext;
    budgetFormVC.delegate = self;
    
    [self.navigationController pushViewController:budgetFormVC animated:YES];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.budgets.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"BudgetCell"];
    
    if (indexPath.row >= self.budgets.count) {
        return [[UITableViewCell alloc] init];
    }
    
    Budget *budget = self.budgets[indexPath.row];
    cell.textLabel.text = budget.name;
    cell.textLabel.font = [UIFont systemFontOfSize:24];
    
    // Date formatter
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateStyle = NSDateFormatterShortStyle;
    NSString *formattedDate = [dateFormatter stringFromDate:budget.createdAt];
    
    // Create a label for the date
    UILabel *dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 80, 20)];
    dateLabel.text = formattedDate;
    dateLabel.font = [UIFont systemFontOfSize:12];
    dateLabel.textColor = [UIColor grayColor];
    dateLabel.textAlignment = NSTextAlignmentRight;
    
    cell.accessoryView = dateLabel;
    
    // TODO: Refactor the UI of Totals
    // Calculate total expense (using NSDecimalNumber)
    NSDecimalNumber *totalExpense = [NSDecimalNumber zero];
    NSDecimalNumber *totalIncome = [NSDecimalNumber zero];
    
    NSSet *categories = budget.category;
    
    for (Category *category in categories){
        for (BudgetAllocation *allocation in category.allocations){
            if (category.isIncome) {
                totalIncome = [totalIncome decimalNumberByAdding:allocation.allocatedAmount];
            } else {
                totalExpense = [totalExpense decimalNumberByAdding:allocation.allocatedAmount];
            }
        }
    }
    
    // Set detail text with totals
    NSString *detailText = [NSString stringWithFormat:@"Expenses: ₱%.2f\nIncome: ₱%.2f", totalExpense.doubleValue, totalIncome.doubleValue];
    cell.detailTextLabel.text = detailText;
    cell.detailTextLabel.numberOfLines = 0;
    cell.contentView.layer.masksToBounds = YES;
    cell.contentView.layer.cornerRadius = 8;
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 100;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    // Instantiate BudgetDisplayViewController
    BudgetDisplayViewController *displayVC = [[BudgetDisplayViewController alloc] init];
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Budgets"
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:nil
                                                                            action:nil];
    
    // Pass the selected budget
    displayVC.budget = self.budgets[indexPath.row];
    displayVC.isEditMode = YES;
    displayVC.managedObjectContext = self.managedObjectContext;
    
    // Push onto navigation stack
    [self.navigationController pushViewController:displayVC animated:YES];
}

// Deleting via swipe gesture
- (void)tableView:(UITableView *)tableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle != UITableViewCellEditingStyleDelete) {
        NSLog(@"editingStyle: %ld", (long)editingStyle);
        return;
    }
    
    UIAlertController *confirmAlert = [UIAlertController alertControllerWithTitle:@"Warning!"
                                                                          message:@"Are you sure you want to delete this budget?"
                                                                   preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *yesBtn = [UIAlertAction actionWithTitle:@"Yes"
                                                     style:UIAlertActionStyleDestructive
                                                   handler:^(UIAlertAction * _Nonnull action) {
        
        NSManagedObjectContext *context = [[CoreDataManager sharedManager] viewContext];
        
        Budget *budgetToDelete = self.budgets[indexPath.row];
        budgetToDelete.isActive = NO;
        
        NSSet *transactions = budgetToDelete.transactions;
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isActive == YES"];
        NSSet *activeTransactions = [transactions filteredSetUsingPredicate:predicate];
        
        for (Transaction *transaction in activeTransactions){
            transaction.isActive = NO;
        }
        
        NSError *saveError = nil;
        if (![context save:&saveError]) {
            NSLog(@"Failed to save context after budget deletion: %@, %@", saveError, saveError.userInfo);
            
            // Show alert on failure
            UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                                message:@"Failed to save budget deletion. Try again later."
                                                                         preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
            [errorAlert addAction:ok];
            
            // Reset flag
            budgetToDelete.isActive = YES;
            
            // Present error alert
            dispatch_async(dispatch_get_main_queue(), ^{
                [self presentViewController:errorAlert animated:YES completion:nil];
            });
            
            return;
        }
        
        [self fetchBudgets];
    }];
    
    UIAlertAction *noBtn = [UIAlertAction actionWithTitle:@"No"
                                                    style:UIAlertActionStyleCancel
                                                  handler:nil];
    
    [confirmAlert addAction:noBtn];
    [confirmAlert addAction:yesBtn];
    
    [self presentViewController:confirmAlert animated:YES completion:nil];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"Monthly Budgets";
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    // Add a helpful footer message like in Health app
    return @"Tap + to add a new budget category";
}

#pragma mark - BudgetDisplayViewControllerDelegate
- (void)didUpdateData {
    NSLog(@"is this called");
    [self fetchBudgets];
}

@end
