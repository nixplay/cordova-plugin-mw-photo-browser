//
//  ImageViewer.m
//  Helper
//
//  Created by Calvin Lai on 7/11/13.
//
//

#import "MWPhotoBrowserCordova.h"
#import "MWPhotoBrowser.h"
#import "MWGridViewController.h"
#import "TextInputViewController.h"
#import <Cordova/CDVViewController.h>
#import "MKActionSheet.h"
#import "UIImage+MWPhotoBrowser.h"
#import <Cordova/CDVPlugin+Resources.h>
#import <PopupDialog/PopupDialog-Swift.h>
#import <IQKeyboardManager/IQTextView.h>
#import <IQKeyboardManager/IQUITextFieldView+Additions.h>
#import <IQKeyboardManager/IQUIView+IQKeyboardToolbar.h>
#import <SDWebImage/SDWebImageManager.h>
#import <MBProgressHUD/MBProgressHUD.h>
#define LIGHT_BLUE_COLOR [UIColor colorWithRed:(99/255.0f)  green:(176/255.0f)  blue:(228.0f/255.0f) alpha:1.0]
#define BUNDLE_UIIMAGE(imageNames) [UIImage imageNamed:[NSString stringWithFormat:@"%@.bundle/%@", NSStringFromClass([self class]), imageNames]]
#define OPTIONS_UIIMAGE BUNDLE_UIIMAGE(@"images/options.png")
#define DOWNLOADIMAGE_UIIMAGE BUNDLE_UIIMAGE(@"images/downloadCloud.png")
#define EDIT_UIIMAGE BUNDLE_UIIMAGE(@"images/edit.png")
#define KEY_ACTION  @"action"
#define KEY_LABEL  @"label"
#define DEFAULT_ACTION_ADD @"add"
#define DEFAULT_ACTION_SELECT @"select"
#define DEFAULT_ACTION_ADDTOPLAYLIST @"addToPlaylist"
#define DEFAULT_ACTION_RENAME @"rename"
#define DEFAULT_ACTION_DELETE @"delete"
#define SUBTITLESTRING_FOR_TITLEVIEW(dateString) [NSString stringWithFormat:@"%lu %@ - %@", (unsigned long)[_photos count] , NSLocalizedString(@"Photos",nil) , dateString]
#define MAX_CHARACTER 160
#define CDV_PHOTO_PREFIX @"cdv_photo_"
@implementation MWPhotoBrowserCordova
@synthesize callbackId;
@synthesize photos = _photos;
@synthesize thumbs = _thumbs;
@synthesize browser = _browser;
@synthesize data = _data;
@synthesize actionSheet = _actionSheet;
@synthesize navigationController = _navigationController;
@synthesize albumName = _name;
@synthesize gridViewController = _gridViewController;
@synthesize toolBar = _toolBar;
- (NSMutableDictionary*)callbackIds {
    if(_callbackIds == nil) {
        _callbackIds = [[NSMutableDictionary alloc] init];
    }
    return _callbackIds;
}

- (void)showGallery:(CDVInvokedUrlCommand*)command {
    //    NSLog(@"showGalleryWith:%@", command.arguments);
    
    self.callbackId = command.callbackId;
    [self.callbackIds setValue:command.callbackId forKey:@"showGallery"];
    
    NSDictionary *options = [command.arguments objectAtIndex:0];
    NSArray * imagesUrls = [options objectForKey:@"images"] ;
    _data = [options objectForKey:@"data"];
    if(imagesUrls == nil || [imagesUrls count] <= 0 ){
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Argument \"images\" clould not be empty"];
        [pluginResult setKeepCallbackAsBool:NO];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
        return;
    }
    if( _data == nil || [_data count] == 0 || [_data count] != [imagesUrls count] ){
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Argument \"data\" clould not be empty"];
        [pluginResult setKeepCallbackAsBool:NO];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
        return;
    }
    NSMutableArray *images = [[NSMutableArray alloc] init];
    NSMutableArray *thumbs = [[NSMutableArray alloc] init];
    NSUInteger photoIndex = [[options objectForKey:@"index"] intValue];
    _actionSheetDicArray = [options objectForKey:@"actionSheet"];
    _name = [options objectForKey:@"albumName"];
    _id = [[options objectForKey:@"id"] integerValue];
    _type = [options objectForKey:@"type"] ;
    NSArray *captions = [options objectForKey:@"captions"];
    _dateString = [options objectForKey:@"date"];
    if(_dateString == nil){
        _dateString = NSLocalizedString(@"Unknown Date",nil);
    }
    if(_name == nil){
        _name = NSLocalizedString(@"Untitled",nil);
    }
    //    NSLog(@"data %@",_data);
    for (NSString* url in imagesUrls)
    {
        [images addObject:[MWPhoto photoWithURL:[NSURL URLWithString: url]]];
    }
    if(captions != nil){
        if([captions count] == [images count] ){
            [images enumerateObjectsUsingBlock:^(MWPhoto*  _Nonnull photo, NSUInteger idx, BOOL * _Nonnull stop) {
                photo.caption = [captions objectAtIndex:idx];
            }];
        }
        
    }
    //#define DEBUG_CAPTION
