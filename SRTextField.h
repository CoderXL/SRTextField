//
//  SRTextField.h
//  SiRui
//
//  Created by zhangjunbo on 13-12-12.
//  Copyright (c) 2013年 ChinaPKE. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^Block)(void);

@class SRTextField;

@protocol SRTextFieldDelegate <NSObject>

@required
- (SRTextField *)textFieldAtIndex:(int)index;
- (NSInteger)numberOfTextFields;

@end

@interface SRTextField : UITextField <UITextFieldDelegate>

@property (nonatomic) BOOL required;
@property (nonatomic, strong) UIToolbar *toolbar;
//@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, setter = setDateField:) BOOL isDateField;
@property (nonatomic, setter = setEmailField:) BOOL isEmailField;

@property (nonatomic, assign) id<SRTextFieldDelegate> textFieldDelegate;

- (BOOL) validate;

@end

@interface SRKeyboardView : UIView

- (void)setPreviousBlock:(Block)previousBlock nextBlock:(Block)nextBlock andDoneBlock:(Block)doneBlock;

@end
