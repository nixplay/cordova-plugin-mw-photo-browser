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
#define LIGHT_BLUE_COLOR [UIColor colorWithRed:(99/255.0f)  green:(176/255.0f)  blue:(228.0f/255.0f) alpha:1.0]
#define OPTIONS_UIIMAGE [UIImage imageNamed:[NSString stringWithFormat:@"%@.bundle/%@", NSStringFromClass([self class]), @"images/options.png"]]
@implementation MWPhotoBrowserCordova 
@synthesize callbackId = _callbackId;
@synthesize callbackIds = _callbackIds;
@synthesize photos = _photos;
@synthesize thumbs = _thumbs;
@synthesize browser = _browser;
@synthesize data = _data;
@synthesize actionSheet = _actionSheet;
@synthesize navigationController = _navigationController;
@synthesize albumName = _albumName;
@synthesize gridViewController = _gridViewController;
- (NSMutableDictionary*)callbackIds {
    if(_callbackIds == nil) {
        _callbackIds = [[NSMutableDictionary alloc] init];
    }
    return _callbackIds;
}

- (void)showGallery:(CDVInvokedUrlCommand*)command {
//    NSLog(@"showGalleryWith:%@", command.arguments);
    
    _callbackId = command.callbackId;
    [self.callbackIds setValue:command.callbackId forKey:@"showGallery"];
    
    NSDictionary *options = [command.arguments objectAtIndex:0];
    NSMutableArray *images = [[NSMutableArray alloc] init];
    NSMutableArray *thumbs = [[NSMutableArray alloc] init];
    NSUInteger photoIndex = [[options objectForKey:@"index"] intValue];
    _data = [options objectForKey:@"data"];
    _albumName = [options objectForKey:@"albumName"];
    NSArray *captions = [options objectForKey:@"captions"];
    
    //    NSLog(@"data %@",_data);
    for (NSString* url in [options objectForKey:@"images"])
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
        __block NSArray * titles = [NSArray arrayWithObjects:
                                    NSLocalizedString(@"Add Photos", nil),
                                    NSLocalizedString(@"Select Photos", nil),
                                    NSLocalizedString(@"Add Album to Playlist", nil),
                                    NSLocalizedString(@"Edit Album Name", nil),
                                    NSLocalizedString(@"Delete Album", nil), nil];
        //        AHKActionSheet *actionSheet = [[AHKActionSheet alloc] initWithTitle:NSLocalizedString(@"Options", nil)];
        
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
            switch(buttonIndex){
                case 0:{
                }
                break;
                case 1:{
                    if(!_browser.displaySelectionButtons){
                        _gridViewController.selectionMode = _browser.displaySelectionButtons = YES;
                        [_gridViewController.collectionView reloadData];
                        [_browser showToolBar];
                        sender.tag = 1;
                        [sender setImage:nil];
                        [sender setTitle:NSLocalizedString(@"Cancel", nil)];
                    }
                }
                    break;
                case 2:{
                    NSMutableDictionary *dictionary = [NSMutableDictionary new];
                    [dictionary setValue:0000 forKey: @"albumId"];
                    [dictionary setValue:@"add album to playlist" forKey: @"command"];
                    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:dictionary];
                    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
                }
                    break;
                case 3:
                    [weakSelf popupTextAreaDialog];
                    break;
                case 4:{
                    [self buildDialogWithCancelText:NSLocalizedString(@"Cancel", nil) confirmText:NSLocalizedString(@"Delete", nil) title:NSLocalizedString(@"Delete album", nil)  text:NSLocalizedString(@"Are you sure you want to delete this album? This will also remove the photos from the playlist if they are not in any other albums. ", nil) action:^{
                        
                    }];
                    //TODO transit to send playlist
                    NSMutableDictionary *dictionary = [NSMutableDictionary new];
                    [dictionary setValue:0000 forKey: @"albumId"];
                    [dictionary setValue:@"transitionTo" forKey: @"nixplay.home.photo-caption.photo-recipient"];
                    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:dictionary];
                    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
                }
                    break;
                case NSNotFound:
                    
                    break;
                default:
                    
                    break;
                    
            }
            
        }];
        
        
        self.actionSheet = sheet;
    }else{
        
        if(_browser.displaySelectionButtons){
            _browser.displayActionButton = NO;
            _gridViewController.selectionMode = _browser.displaySelectionButtons = NO;
            [_gridViewController.collectionView reloadData];
//            [_browser reloadData];
            [_browser hideToolBar];
            sender.tag = 0;
            [sender setImage:OPTIONS_UIIMAGE];
            [sender setTitle:nil];
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

- (void)popupTextAreaDialog {
    
    
    __block TextInputViewController* textViewVC = [[TextInputViewController alloc] initWithNibName:@"TextInputViewController" bundle:nil];
    
    __weak MWPhotoBrowserCordova *weakSelf = self;
    PopupDialog *popup = [[PopupDialog alloc] initWithViewController:textViewVC buttonAlignment:UILayoutConstraintAxisHorizontal transitionStyle:PopupDialogTransitionStyleFadeIn gestureDismissal:YES completion:^{
        
    }];
    CancelButton *cancel = [[CancelButton alloc]initWithTitle:NSLocalizedString(@"Cancel", nil) height:60 dismissOnTap:YES action:^{
        
    }];
    
    DefaultButton *ok = [[DefaultButton alloc]initWithTitle:NSLocalizedString(@"OK", nil)  height:60 dismissOnTap:YES action:^{
        //TODO send result edit album name
        NSMutableDictionary *dictionary = [NSMutableDictionary new];
        [dictionary setValue:0000 forKey: @"albumId"];
        if( ![textViewVC.textInputField.text isEqualToString:@""]){
            [dictionary setValue:textViewVC.textInputField.text forKey: @"albumName"];
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:dictionary];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
        }
        
    }];
    [ok setTitleColor:[UIColor whiteColor]];
    [ok setBackgroundColor:LIGHT_BLUE_COLOR];
    
    [popup addButtons: @[cancel, ok]];
    _dialogView = popup;
    [_browser.navigationController presentViewController:popup animated:YES completion:^{
        
    }];
}

-(void) onOrientationChanged:(UIInterfaceOrientation) orientation{
    //    if(_actionSheet != nil)
    //        [_actionSheet rotateToCurrentOrientation];
}

// -(void)action:(UIBarButtonItem *)sender
// {
//     _browser.displaySelectionButtons = !_browser.displaySelectionButtons;
//     [_browser setNeedsFocusUpdate];
//     NSLog(@"action %@",sender);
// }


#pragma mark - UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated{
    if([viewController isKindOfClass:[MWPhotoBrowser class] ]){
        // UIBarButtonItem *newActionButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"action", nil) style:UIBarButtonItemStylePlain target:self action:@selector(action:)];
        // viewController.navigationItem.rightBarButtonItem = newActionButton;
        
    }
    //else{
    //        [self.viewController dismissViewControllerAnimated:YES completion:nil];
    //    }
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
//    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    transition.delegate = self;
    transition.type = kCATransitionPush;
    transition.subtype = kCATransitionFromLeft;
    [browser.view.window.layer addAnimation:transition forKey:nil];
//    [_navigationController.view removeFromSuperview];
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
//        _browser = nil;
        _actionSheet = nil;
        _albumName = nil;
        _dialogView = nil;
        _rightBarbuttonItem = nil;
    }
}
//- (NSString *)photoBrowser:(MWPhotoBrowser *)photoBrowser titleForPhotoAtIndex:(NSUInteger)index{
//}
- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser didDisplayPhotoAtIndex:(NSUInteger)index{
    _browser = photoBrowser;
    NSLog(@"didDisplayPhotoAtIndex %lu", (unsigned long)index);
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
    //    _rightBarbuttonItem = photoBrowser.navigationItem.rightBarButtonItem;
    photoBrowser.navigationItem.rightBarButtonItem = nil;
    photoBrowser.navigationController.navigationItem.rightBarButtonItem = nil;
    
    return YES;
}