#ifdef DEBUG_CAPTION
    else{
        NSArray *tempCaption = [NSArray arrayWithObjects:
                                @"Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aliquam in elit nullam.",
                                @"Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec id bibendum justo, sed luctus lorem. Vestibulum euismod dolor in justo accumsan condimentum amet.",
                                @"Flat White at Elliot's",
                                @"Lorem ipsum dolor sit amet, consectetur adipiscing elit. Quisque auctor feugiat porttitor. In metus.",
                                @"Jury's Inn",
                                @"iPad Application Sketch Template v1",
                                @"Grotto of the Madonna", nil];
        [images enumerateObjectsUsingBlock:^(MWPhoto*  _Nonnull photo, NSUInteger idx, BOOL * _Nonnull stop) {
            int lowerBound = 0;
            int upperBound = (int)[tempCaption count] ;
            int rndValue = lowerBound + arc4random() % (upperBound - lowerBound);
            photo.caption = [tempCaption objectAtIndex:rndValue];
        }];
    }
#endif
    for (NSString* url in [options objectForKey:@"thumbnails"])
    {
        [thumbs addObject:[MWPhoto photoWithURL:[NSURL URLWithString: url]]];
    }
    _selections = [NSMutableArray new];
    for (int i = 0; i < images.count; i++) {
        [_selections addObject:[NSNumber numberWithBool:NO]];
    }
    self.photos = images;
    if([thumbs count] == 0){
        self.thumbs = self.photos;
    }else{
        self.thumbs = thumbs;
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onOrientationChanged:) name:@"UIDeviceOrientationDidChangeNotification" object:nil];
    
    
    
    // Create & present browser
    MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate: self];
    _browser = browser;
    // Set options
    //    browser.automaticallyAdjustsScrollViewInsets = YES; // Decide if you want the photo browser full screen, i.e. whether the status bar is affected (defaults to YES)
    browser.displayActionButton = NO; // Show action button to save, copy or email photos (defaults to NO)
    browser.startOnGrid = YES;
    browser.enableGrid = YES;
    browser.displayNavArrows = NO;
    
    [browser setCurrentPhotoIndex: photoIndex]; // Example: allows second image to be presented first
    
    // Modal
    
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:browser];
    _navigationController = nc;
    
    UIBarButtonItem *newBackButton = [[UIBarButtonItem alloc] initWithImage: OPTIONS_UIIMAGE style:UIBarButtonItemStylePlain target:self action:@selector(home:)];
    newBackButton.tag = 0;
    browser.navigationItem.rightBarButtonItem = newBackButton;
    _rightBarbuttonItem = newBackButton;
    
    _navigationController.delegate = self;
    
    CATransition *transition = [CATransition animation];
    transition.duration = 0.5;
    //    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    transition.type = kCATransitionPush;
    transition.subtype = kCATransitionFromRight;
    [self.viewController.view.window.layer addAnimation:transition forKey:nil];
    //    __block UIView*  oldSuperView = _navigationController.view.subviews[0];
    //    [self.viewController.view addSubview:_navigationController.view];
    [self.viewController presentViewController:nc animated:NO completion:^{
        
    }];
    
}

