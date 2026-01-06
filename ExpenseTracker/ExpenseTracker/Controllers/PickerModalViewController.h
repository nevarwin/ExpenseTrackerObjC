//
//  PickerModalViewController.h
//  ExpenseTracker
//
//  Created by raven on 9/29/25.
//

#ifndef PickerModalViewController_h
#define PickerModalViewController_h

#import <UIKit/UIKit.h>

@interface PickerModalViewController : UIViewController
@property (nonatomic, strong) NSArray<NSString *> *items;
@property (nonatomic, copy) void (^onDone)(NSInteger selectedIndex);
@property (nonatomic, assign) NSInteger selectedIndex;
@end

#endif /* PickerModalViewController_h */