- (BOOL)photoBrowser:(MWPhotoBrowser *)photoBrowser setNavBarAppearance:(UINavigationBar *)navigationBar{
    
    _browser = photoBrowser;
    [photoBrowser.navigationController setNavigationBarHidden:NO animated:NO];
//    photoBrowser.navigationItem.title = (_albumName != nil ) ? _albumName : @"Albums";
    navigationBar.barStyle = UIBarStyleDefault;
    navigationBar.translucent = YES;
//    photoBrowser.navigationItem.prompt = @"145 Photos - 15 Nov 2016";
    
    photoBrowser.navigationItem.titleView = [self setTitle:(_albumName != nil ) ? _albumName : @"Albums" subtitle:@"145 Photos - 15 Nov 2016"];
    
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
    UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:self action:nil];
    fixedSpace.width = 32; // To balance action button
    UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    
    NSMutableArray *items = [[NSMutableArray alloc] init];
    
    
    UIBarButtonItem * deleteBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash
                                                                         target:self action:@selector(deletePhoto:)];
    
    UIBarButtonItem * sendtoBarButton = [[UIBarButtonItem alloc] initWithTitle:@"Add" style:UIBarButtonItemStylePlain target:self action:@selector(add:)];
    
    
    [items addObject:deleteBarButton];
    [items addObject:flexSpace];
    [items addObject:sendtoBarButton];
    [items addObject:flexSpace];
    // Right - Action
    UIBarButtonItem *actionButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(actionButtonPressed:)];
    if (actionButton ) {
        [items addObject:actionButton];
    }
    return items;
}
-(void) deletePhoto:(id)sender{
    
    [self buildDialogWithCancelText:NSLocalizedString(@"Cancel", nil) confirmText:NSLocalizedString(@"Delete", nil) title:NSLocalizedString(@"Delete photos", nil) text:NSLocalizedString(@"Are you sure you want to delete the selected photos? ", nil) action:^{
        NSMutableArray *fetchArray = [NSMutableArray new];
        [_selections enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if([obj isEqual:@(YES)]){
                [fetchArray addObject: [[_data objectAtIndex:idx] valueForKey:@"id"]];
            }
        }];
        
        NSMutableDictionary *dictionary = [NSMutableDictionary new];
        [dictionary setValue:fetchArray forKey: @"photos"];
        [dictionary setValue:0000 forKey: @"albumId"];
        [dictionary setValue:@"delete photos from album" forKey: @"description"];
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:dictionary];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
    }];
    
    
}
-(void) add:(id)sender{
    
}
-(void) actionButtonPressed:(id)sender{
    
}
@end