-(void)home:(UIBarButtonItem *)sender
{
    if(sender.tag == 0){
        PopupDialogDefaultView* dialogAppearance =  [PopupDialogDefaultView appearance];
        PopupDialogOverlayView* overlayAppearance =  [PopupDialogOverlayView appearance];
        overlayAppearance.blurEnabled = NO;
        overlayAppearance.blurRadius = 0;
        overlayAppearance.opacity = 0.5;
        dialogAppearance.titleTextAlignment     = NSTextAlignmentLeft;
        dialogAppearance.messageTextAlignment   = NSTextAlignmentLeft;
        dialogAppearance.titleFont              = [UIFont systemFontOfSize:20];
        dialogAppearance.messageFont            =  [UIFont systemFontOfSize:16];
        dialogAppearance.titleColor            =  [UIColor blackColor];
        dialogAppearance.messageColor            =  [UIColor darkGrayColor];
        //    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
        __weak MWPhotoBrowserCordova *weakSelf = self;
        __block NSArray * titles =  [_actionSheetDicArray valueForKey:KEY_LABEL];
        __block NSArray * actions =  [_actionSheetDicArray valueForKey:KEY_ACTION];
        
        MKActionSheet *sheet = [[MKActionSheet alloc] initWithTitle:NSLocalizedString(@"Options", nil) buttonTitleArray:titles selectType:MKActionSheetSelectType_common];
        sheet.titleColor = [UIColor grayColor];
        sheet.titleAlignment = NSTextAlignmentLeft;
        sheet.buttonTitleColor = [UIColor blackColor];
        sheet.buttonOpacity = 1;
        sheet.buttonTitleAlignment = MKActionSheetButtonTitleAlignment_left;
        sheet.animationDuration = 0.2f;
        sheet.blurOpacity = 0.7f;
        sheet.blackgroundOpacity = 0.6f;
        sheet.needCancelButton = NO;
        sheet.maxShowButtonCount = 5.6;
        sheet.separatorLeftMargin = 0;
        
        [sheet showWithBlock:^(MKActionSheet *actionSheet, NSInteger buttonIndex) {
            
            if([[actions objectAtIndex:buttonIndex] isEqualToString:DEFAULT_ACTION_ADD]){
                NSMutableDictionary *dictionary = [NSMutableDictionary new];
                [dictionary setValue:[actions objectAtIndex:buttonIndex] forKey: KEY_ACTION];
                [dictionary setValue:@(_id) forKey: @"id"];
                [dictionary setValue:_type forKey: @"type"];
                [dictionary setValue:@"add photo to album" forKey: @"description"];
                CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:dictionary];
                [pluginResult setKeepCallbackAsBool:NO];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
                [self photoBrowserDidFinishModalPresentation:_browser];
            }else if([[actions objectAtIndex:buttonIndex] isEqualToString:DEFAULT_ACTION_SELECT]){
                if(!_browser.displaySelectionButtons){
                    _gridViewController.selectionMode = _browser.displaySelectionButtons = YES;
                    [_gridViewController.collectionView reloadData];
                    [_browser showToolBar];
                    sender.tag = 1;
                    [sender setImage:nil];
                    [sender setTitle:NSLocalizedString(@"Cancel", nil)];
                }
            }
//            else if([[actions objectAtIndex:buttonIndex] isEqualToString:DEFAULT_ACTION_ADDTOPLAYLIST]){
//                NSMutableDictionary *dictionary = [NSMutableDictionary new];
//                [dictionary setValue:@"addAlbumToPlaylist" forKey: KEY_ACTION];
//                [dictionary setValue:@(_id) forKey: @"id"];
//                [dictionary setValue:_type forKey: @"type"];
//                [dictionary setValue:@"add album to playlist" forKey: @"description"];
//                CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:dictionary];
//                [pluginResult setKeepCallbackAsBool:NO];
//                [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
//                [self photoBrowserDidFinishModalPresentation:_browser];
//            }
            else if([[actions objectAtIndex:buttonIndex] isEqualToString:DEFAULT_ACTION_RENAME]){
                //edit album name
                [weakSelf popupTextAreaDialogTitle:NSLocalizedString(@"Edit Album name", nil) message:((_name != nil || [_name isEqualToString:@""] ) ? _name : NSLocalizedString(@"Album", nil)) placeholder:NSLocalizedString(@"Album name", nil) action:^(NSString * text) {
                    
                    //TODO send result edit album name
                    
                    if( ![text isEqualToString:@""]){
                        NSMutableDictionary *dictionary = [NSMutableDictionary new];
                        [dictionary setValue:[actions objectAtIndex:buttonIndex] forKey: KEY_ACTION];
                        [dictionary setValue:@(_id) forKey: @"id"];
                        [dictionary setValue:_type forKey: @"type"];
                        [dictionary setValue:text forKey: @"albumName"];
                        [dictionary setValue:@"edit album name" forKey: @"description"];
                        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:dictionary];
                        [pluginResult setKeepCallbackAsBool:YES];
                        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
                    }
                    
                }];
            }else if([[actions objectAtIndex:buttonIndex] isEqualToString:DEFAULT_ACTION_DELETE]){
                [self buildDialogWithCancelText:NSLocalizedString(@"Cancel", nil) confirmText:NSLocalizedString(@"Delete", nil) title:NSLocalizedString(@"Delete album", nil)  text:NSLocalizedString(@"Are you sure you want to delete this album? This will also remove the photos from the playlist if they are not in any other albums. ", nil) action:^{
                    NSMutableDictionary *dictionary = [NSMutableDictionary new];
                    [dictionary setValue:[actions objectAtIndex:buttonIndex] forKey: KEY_ACTION];
                    [dictionary setValue:@(_id) forKey: @"id"];
                    [dictionary setValue:_type forKey: @"type"];
                    
                    [dictionary setValue:@"delete album" forKey: @"description"];
                    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:dictionary];
                    [pluginResult setKeepCallbackAsBool:YES];
                    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
                }];
                
                
            }else{
                NSMutableDictionary *dictionary = [NSMutableDictionary new];
                [dictionary setValue:[actions objectAtIndex:buttonIndex] forKey: KEY_ACTION];
                [dictionary setValue:@(_id) forKey: @"id"];
                [dictionary setValue:_type forKey: @"type"];
                [dictionary setValue:@"unhandled action	" forKey: @"description"];
                CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:dictionary];
                [pluginResult setKeepCallbackAsBool:NO];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
            }
            
            
        }];
        
        
        self.actionSheet = sheet;
    }else{
        
        if(_browser.displaySelectionButtons){
            _browser.displayActionButton = NO;
            _gridViewController.selectionMode = _browser.displaySelectionButtons = NO;
            [_gridViewController.collectionView reloadData];
            
            [_browser hideToolBar];
            sender.tag = 0;
            [sender setImage:OPTIONS_UIIMAGE];
            [sender setTitle:nil];
            for (int i = 0; i < _selections.count; i++) {
                [_selections replaceObjectAtIndex:i withObject:[NSNumber numberWithBool:NO]];
            }
        }
        
    }
}

