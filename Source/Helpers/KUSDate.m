//
//  KUSDate.m
//  Kustomer
//
//  Created by Daniel Amitay on 8/20/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KUSDate.h"
#import "Kustomer_Private.h"
#import "KUSUserSession.h"
#import "KUSLocalization.h"

const NSTimeInterval kSecondsPerMinute = 60.0;
const NSTimeInterval kMinutesPerHour = 60.0;
const NSTimeInterval kHoursPerDay = 24.0;
const NSTimeInterval kDaysPerWeek = 7.0;

@implementation KUSDate

+ (NSString *)humanReadableTextFromDate:(NSDate *)date
{
    if (date == nil) {
        return nil;
    }
    
    NSTimeInterval timeAgo = -[date timeIntervalSinceNow];
    if (timeAgo >= kSecondsPerMinute * kMinutesPerHour * kHoursPerDay * kDaysPerWeek) {
        NSTimeInterval count = timeAgo / (kSecondsPerMinute * kMinutesPerHour * kHoursPerDay * kDaysPerWeek);
        return _AgoTextWithCountAndUnit(count, @"week");
    } else if (timeAgo >= kSecondsPerMinute * kMinutesPerHour * kHoursPerDay) {
        NSTimeInterval count = timeAgo / (kSecondsPerMinute * kMinutesPerHour * kHoursPerDay);
        return _AgoTextWithCountAndUnit(count, @"day");
    } else if (timeAgo >= kSecondsPerMinute * kMinutesPerHour) {
        NSTimeInterval count = timeAgo / (kSecondsPerMinute * kMinutesPerHour);
        return _AgoTextWithCountAndUnit(count, @"hour");
    } else if (timeAgo >= kSecondsPerMinute) {
        NSTimeInterval count = timeAgo / (kSecondsPerMinute);
        return _AgoTextWithCountAndUnit(count, @"minute");
    } else {
        return [[KUSLocalization sharedInstance] localizedString:@"Just now"];
    }
}

+ (NSString *)humanReadableTextFromSeconds:(NSUInteger)seconds
{
    if (seconds < kSecondsPerMinute) {
        return _textWithCountAndUnit(seconds, @"second");
    } else if (seconds < kSecondsPerMinute * kMinutesPerHour) {
        int minutes = (int)ceil(seconds / kSecondsPerMinute);
        return _textWithCountAndUnit(minutes, @"minute");
    } else if (seconds < kSecondsPerMinute * kMinutesPerHour * kHoursPerDay) {
        int hours = (int)ceil(seconds / (kSecondsPerMinute * kMinutesPerHour));
        return _textWithCountAndUnit(hours, @"hour");
    } else {
        return [[KUSLocalization sharedInstance] localizedString:@"greater than one day"];
    }
}

+ (NSString *)humanReadableUpfrontVolumeControlWaitingTimeFromSeconds:(NSUInteger)seconds
{
    if (seconds == 0) {
        return [[KUSLocalization sharedInstance] localizedString:@"Someone should be with you momentarily"];
    } else {
        NSString *waitTime = [KUSDate humanReadableTextFromSeconds:seconds];
        NSString *localizedMessage = [[KUSLocalization sharedInstance] localizedString:@"Your expected wait time is"];
        return [[NSString alloc] initWithFormat:@"%@ %@", localizedMessage, waitTime];
    }
}

+ (NSString *)messageTimestampTextFromDate:(NSDate *)date
{
    return [_ShortRelativeDateFormatter() stringFromDate:date];
}

+ (NSDate *)dateFromString:(NSString *)string
{
    return (string.length ? [_ISO8601DateFormatterFromString() dateFromString:string] : nil);
}

+ (NSString *)stringFromDate:(NSDate *)date
{
    return (date ? [_ISO8601DateFormatterFromDate() stringFromDate:date] : nil);
}

#pragma mark - Helper logic

static NSDateFormatter *_ShortRelativeDateFormatter(void)
{
    static NSDateFormatter *_dateFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dateFormatter = [[NSDateFormatter alloc] init];
        _dateFormatter.timeStyle = NSDateFormatterShortStyle;
        _dateFormatter.dateStyle = NSDateFormatterShortStyle;
        _dateFormatter.locale = [[KUSLocalization sharedInstance] currentLocale];
        _dateFormatter.doesRelativeDateFormatting = YES;
    });
    return _dateFormatter;
}

static NSString *_AgoTextWithCountAndUnit(NSTimeInterval unitCount, NSString *unit)
{
    int integerUnit = (int)round(unitCount);
    NSString* ago = [[KUSLocalization sharedInstance] localizedString:@"ago"];
    NSString* localizedUnit = [[KUSLocalization sharedInstance] localizedString:[NSString stringWithFormat:@"%@%@", unit, (integerUnit > 1 ? @"s": @"")]];
    return [NSString stringWithFormat:@"%i %@ %@", integerUnit, localizedUnit, ago];
}

static NSString *_textWithCountAndUnit(NSTimeInterval unitCount, NSString *unit)
{
    int integerUnit = (int)round(unitCount);
    NSString* localizedUnit = [[KUSLocalization sharedInstance] localizedString:[NSString stringWithFormat:@"%@%@", unit, (integerUnit > 1 ? @"s": @"")]];
    return [NSString stringWithFormat:@"%i %@", integerUnit, localizedUnit];
}

static NSDateFormatter *_ISO8601DateFormatterFromDate(void)
{
    static NSDateFormatter *_dateFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"];
        [_dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
        [_dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    });
    return _dateFormatter;
}

static NSDateFormatter *_ISO8601DateFormatterFromString(void)
{
    static NSDateFormatter *_dateFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];
        [_dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
    });
    return _dateFormatter;
}

@end
