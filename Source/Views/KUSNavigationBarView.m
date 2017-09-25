//
//  KUSNavigationBarView.m
//  Kustomer
//
//  Created by Daniel Amitay on 8/16/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KUSNavigationBarView.h"

#import "KUSAvatarImageView.h"
#import "KUSColor.h"
#import "KUSUserSession.h"

@interface KUSNavigationBarView () <KUSObjectDataSourceListener, KUSPaginatedDataSourceListener> {
    KUSUserSession *_userSession;
    KUSChatMessagesDataSource *_chatMessagesDataSource;
    KUSUserDataSource *_userDataSource;

    KUSAvatarImageView *_avatarImageView;
    UILabel *_nameLabel;
    UILabel *_greetingLabel;
    UIView *_separatorView;
}

@end

@implementation KUSNavigationBarView

#pragma mark - Class methods

+ (void)initialize
{
    if (self == [KUSNavigationBarView class]) {
        KUSNavigationBarView *appearance = [KUSNavigationBarView appearance];
        [appearance setBackgroundColor:[KUSColor lightGrayColor]];
        [appearance setNameColor:[UIColor darkGrayColor]];
        [appearance setNameFont:[UIFont boldSystemFontOfSize:13.0]];
        [appearance setGreetingColor:[KUSColor darkGrayColor]];
        [appearance setGreetingFont:[UIFont systemFontOfSize:11.0]];
        [appearance setSeparatorColor:[KUSColor grayColor]];
    }
}

#pragma mark - Lifecycle methods