-(void) buildDialogWithCancelText:(NSString*)cancelText confirmText:(NSString*)confirmtext title:(NSString*) title text:(NSString*)text action:(void (^ _Nullable)(void))action {
    __weak MWPhotoBrowserCordova *weakSelf = self;
    
    
    PopupDialog *popup = [[PopupDialog alloc] initWithTitle:title
                                                    message:text
                                                      image:nil
                                            buttonAlignment:UILayoutConstraintAxisHorizontal
                                            transitionStyle:PopupDialogTransitionStyleFadeIn
                                           gestureDismissal:YES
                                                 completion:nil];
    
    CancelButton *cancel = [[CancelButton alloc]initWithTitle:cancelText height:60 dismissOnTap:YES action:^{
        
    }];
    
    DefaultButton *ok = [[DefaultButton alloc]initWithTitle:confirmtext  height:60 dismissOnTap:YES action:action];
    [ok setBackgroundColor:LIGHT_BLUE_COLOR];
    [ok setTitleColor:[UIColor whiteColor]];
    [popup addButtons: @[cancel, ok]];
    _dialogView = popup;
    [_browser.navigationController presentViewController:popup animated:YES completion:nil];
    
}

- (void)popupTextAreaDialogTitle:(NSString*)title message:(NSString*)message placeholder:(NSString*)placeholder action:(void (^ _Nullable)(NSString*))action{
    
    
    __block TextInputViewController* textViewVC = [[TextInputViewController alloc] initWithNibName:@"TextInputViewController" bundle:nil];
    textViewVC.titleString = title;
    textViewVC.messageString = message;
    textViewVC.placeholderString = placeholder;
    
    __weak MWPhotoBrowserCordova *weakSelf = self;
    PopupDialog *popup = [[PopupDialog alloc] initWithViewController:textViewVC buttonAlignment:UILayoutConstraintAxisHorizontal transitionStyle:PopupDialogTransitionStyleFadeIn gestureDismissal:YES completion:^{
        
    }];
    CancelButton *cancel = [[CancelButton alloc]initWithTitle:NSLocalizedString(@"Cancel", nil) height:60 dismissOnTap:YES action:^{
        
    }];
    
    DefaultButton *ok = [[DefaultButton alloc]initWithTitle:NSLocalizedString(@"OK", nil)  height:60 dismissOnTap:YES action:^{
        action(textViewVC.textInputField.text);
    }];
    [ok setTitleColor:[UIColor whiteColor]];
    [ok setBackgroundColor:LIGHT_BLUE_COLOR];
    
    [popup addButtons: @[cancel, ok]];
    _dialogView = popup;
    [_browser.navigationController presentViewController:popup animated:YES completion:^{
        
    }];
}


#pragma mark UITextViewDelegate


-(void)textViewDidChange:(UITextView *)textView{
    MWPhoto *photo = [self.photos objectAtIndex:_browser.currentIndex];
    
    [photo setCaption:textView.text];
    [self.photos replaceObjectAtIndex:_browser.currentIndex withObject:photo];
    
}
- (BOOL)textViewShouldEndEditing:(UITextView *)textView{
    return YES;
}
-(void)textViewDidBeginEditing:(UITextView *)textView
{
    //    [self animatetextView:_textView up:YES keyboardFrameBeginRect:keyboardRect];
    textView.backgroundColor = [UIColor whiteColor];
    textView.textColor = [UIColor blackColor];
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    //    [self animatetextView:_textView up:YES keyboardFrameBeginRect:_keyboardRect];
    //    [self animatetextView:textView up:NO :];
    textView.backgroundColor = [UIColor blackColor];
    textView.textColor = [UIColor whiteColor];
    [self resignKeyboard:textView];
    [self endEditCaption:textView];
    
}
- (BOOL)textViewShouldReturn:(UITextView *)textView{
    NSLog(@"textViewShouldReturn:");
    if (textView.tag == 1) {
        UITextView *textView = (UITextView *)[self.navigationController.view viewWithTag:2];
        [textView becomeFirstResponder];
    }
    else {
        [self endEditCaption:textView];
    }
    return YES;
}


- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    // Prevent crashing undo bug – see note below.
    IQTextView* iqTextView = (IQTextView*)textView;
    iqTextView.shouldHidePlaceholderText = NO;
    iqTextView.placeholderText = [NSString stringWithFormat:@"%lu/%d",(unsigned long)textView.text.length, MAX_CHARACTER];
    
    if(range.length + range.location > textView.text.length)
    {
        return NO;
    }
    if ([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        
        return NO;
    }
    NSUInteger newLength = [textView.text length] + [text length] - range.length;
    return newLength < MAX_CHARACTER;
}

#pragma mark - MWPhotoBrowserDelegate

- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    return _photos.count;
}

- (MWPhoto *)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    if (index < _photos.count)
        return [_photos objectAtIndex:index];
    return nil;
}
- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser thumbPhotoAtIndex:(NSUInteger)index{
    MWPhoto *photo = [self.thumbs objectAtIndex:index];
    return photo;
}
- (MWCaptionView *)photoBrowser:(MWPhotoBrowser *)photoBrowser captionViewForPhotoAtIndex:(NSUInteger)index {
    MWPhoto *photo = [self.photos objectAtIndex:index];
    MWCaptionView *captionView = [[MWCaptionView alloc] initWithPhoto:photo];
    
    return captionView;
}

