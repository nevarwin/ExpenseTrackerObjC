//
//  ViewController.m
//  ExpenseTracker
//
//  Created by XOO_Raven on 6/26/25.
//

#import "ViewController.h"
#import "Transaction.h"
#import "AddTransactionViewController.h"

@interface ViewController () <UITableViewDataSource, UITableViewDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.transactionTableView.delegate = self;
    self.transactionTableView.dataSource = self;
    self.transactionsArray = [NSMutableArray array];
}


- (IBAction)addTransaction:(UIButton *)sender {
    NSLog(@"Button Pressed");
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"AddTransactionViewController"]) {
        AddTransactionViewController *secondVC = segue.destinationViewController;
        secondVC.delegate = self;
    }
}



#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableview numberOfRowsInSection:(NSInteger)section {
    return self.transactionsArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *cellIdentifier = @"TransactionsCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    Transaction *transaction = self.transactionsArray[indexPath.row];
    cell.editing = true;
    cell.textLabel.text = [NSString stringWithFormat:@"Amount: %ld", (long) transaction.amount];
    cell.detailTextLabel.text = transaction.category;
    
    return cell;
}


#pragma mark -
- (void) didSaveTransactions:(Transaction *)transactions{
    [self.transactionsArray addObject:transactions];
    [self.transactionTableView reloadData];
}


@end
