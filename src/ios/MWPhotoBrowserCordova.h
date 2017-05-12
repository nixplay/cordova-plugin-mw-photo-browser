//
//  ImageViewer.h
//  Helper
//
//  Created by Calvin Lai on 7/11/13.
//
//

#import <Foundation/Foundation.h>
#import <Cordova/CDVPlugin.h>
#import "MWPhotoBrowser.h"
#import "MKActionSheet.h"
#import <PopupDialog/PopupDialog-Swift.h>
#import <IQKeyboardManager/IQKeyboardManager.h>
#import <IQKeyboardManager/IQTextView.h>
@interface MWPhotoBrowserCordova : CDVPlugin <MWPhotoBrowserDelegate,UINavigationControllerDelegate, CAAnimationDelegate, UITextViewDelegate> {

    NSMutableDictionary* _callbackIds;

    NSMutableArray *_selections;
    UIBarButtonItem *_rightBarbuttonItem;
    IQTextView *_textView;
    NSInteger _albumId;
    
}
@property (copy)   NSString* callbackId;
@property (nonatomic, retain) NSMutableArray *photos;
@property (nonatomic, retain) NSArray *thumbs;
@property (nonatomic, retain) NSMutableArray *data;
@property (nonatomic, retain) UIToolbar *toolBar;
@property (nonatomic, retain) UINavigationController *navigationController;
@property (nonatomic, retain) MWGridViewController* gridViewController;
@property (nonatomic, retain) MWPhotoBrowser *browser;
@property (nonatomic, retain) MKActionSheet *actionSheet;
@property (nonatomic, retain) NSString *albumName;
@property (nonatomic, retain) PopupDialog *dialogView;

- (void)showGallery:(CDVInvokedUrlCommand*)command;

@end