-(void) photoBrowserDidFinishModalPresentation:(MWPhotoBrowser*) browser{
    CATransition *transition = [CATransition animation];
    
    transition.duration = 0.5;
    transition.delegate = self;
    transition.type = kCATransitionPush;
    transition.subtype = kCATransitionFromLeft;
    [browser.view.window.layer addAnimation:transition forKey:nil];
    [browser dismissViewControllerAnimated:NO completion:^{
        
        
    }];
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag{
    if(flag){
        _photos = nil;
        _thumbs = nil;
        _data = nil;
        _navigationController = nil;
        _gridViewController = nil;
        _browser = nil;
        _actionSheet = nil;
        _name = nil;
        _dialogView = nil;
        _rightBarbuttonItem = nil;
    }
}
//- (NSString *)photoBrowser:(MWPhotoBrowser *)photoBrowser titleForPhotoAtIndex:(NSUInteger)index{
//}
- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser didDisplayPhotoAtIndex:(NSUInteger)index{
    _browser = photoBrowser;
    NSLog(@"didDisplayPhotoAtIndex %lu", (unsigned long)index);
    if(_textView.superview != nil){
        _textView.text = [[self.photos objectAtIndex:index] caption];
        [_textView setFrame:[self newRectFromTextView:_textView ]];
    }
}
- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser actionButtonPressedForPhotoAtIndex:(NSUInteger)index{
    _browser = photoBrowser;
    NSLog(@"actionButtonPressedForPhotoAtIndex %lu", (unsigned long)index);
}
- (BOOL)photoBrowser:(MWPhotoBrowser *)photoBrowser isPhotoSelectedAtIndex:(NSUInteger)index{
    _browser = photoBrowser;
    return [[_selections objectAtIndex:index] boolValue];
}
- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index selectedChanged:(BOOL)selected{
    _browser = photoBrowser;
    [_selections replaceObjectAtIndex:index withObject:[NSNumber numberWithBool:selected]];
    NSLog(@"photoAtIndex %lu selectedChanged %i", (unsigned long)index , selected);
}
- (BOOL)photoBrowser:(MWPhotoBrowser *)photoBrowser showGridController:(MWGridViewController*)gridController{
    [photoBrowser hideToolBar];
    _browser = photoBrowser;
    _gridViewController = gridController;
    if(_rightBarbuttonItem != nil){
        photoBrowser.navigationItem.rightBarButtonItem = _rightBarbuttonItem;
        [_rightBarbuttonItem setAction:@selector(home:)];
        [_rightBarbuttonItem setTarget:self];
        photoBrowser.navigationController.navigationItem.rightBarButtonItem = _rightBarbuttonItem;
    }
    return YES;
}

- (BOOL)photoBrowser:(MWPhotoBrowser *)photoBrowser hideGridController:(MWGridViewController*)gridController{
    _browser = photoBrowser;
    _gridViewController = nil;
    
    if(_textView != nil){
        [_textView removeFromSuperview];
    }
    photoBrowser.navigationItem.rightBarButtonItem = nil;
    photoBrowser.navigationController.navigationItem.rightBarButtonItem = nil;
    [photoBrowser showToolBar];
    return YES;
}

- (BOOL)photoBrowser:(MWPhotoBrowser *)photoBrowser setNavBarAppearance:(UINavigationBar *)navigationBar{
    
    _browser = photoBrowser;
    [photoBrowser.navigationController setNavigationBarHidden:NO animated:NO];
    navigationBar.barStyle = UIBarStyleDefault;
    navigationBar.translucent = YES;
    photoBrowser.navigationItem.titleView = [self setTitle:_name subtitle:SUBTITLESTRING_FOR_TITLEVIEW(_dateString)];
    return YES;
}

-(UIView*) setTitle:(NSString*)title subtitle:(NSString*)subtitle {
    UILabel *titleLabel = [[UILabel alloc] initWithFrame: CGRectMake(0,-5,0,0)];
    
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.textColor = [UIColor grayColor];
    titleLabel.font = [UIFont boldSystemFontOfSize: 17];
    titleLabel.text = title;
    [titleLabel sizeToFit];
    
    UILabel *subtitleLabel = [[UILabel alloc] initWithFrame: CGRectMake(0,18,0,0)];
    subtitleLabel.backgroundColor = [UIColor clearColor];
    subtitleLabel.textColor = [UIColor blackColor];
    subtitleLabel.font = [UIFont systemFontOfSize:12];
    subtitleLabel.text = subtitle;
    [subtitleLabel sizeToFit];
    
    UIView *titleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, fmax(titleLabel.frame.size.width, subtitleLabel.frame.size.width), 30)];
    [titleView addSubview:titleLabel];
    [titleView addSubview:subtitleLabel];
    
    float widthDiff = subtitleLabel.frame.size.width - titleLabel.frame.size.width;
    
    if (widthDiff > 0) {
        CGRect frame = titleLabel.frame;
        frame.origin.x = widthDiff / 2;
        titleLabel.frame = CGRectIntegral(frame);
    } else {
        CGRect frame = subtitleLabel.frame;
        frame.origin.x = fabsf(widthDiff) / 2;
        titleLabel.frame = CGRectIntegral(frame);
    }
    
    return titleView;
}

