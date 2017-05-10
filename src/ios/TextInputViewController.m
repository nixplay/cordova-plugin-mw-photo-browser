//
//  TextInputViewController.m
//  Nixplay
//
//  Created by James Kong on 4/5/2017.
//
//

#import "TextInputViewController.h"

@interface TextInputViewController ()
@end

@implementation TextInputViewController
@synthesize titleLabel = _titleLabel;
@synthesize textInputField = _textInputField;
@synthesize title = _title;
@synthesize message = _message;
@synthesize placeholder = _placeholder;
- (void)viewDidLoad {
    [super viewDidLoad];
    if(_title == nil || [_title isEqualToString:@""]){
        _title = @"Default Title";
    }
    if(_message == nil || [_message isEqualToString:@""]){
        _message = @"Default Message";
    }
    if(_placeholder == nil || [_placeholder isEqualToString:@""]){
        _placeholder = @"Default PlaceHolder";
    }
    [_titleLabel setText:_title];
    [_textInputField setText:_message];
    [_textInputField setPlaceholder:_placeholder];
    
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
