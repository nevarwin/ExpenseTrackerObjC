//
//  PickerModalViewController.m
//  ExpenseTracker
//
//  Created by raven on 9/29/25.
//

#import <Foundation/Foundation.h>
#import "PickerModalViewController.h"

@interface PickerModalViewController () <UIPickerViewDelegate, UIPickerViewDataSource>
@property (nonatomic, strong) UIPickerView *pickerView;
@end

@implementation PickerModalViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.modalPresentationStyle = UIModalPresentationPageSheet;
    
    self.pickerView = [[UIPickerView alloc] init];
    self.pickerView.delegate = self;
    self.pickerView.dataSource = self;
    self.pickerView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.pickerView];
    
    UIButton *doneButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [doneButton setTitle:@"Done" forState:UIControlStateNormal];
    doneButton.translatesAutoresizingMaskIntoConstraints = NO;
    [doneButton addTarget:self action:@selector(doneTapped) forControlEvents:UIControlEventTouchUpInside];
    doneButton.titleLabel.font = [UIFont systemFontOfSize:22 weight:UIFontWeightSemibold];
    [self.view addSubview:doneButton];
    
    UILayoutGuide *guide = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [self.pickerView.topAnchor constraintEqualToAnchor:guide.topAnchor constant:24],
        [self.pickerView.leadingAnchor constraintEqualToAnchor:guide.leadingAnchor constant:16],
        [self.pickerView.trailingAnchor constraintEqualToAnchor:guide.trailingAnchor constant:-16],

        [doneButton.heightAnchor constraintEqualToConstant:56],
        [doneButton.topAnchor constraintEqualToAnchor:self.pickerView.bottomAnchor constant:16],
        [doneButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [doneButton.bottomAnchor constraintEqualToAnchor:guide.bottomAnchor constant:0],
        [doneButton.heightAnchor constraintEqualToAnchor:doneButton.titleLabel.heightAnchor]
    ]];
    
    [self.pickerView selectRow:self.selectedIndex inComponent:0 animated:NO];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return self.items.count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return self.items[row];
}

- (void)doneTapped {
    if (self.onDone) {
        self.onDone([self.pickerView selectedRowInComponent:0]);
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (@available(iOS 16.0, *)) {
        CGFloat contentHeight = [self.view systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
        UISheetPresentationController *sheet = self.sheetPresentationController;
        if (sheet) {
            sheet.detents = @[
                [UISheetPresentationControllerDetent customDetentWithIdentifier:@"custom"
                                                                       resolver:^CGFloat(id<UISheetPresentationControllerDetentResolutionContext> context) {
                    return contentHeight;
                }]
            ];
            sheet.prefersGrabberVisible = YES;
            sheet.preferredCornerRadius = 16.0;
        }
    }
}
@end