-(BOOL) photoBrowserSelectionMode{
    return _browser.displaySelectionButtons;
}
- (BOOL)photoBrowser:(MWPhotoBrowser *)photoBrowser hideToolbar:(BOOL)hide {
    _browser = photoBrowser;
    return NO;
}
- (NSMutableArray*)photoBrowser:(MWPhotoBrowser *)photoBrowser buildToolbarItems:(UIToolbar*)toolBar{
    _toolBar = toolBar;
    if(_gridViewController != nil){
        UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:self action:nil];
        fixedSpace.width = 32; // To balance action button
        UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
        
        NSMutableArray *items = [[NSMutableArray alloc] init];
        
        
        UIBarButtonItem * deleteBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash
                                                                                          target:self action:@selector(deletePhotos:)];
        
        UIBarButtonItem * sendtoBarButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Add to...", nil) style:UIBarButtonItemStylePlain target:self action:@selector(add:)];
        
        UIBarButtonItem * downloadPhotosButton = [[UIBarButtonItem alloc] initWithImage:DOWNLOADIMAGE_UIIMAGE style:UIBarButtonItemStylePlain target:self action:@selector(downloadPhotos:)];
        
        [items addObject:deleteBarButton];
        [items addObject:flexSpace];
        [items addObject:downloadPhotosButton];
        [items addObject:flexSpace];
        [items addObject:sendtoBarButton];
        [items addObject:flexSpace];
        // Right - Action
        UIBarButtonItem *actionButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(actionButtonPressed:)];
        if (actionButton ) {
            [items addObject:actionButton];
        }
        return items;
    }else{
        UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:self action:nil];
        fixedSpace.width = 32; // To balance action button
        UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
        NSMutableArray *items = [[NSMutableArray alloc] init];
        
        UIBarButtonItem * downloadPhotoButton = [[UIBarButtonItem alloc] initWithImage:DOWNLOADIMAGE_UIIMAGE style:UIBarButtonItemStylePlain target:self action:@selector(downloadPhoto:)];
        
        UIBarButtonItem * editCaption = [[UIBarButtonItem alloc] initWithImage:EDIT_UIIMAGE style:UIBarButtonItemStylePlain target:self action:@selector(beginEditCaption:)];
        
        UIBarButtonItem * deleteBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(deletePhoto:)];
        
        
        [items addObject:downloadPhotoButton];
        [items addObject:flexSpace];
        [items addObject:editCaption];
        [items addObject:flexSpace];
        [items addObject:deleteBarButton];
        return items;
    }
    
    
}
-(void)onOrientationChanged:(id)orientation{
    
}
-(void) downloadPhoto:(id)sender{
    //TODO save photo
    __block MBProgressHUD *progressHUD = [MBProgressHUD showHUDAddedTo:_browser.view
                                                      animated:YES];
    progressHUD.mode = MBProgressHUDModeDeterminate;
    
    progressHUD.label.text = NSLocalizedString(@"Downloading",nil);
    [progressHUD showAnimated:YES];
    
    @try{
        NSString *originalUrl = [[_data objectAtIndex:_browser.currentIndex] objectForKey:@"originalUrl"];
        [[SDWebImageManager sharedManager] downloadImageWithURL:[NSURL URLWithString:originalUrl ] options:0 progress:^(NSInteger receivedSize, NSInteger expectedSize) {
            [progressHUD setProgress:(receivedSize*1.0f)/(expectedSize*1.0f) ];
        } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
            [progressHUD hideAnimated:YES];
            if ([PHObject class]) {
                __block PHAssetChangeRequest *assetRequest;
                __block PHObjectPlaceholder *placeholder;
                // Save to the album
                [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                    
                    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                        assetRequest = [PHAssetChangeRequest creationRequestForAssetFromImage:image];
                        placeholder = [assetRequest placeholderForCreatedAsset];
                    } completionHandler:^(BOOL success, NSError *error) {
                        NSString *message;
                        NSString *title;
                        if (success) {
                            title = NSLocalizedString(@"Image Saved", @"");
                            message = NSLocalizedString(@"The image was placed in your photo album.", @"");
                        }
                        else {
                            title = NSLocalizedString(@"Error", @"");
                            message = [error description];
                        }
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                                        message:message
                                                                       delegate:nil
                                                              cancelButtonTitle:@"OK"
                                                              otherButtonTitles:nil];
                        [alert show];
                    }];
                }];
            }


        }];
        //download
    }@catch(NSException * exception){
        NSLog(@"%@", exception.description);
    }
}

typedef void(^DownloaderProgressBlock)(float progress);

typedef void(^DownloaderCompletedBlock)(NSArray *images, NSError *error, BOOL finished);


