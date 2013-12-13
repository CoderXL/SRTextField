//
//  SRTextField.m
//  SiRui
//
//  Created by zhangjunbo on 13-12-12.
//  Copyright (c) 2013年 ChinaPKE. All rights reserved.
//

#import "SRTextField.h"

@interface SRTextField () {
    UITextField *_textField;
    BOOL _disabled;
//    CGRect originalRect;
    CGPoint originalPoint;
    CGFloat aDuration;
}

@property (nonatomic) BOOL keyboardIsShown;
@property (nonatomic) CGSize keyboardSize;
@property (nonatomic) BOOL isSuperViewScrollView;
@property (nonatomic) BOOL invalid;

@property (nonatomic, strong) UIScrollView *superScrollView;

@property (nonatomic, setter = setToolbarCommand:) BOOL isToolBarCommand;
@property (nonatomic, setter = setDoneCommand:) BOOL isDoneCommand;

@property (nonatomic , strong) UIBarButtonItem *previousBarButton;
@property (nonatomic , strong) UIBarButtonItem *nextBarButton;

@property (nonatomic, strong) NSMutableArray *textFields;

@end

@implementation SRTextField

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self){
        [self setup];
    }
    
    return self;
}

- (void) awakeFromNib{
    [super awakeFromNib];
    [self setup];
}

- (void)setup
{
//    self.delegate = self;
    
    if ([self respondsToSelector:@selector(setTintColor:)]) {
        [self setTintColor:[UIColor blackColor]];
    }
    
    _toolbar = [[UIToolbar alloc] init];
    _toolbar.frame = CGRectMake(0, 0, self.window.frame.size.width, 35);
    // set style
    [_toolbar setBarStyle:UIBarStyleDefault];
    
    self.previousBarButton = [[UIBarButtonItem alloc] initWithTitle:@"Previous" style:UIBarButtonItemStyleBordered target:self action:@selector(previousButtonIsClicked:)];
    self.nextBarButton = [[UIBarButtonItem alloc] initWithTitle:@"Next" style:UIBarButtonItemStyleBordered target:self action:@selector(nextButtonIsClicked:)];
    
    UIBarButtonItem *flexBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    UIBarButtonItem *doneBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonIsClicked:)];
    
    NSArray *barButtonItems = @[self.previousBarButton, self.nextBarButton, flexBarButton, doneBarButton];
    
    _toolbar.items = barButtonItems;
    
    self.textFields = [[NSMutableArray alloc]init];
    
    [self markTextFieldsWithTagInView:self.superview];
    
    _isSuperViewScrollView = [self.superview isKindOfClass:[UIScrollView class]];
    
    if (_isSuperViewScrollView) {
        _superScrollView = (UIScrollView *)self.superview;
        originalPoint = _superScrollView.contentOffset;
    } else {
        originalPoint = self.superview.frame.origin;
    }
    
    self.inputAccessoryView = _toolbar;
}

- (void)markTextFieldsWithTagInView:(UIView*)view
{
    int index = 0;
    if ([self.textFields count] == 0){
        for(UIView *subView in view.subviews){
            if ([subView isKindOfClass:[SRTextField class]]){
                SRTextField *textField = (SRTextField *)subView;
                textField.tag = index;
                [self.textFields addObject:textField];
                index++;
            }
        }
    }
}

- (void) doneButtonIsClicked:(id)sender
{
    [self setDoneCommand:YES];
    [self resignFirstResponder];
    [self setToolbarCommand:YES];
}