- (instancetype)initWithUserSession:(KUSUserSession *)userSession
{
    self = [super init];
    if (self) {
        _userSession = userSession;

        _avatarImageView = [[KUSAvatarImageView alloc] initWithUserSession:userSession];
        [self addSubview:_avatarImageView];

        _nameLabel = [[UILabel alloc] init];
        _nameLabel.textAlignment = NSTextAlignmentCenter;
        _nameLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _nameLabel.numberOfLines = 1;
        [self addSubview:_nameLabel];

        _greetingLabel = [[UILabel alloc] init];
        _greetingLabel.textAlignment = NSTextAlignmentCenter;
        _greetingLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _greetingLabel.numberOfLines = 1;
        _greetingLabel.adjustsFontSizeToFitWidth = YES;
        _greetingLabel.minimumScaleFactor = 0.9;
        [self addSubview:_greetingLabel];

        _separatorView = [[UIView alloc] init];
        [self addSubview:_separatorView];

        [_userSession.chatSettingsDataSource addListener:self];
        [self _updateTextLabels];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    BOOL hasStatusBar = ![UIApplication sharedApplication].statusBarHidden;

    CGFloat avatarSize = 30.0;
    CGFloat statusBarHeight = (hasStatusBar && UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad ? 20.0 : 0.0);
    CGFloat labelSidePad = 10.0;

    if (self.showsLabels) {
        if (_sessionId.length) {
            _nameLabel.font = [UIFont boldSystemFontOfSize:13.0];
            _greetingLabel.font = [UIFont systemFontOfSize:11.0];

            _avatarImageView.frame = (CGRect) {
                .origin.x = (self.bounds.size.width - avatarSize) / 2.0,
                .origin.y = (self.bounds.size.height - [self _extraNavigationBarHeight] - avatarSize - statusBarHeight) / 2.0 + statusBarHeight,
                .size.width = avatarSize,
                .size.height = avatarSize
            };
            _nameLabel.frame = (CGRect) {
                .origin.x = labelSidePad,
                .origin.y = _avatarImageView.frame.origin.y + _avatarImageView.frame.size.height + 4.0,
                .size.width = self.bounds.size.width - labelSidePad * 2.0,
                .size.height = 16.0
            };
            _greetingLabel.frame = (CGRect) {
                .origin.x = labelSidePad,
                .origin.y = _nameLabel.frame.origin.y + _nameLabel.frame.size.height + 2.0,
                .size.width = self.bounds.size.width - labelSidePad * 2.0,
                .size.height = 13.0
            };
        } else {
            _nameLabel.font = [UIFont boldSystemFontOfSize:15.0];
            _greetingLabel.font = [UIFont systemFontOfSize:13.0];

            _avatarImageView.frame = (CGRect) {
                .origin.x = (self.bounds.size.width - avatarSize) / 2.0,
                .origin.y = (self.bounds.size.height / 2.0) - avatarSize,
                .size.width = avatarSize,
                .size.height = avatarSize
            };
            _nameLabel.frame = (CGRect) {
                .origin.x = labelSidePad,
                .origin.y = _avatarImageView.frame.origin.y + _avatarImageView.frame.size.height + 8.0,
                .size.width = self.bounds.size.width - labelSidePad * 2.0,
                .size.height = 20.0
            };
            _greetingLabel.frame = (CGRect) {
                .origin.x = labelSidePad,
                .origin.y = _nameLabel.frame.origin.y + _nameLabel.frame.size.height + 8.0,
                .size.width = self.bounds.size.width - labelSidePad * 2.0,
                .size.height = 16.0
            };
        }
    } else {
        _avatarImageView.frame = (CGRect) {
            .origin.x = (self.bounds.size.width - avatarSize) / 2.0,
            .origin.y = (self.bounds.size.height - avatarSize - statusBarHeight) / 2.0 + statusBarHeight,
            .size.width = avatarSize,
            .size.height = avatarSize
        };
    }

    _separatorView.frame = (CGRect) {
        .origin.y = self.bounds.size.height - 0.5,
        .size.width = self.bounds.size.width,
        .size.height = 0.5
    };
}

#pragma mark - Internal methods

- (CGFloat)_extraNavigationBarHeight
{
    return (_sessionId.length == 0 ? 146.0 : 36.0);
}

- (void)_updateTextLabels
{
    [_userDataSource removeListener:self];
    _userDataSource = [_userSession userDataSourceForUserId:_chatMessagesDataSource.firstOtherUserId];
    [_userDataSource addListener:self];

    // Title text (from last responder, chat settings, or organization name)
    KUSChatSettings *chatSettings = [_userSession.chatSettingsDataSource object];
    KUSUser *firstOtherUser = _userDataSource.object;
    NSString *responderName = firstOtherUser.displayName;
    if (responderName.length == 0) {
        responderName = chatSettings.teamName.length ? chatSettings.teamName : _userSession.organizationName;
    }
    _nameLabel.text = responderName;
    _greetingLabel.text = chatSettings.greeting;
}

#pragma mark - Public methods

- (CGFloat)desiredHeightWithTopInset:(CGFloat)topInset
{
    if (self.showsLabels) {
        return [self _extraNavigationBarHeight] + topInset;
    } else {
        return topInset;
    }
}

- (void)setSessionId:(NSString *)sessionId
{
    if (_sessionId == sessionId || [_sessionId isEqualToString:sessionId]) {
        return;
    }
    _sessionId = [sessionId copy];
    [self setNeedsLayout];

    [_chatMessagesDataSource removeListener:self];
    _chatMessagesDataSource = [_userSession chatMessagesDataSourceForSessionId:_sessionId];
    [_chatMessagesDataSource addListener:self];
    [_avatarImageView setUserId:_chatMessagesDataSource.firstOtherUserId];
    [self _updateTextLabels];
}

- (void)setShowsLabels:(BOOL)showsLabels
{
    _showsLabels = showsLabels;
    [self setNeedsLayout];
}

#pragma mark - KUSObjectDataSourceListener

- (void)objectDataSourceDidLoad:(KUSObjectDataSource *)dataSource
{
    [self _updateTextLabels];
}

#pragma mark - KUSPaginatedDataSourceListener methods

- (void)paginatedDataSourceDidChangeContent:(KUSPaginatedDataSource *)dataSource
{
    [_avatarImageView setUserId:_chatMessagesDataSource.firstOtherUserId];
    [self _updateTextLabels];
}

#pragma mark - UIAppearance methods

- (void)setNameColor:(UIColor *)nameColor
{
    _nameColor = nameColor;
    _nameLabel.textColor = _nameColor;
}

- (void)setNameFont:(UIFont *)nameFont
{
    _nameFont = nameFont;
    _nameLabel.font = _nameFont;
}

- (void)setGreetingColor:(UIColor *)greetingColor
{
    _greetingColor = greetingColor;
    _greetingLabel.textColor = _greetingColor;
}

- (void)setGreetingFont:(UIFont *)greetingFont
{
    _greetingFont = greetingFont;
    _greetingLabel.font = _greetingFont;
}

- (void)setSeparatorColor:(UIColor *)separatorColor
{
    _separatorColor = separatorColor;
    _separatorView.backgroundColor = _separatorColor;
}

@end