-(void)downloadPhotos:(id)sender{
    NSMutableArray* urls = [NSMutableArray new];
    [_selections enumerateObjectsUsingBlock:^(NSNumber *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if([obj boolValue]){
            NSString *originalUrl = [[_data objectAtIndex:idx] objectForKey:@"originalUrl"];
            [urls addObject:originalUrl];
        }
    }];
    __block MBProgressHUD *progressHUD = [MBProgressHUD showHUDAddedTo:_browser.view
                                                              animated:YES];
    progressHUD.mode = MBProgressHUDModeDeterminate;
    
    progressHUD.label.text = NSLocalizedString(@"Downloading",nil);
    [progressHUD showAnimated:YES];
    
    
    [self downloadImages:urls total:[urls count] received:0 progress:^(float progress) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [progressHUD setProgress:progress];
        });
    } complete:^(NSArray *images, NSError *error, BOOL finished) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [progressHUD hideAnimated:YES];
        });
    } ];

}
     
-(void) downloadImages:(NSArray*)urls total:(NSInteger)total received:(NSInteger)received progress:(DownloaderProgressBlock) progressBlack complete:(DownloaderCompletedBlock)completeBlock{
    SDWebImageManager *manager = [SDWebImageManager sharedManager];
    [manager downloadImageWithURL:[NSURL URLWithString:[urls firstObject]] options:0 progress:^(NSInteger receivedSize, NSInteger expectedSize) {
        
        float progressOfATask = ((receivedSize*1.0f)/(expectedSize*1.0f))*(1.0f/total*1.0f);
        progressBlack(((progressOfATask+received)*1.0f)/(total*1.0f));
        
    } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
        
        if ([PHObject class]) {
            __block PHAssetChangeRequest *assetRequest;
            __block PHObjectPlaceholder *placeholder;
            // Save to the album
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                
                [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                    assetRequest = [PHAssetChangeRequest creationRequestForAssetFromImage:image];
                    placeholder = [assetRequest placeholderForCreatedAsset];
                } completionHandler:^(BOOL success, NSError *error) {
                    if (success) {
//                        NSString *localIdentifier = placeholder.localIdentifier;
                        if([urls count] > 1){
                            NSArray *tempArray = [NSArray arrayWithArray:[urls subarrayWithRange: NSMakeRange (1, [urls count]-1) ]];
                            //save images
                            NSInteger newReceive = (received+1);
                            [self downloadImages:tempArray total:total received:newReceive progress:progressBlack complete:completeBlock];
                        }else{
                            completeBlock(nil, nil, YES);
                        }
                    }
                    else {
                        NSError* err = [NSError errorWithDomain:@"MWPhotoBrowserCordova" code:403 userInfo:@{@"message":@"Photo Library is not allowed to access"} ];
                        completeBlock(nil, err, YES);
                    }
                }];
            }];
        }
        
        
        
    }];
}

- (NSString*)tempFilePath:(NSString*)extension
{
    NSString* docsPath = [NSTemporaryDirectory()stringByStandardizingPath];
    NSFileManager* fileMgr = [[NSFileManager alloc] init]; // recommended by Apple (vs [NSFileManager defaultManager]) to be threadsafe
    NSString* filePath;
    
    // generate unique file name
    int i = 1;
    do {
        filePath = [NSString stringWithFormat:@"%@/%@%03d.%@", docsPath, CDV_PHOTO_PREFIX, i++, extension];
    } while ([fileMgr fileExistsAtPath:filePath]);
    
    return filePath;
}