- (void)keyboardWillShow:(NSNotification *) notification
{
    aDuration = [[[notification userInfo] valueForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
}

-(void) keyboardDidShow:(NSNotification *) notification
{
    if (_textField == nil) return;
    if (_keyboardIsShown) return;
    if (![_textField isKindOfClass:[SRTextField class]]) return;
    
    NSDictionary* info = [notification userInfo];
    
    NSValue *aValue = [info objectForKey:UIKeyboardFrameBeginUserInfoKey];
    _keyboardSize = [aValue CGRectValue].size;
    
    [self scrollToField];
    
    self.keyboardIsShown = YES;
    
}

-(void) keyboardWillHide:(NSNotification *) notification
{
    NSTimeInterval duration = [[[notification userInfo] valueForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    [UIView animateWithDuration:duration animations:^{
        if (_isToolBarCommand)
            return ;

        if (_isSuperViewScrollView) {
            _superScrollView.contentOffset = originalPoint;
        } else {
            CGRect frame = self.superview.frame;
            frame.origin = originalPoint;
            self.superview.frame = frame;
        }
    }];
    
    _keyboardIsShown = NO;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void) nextButtonIsClicked:(id)sender
{
    NSInteger tagIndex = self.tag;
    SRTextField *textField =  [self.textFields objectAtIndex:++tagIndex];
    
    while (!textField.isEnabled && tagIndex < [self.textFields count]){
        textField = [self.textFields objectAtIndex:++tagIndex];
    }
    
    _isToolBarCommand = YES;
    [self resignFirstResponder];
    [textField becomeFirstResponder];
}


- (void) previousButtonIsClicked:(id)sender
{
    NSInteger tagIndex = self.tag;
    
    SRTextField *textField =  [self.textFields objectAtIndex:--tagIndex];
    
    while (!textField.isEnabled && tagIndex < [self.textFields count]){
        textField = [self.textFields objectAtIndex:--tagIndex];
    }
    
    [self setToolbarCommand:YES];
    
    [textField becomeFirstResponder];
    [self resignFirstResponder];
}

- (void)setBarButtonNeedsDisplayAtTag:(int)tag
{
    
    BOOL previousBarButtonEnabled = NO;
    BOOL nexBarButtonEnabled = NO;
    
    for (int index = 0; index < [self.textFields count]; index++) {
        
        UITextField *textField = [self.textFields objectAtIndex:index];
        
        if (index < tag)
            previousBarButtonEnabled |= textField.isEnabled;
        else if (index > tag)
            nexBarButtonEnabled |= textField.isEnabled;
    }
    
    self.previousBarButton.enabled = previousBarButtonEnabled;
    self.nextBarButton.enabled = nexBarButtonEnabled;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
//    if (!textField.window.isKeyWindow) {
//        [textField.window makeKeyAndVisible];
//    }
    
    _textField = textField;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidShow:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    [self setBarButtonNeedsDisplayAtTag:textField.tag];
    
    self.inputAccessoryView = _toolbar;
    
    [self setDoneCommand:NO];
    [self setToolbarCommand:NO];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [self validate];
    
    _textField = nil;
    
    if (_isDateField && [textField.text isEqualToString:@""] && _isDoneCommand){
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        
        [dateFormatter setDateFormat:@"MM/dd/YY"];
        [textField setText:[dateFormatter stringFromDate:[NSDate date]]];
        
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
//    if (self.nextBarButton.enabled && textField.returnKeyType == UIReturnKeyNext) {
//        [self nextButtonIsClicked:self.nextBarButton];
//    } else if (textField.returnKeyType == UIReturnKeyDone) {
//        [self endEditing:YES];
//    }
    
    if (self.nextBarButton.enabled) {
        [self nextButtonIsClicked:self.nextBarButton];
    } else {
        [self endEditing:YES];
    }
    

    return YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    if (_isDateField){
        UIDatePicker *datePicker = [[UIDatePicker alloc] init];
        datePicker.datePickerMode = UIDatePickerModeDate;
        [datePicker addTarget:self action:@selector(datePickerValueChanged:) forControlEvents:UIControlEventValueChanged];
        
        if (![textField.text isEqualToString:@""]){
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"MM/dd/YY"];
            [dateFormatter setTimeZone:[NSTimeZone localTimeZone]];
            [dateFormatter setDateStyle:NSDateFormatterShortStyle];
            [datePicker setDate:[dateFormatter dateFromString:textField.text]];
        }
        [textField setInputView:datePicker];
    }
    
    return !_disabled;
}

- (void)datePickerValueChanged:(id)sender
{
    UIDatePicker *datePicker = (UIDatePicker*)sender;
    
    NSDate *selectedDate = datePicker.date;
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MM/dd/YY"];
    
    [_textField setText:[dateFormatter stringFromDate:selectedDate]];
    [self validate];
}

- (void)scrollToField
{
    //textField左下角在窗口中的坐标
    CGPoint textRectBoundary = [self convertPoint:CGPointMake(0, self.frame.size.height) toView:self.window];
    
    //键盘左上角在窗口中的坐标
    CGPoint keyboardRectBoundary = [self.inputAccessoryView convertPoint:CGPointMake(0, 0) toView:self.window];
    
    //视图左上角原始坐标位置 (注意：originY和originX 与 originalPoint有可能不一致！！！！！！！！)
    //originalPoint是页面加载时的位置，originY、originX是当前状态下页面的位置
    CGFloat originY;
    CGFloat originX;
    if (_isSuperViewScrollView) {
        originY = -_superScrollView.contentOffset.y;
        originX = _superScrollView.contentOffset.x;
    } else {
        originY = self.superview.frame.origin.y;
        originX = self.superview.frame.origin.x;
    }
    
    //记录最新的X位置，整个过程只变化Y位置，X位置保持不变
    originalPoint.x = originX;
    
    CGFloat deltaY = keyboardRectBoundary.y - 10 - textRectBoundary.y + originY;
    deltaY = deltaY>0?0:deltaY;
    deltaY *= _isSuperViewScrollView?-1:1;
    CGPoint scrollPoint = CGPointMake(originX, deltaY);
    
    if (_isSuperViewScrollView) {
        _superScrollView.contentOffset = scrollPoint;
    } else {
        CGRect rect = self.superview.frame;
        rect.origin = scrollPoint;
        [UIView animateWithDuration:0.35 animations:^{
            self.superview.frame = rect;
        }];
    }
    
    return;
}

- (BOOL) validate
{
    self.backgroundColor = [UIColor colorWithRed:255 green:0 blue:0 alpha:0.5];
    
    if (_required && [self.text isEqualToString:@""]){
        return NO;
    }
    else if (_isEmailField){
        NSString *emailRegEx =
        @"(?:[A-Za-z0-9!#$%\\&'*+/=?\\^_`{|}~-]+(?:\\.[A-Za-z0-9!#$%\\&'*+/=?\\^_`{|}"
        @"~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\"
        @"x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[A-Za-z0-9](?:[a-"
        @"z0-9-]*[A-Za-z0-9])?\\.)+[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?|\\[(?:(?:25[0-5"
        @"]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-"
        @"9][0-9]?|[A-Za-z0-9-]*[A-Za-z0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21"
        @"-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])";
        
        NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegEx];
        
        if (![emailTest evaluateWithObject:self.text]){
            return NO;
        }
    }
    
    [self setBackgroundColor:[UIColor whiteColor]];
    
    return YES;
}

- (void)setEnabled:(BOOL)enabled
{
    [super setEnabled:enabled];
    
    if (!enabled)
        [self setBackgroundColor:[UIColor lightGrayColor]];
}


@end


@interface SRKeyboardView ()

@end

@implementation SRKeyboardView

- (id)init {
    self = [super init];
    if (self) {
        
    }
    
    return self;
}


- (void)setPreviousBlock:(Block)previousBlock nextBlock:(Block)nextBlock andDoneBlock:(Block)doneBlock
{

}

@end