-(void) beginEditCaption:(UIBarButtonItem*)sender{
    
    if(_browser != nil){
        _browser.alwaysShowControls = YES;
    }
    if(_textView == nil){
        float height = self.navigationController.view.frame.size.height*(1.0f/6.0f);
        float y = self.navigationController.view.frame.size.height - height ;
        
        _textView = [[IQTextView alloc ] initWithFrame:CGRectMake(0, y, self.navigationController.view.frame.size.width, height*.5)];
        _textView.delegate = self;
        _textView.backgroundColor = [UIColor blackColor];
        _textView.textColor = [UIColor whiteColor];
        _textView.font = [UIFont systemFontOfSize:17];
        _textView.returnKeyType = UIReturnKeyDone;
        [_textView addRightButtonOnKeyboardWithImage:EDIT_UIIMAGE target:self action:@selector(resignKeyboard:) shouldShowPlaceholder:nil];
        [[IQKeyboardManager sharedManager] preventShowingBottomBlankSpace];
    }
    __block MWPhoto *photo = [self.photos objectAtIndex:[_browser currentIndex]];
    
    _textView.text = photo.caption;
    
    _textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    [_textView setFrame:[self newRectFromTextView:_textView ]];
    [_browser.view addSubview:_textView];
    [_textView becomeFirstResponder];
}
-(void) resignKeyboard:(id)sender{
    if(_textView && _textView.superview != nil){
        [_textView resignFirstResponder];
        [_textView removeFromSuperview];
    }
}
-(void) endEditCaption:(id)sender{
    _browser.alwaysShowControls = NO;
    [[self.photos objectAtIndex:_browser.currentIndex] setCaption: _textView.text];
    
    [_browser reloadData];
    [[IQKeyboardManager sharedManager] setKeyboardDistanceFromTextField:0];
    NSMutableDictionary *dictionary = [NSMutableDictionary new];
    [dictionary setValue:[_data objectAtIndex:_browser.currentIndex] forKey: @"photo"];
    [dictionary setValue:[[_photos objectAtIndex:_browser.currentIndex] caption] forKey: @"caption"];
    [dictionary setValue:@"editCaption" forKey: KEY_ACTION];
    [dictionary setValue:@(_id) forKey: @"id"];
    [dictionary setValue:_type forKey: @"type"];
    [dictionary setValue:@"edit caption of photo" forKey: @"description"];
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:dictionary];
    [pluginResult setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
}
-(CGRect) newRectFromTextView:(UITextView*) inTextView{
    float labelPadding = 10;
    float newHeight =  MAX(MIN(5.0,(_textView.contentSize.height - _textView.textContainerInset.top - _textView.textContainerInset.bottom) / _textView.font.lineHeight), 2) *_textView.font.lineHeight ;
    newHeight = MAX(newHeight , _toolBar.frame.size.height)  + labelPadding * 2;
    CGRect originFrame = _textView.frame;
    CGRect newFrame = CGRectMake( originFrame.origin.x, self.navigationController.view.frame.size.height - newHeight - _toolBar.frame.size.height, originFrame.size.width, newHeight);
    return newFrame;
}
-(void) deletePhoto:(id)sender{
    [self buildDialogWithCancelText:NSLocalizedString(@"Cancel", nil) confirmText:NSLocalizedString(@"Delete", nil) title:NSLocalizedString(@"Delete photos", nil) text:NSLocalizedString(@"Are you sure you want to delete the selected photos? ", nil) action:^{
        NSMutableArray* tempPhotos = [NSMutableArray arrayWithArray:_photos];
        NSMutableArray* tempThumbs = [NSMutableArray arrayWithArray:_thumbs];
        NSMutableArray* tempSelections = [NSMutableArray arrayWithArray:_selections];
        NSDictionary* targetPhoto = [_data objectAtIndex:_browser.currentIndex];
        [tempPhotos removeObjectAtIndex:_browser.currentIndex];
        [tempThumbs removeObjectAtIndex:_browser.currentIndex];
        [tempSelections removeObjectAtIndex:_browser.currentIndex];
        self.photos = tempPhotos;
        self.thumbs = tempThumbs;
        _selections = tempSelections;
        
        [_browser reloadData];
//
        _browser.navigationItem.titleView = [self setTitle:_name subtitle:SUBTITLESTRING_FOR_TITLEVIEW(_dateString)];
        NSMutableDictionary *dictionary = [NSMutableDictionary new];
        [dictionary setValue:[targetPhoto valueForKey:@"id"] forKey: @"photo"];
        [dictionary setValue:@"deletePhoto" forKey: KEY_ACTION];
        [dictionary setValue:@(_id) forKey: @"id"];
        [dictionary setValue:_type forKey: @"type"];
        [dictionary setValue:@"delete photo" forKey: @"description"];
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:dictionary];
        [pluginResult setKeepCallbackAsBool:YES];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
    }];
    
}
-(void) deletePhotos:(id)sender{
    
    [self buildDialogWithCancelText:NSLocalizedString(@"Cancel", nil) confirmText:NSLocalizedString(@"Delete", nil) title:NSLocalizedString(@"Delete photos", nil) text:NSLocalizedString(@"Are you sure you want to delete the selected photos? ", nil) action:^{
        NSMutableArray *fetchArray = [NSMutableArray new];
#define DEBUG
#ifdef DEBUG
        NSMutableArray* tempPhotos = [NSMutableArray new];
        NSMutableArray* tempThumbs = [NSMutableArray new];
        NSMutableArray* tempSelections = [NSMutableArray new];
        NSMutableArray* tempData = [NSMutableArray new];
#endif
        
        [_selections enumerateObjectsUsingBlock:^(NSNumber *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if([obj boolValue]){
                [fetchArray addObject: [[_data objectAtIndex:idx] valueForKey:@"id"]];
                
#ifdef DEBUG
                
#endif
            }else{
                [tempPhotos addObject: [_photos objectAtIndex:idx]];
                [tempThumbs addObject: [_thumbs objectAtIndex:idx]];
                [tempSelections addObject: [_selections objectAtIndex:idx]];
                [tempData addObject: [_data objectAtIndex:idx]];
            }
        }];
#ifdef DEBUG
        
        self.photos = tempPhotos;
        self.thumbs = tempThumbs;
        _selections = tempSelections;
        _data = tempData;
        [_browser setCurrentPhotoIndex:0];
        [_browser reloadData];
        _browser.navigationItem.titleView = [self setTitle:_name subtitle:SUBTITLESTRING_FOR_TITLEVIEW(_dateString)];
#endif
        NSMutableDictionary *dictionary = [NSMutableDictionary new];
        [dictionary setValue:fetchArray forKey: @"photos"];
        [dictionary setValue:@"deletePhotos" forKey: KEY_ACTION];
        [dictionary setValue:@(_id) forKey: @"id"];
        [dictionary setValue:_type forKey: @"type"];
        [dictionary setValue:@"delete photos from album" forKey: @"description"];
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:dictionary];
        [pluginResult setKeepCallbackAsBool:YES];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
    }];
    
    
}
-(void) add:(id)sender{
    
}
-(void) actionButtonPressed:(id)sender{
    
}
@end
