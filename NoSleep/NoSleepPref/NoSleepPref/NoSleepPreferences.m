//
//  nosleep_preferences.m
//  nosleep-preferences
//
//  Created by Pavel Prokofiev on 4/2/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NoSleepPreferences.h"
#import <IOKit/IOMessage.h>
#import <NoSleep/GlobalConstants.h>
#import <NoSleep/Utilities.h>
#import <Sparkle/Sparkle.h>

@implementation NoSleepPreferences

#define appID "com.protech.NoSleep"
#define isBWIconEnabledID "IsBWIconEnabled"

- (void)updater:(SUUpdater *)updater didFinishLoadingAppcast:(SUAppcast *)appcast {
    [self didChangeValueForKey:@"lastUpdateDate"];
}

- (SUUpdater *)updater {
    return [SUUpdater updaterForBundle:[NSBundle bundleWithPath:@NOSLEEP_HELPER_PATH]];
}

- (IBAction)updateNow:(id)sender {
    [self willChangeValueForKey:@"lastUpdateDate"];
    [[self updater] checkForUpdates:sender];
}

- (BOOL)autoUpdate {
    return [[self updater] automaticallyChecksForUpdates];
}

- (void)setAutoUpdate:(BOOL)value {
    [[self updater] setAutomaticallyChecksForUpdates:value];
}

- (NSString *)lastUpdateDate {
    return [NSDateFormatter localizedStringFromDate:[[self updater] lastUpdateCheckDate]
                                          dateStyle:NSDateFormatterFullStyle
                                          timeStyle:NSDateFormatterFullStyle];
}

- (BOOL)isBWEnabled {
    Boolean b = false;
    Boolean ret = CFPreferencesGetAppBooleanValue(CFSTR(isBWIconEnabledID), CFSTR(appID), &b);
    if(b) {
        return ret;
    }
    return NO;
}

- (void)setIsBWEnabled:(BOOL)value {
    CFBooleanRef booleanValue = value?kCFBooleanTrue:kCFBooleanFalse;
    CFPreferencesSetAppValue(CFSTR(isBWIconEnabledID), booleanValue, CFSTR(appID));
    CFPreferencesAppSynchronize(CFSTR(appID));
    
    NSDistributedNotificationCenter *center = [NSDistributedNotificationCenter defaultCenter];
    [center postNotificationName: @"UpdateSettings"
                          object: [NSString stringWithCString:appID encoding:NSASCIIStringEncoding]
                        userInfo: nil
              deliverImmediately: YES];
}

- (id)initWithBundle:(NSBundle *)bundle
{
    // Initialize the location of our preferences
    if ((self = [super initWithBundle:bundle]) != nil) {
        m_noSleepInterface = nil;
    }
    
    return self;
}

- (void)notificationReceived:(uint32_t)messageType :(void *)messageArgument
{
    [self updateEnableState];
}

- (void)updateEnableState
{
    stateAC = [m_noSleepInterface stateForMode:kNoSleepModeAC];
    stateBattery = [m_noSleepInterface stateForMode:kNoSleepModeBattery];
    [m_checkBoxEnableAC setState:stateAC];
    [m_checkBoxEnableBattery setState:stateBattery];
}

- (void)willSelect
{
    if(m_noSleepInterface == nil) {
         m_noSleepInterface = [[NoSleepInterfaceWrapper alloc] init];   
    }
    
    if([[NSFileManager defaultManager] fileExistsAtPath:@NOSLEEP_HELPER_PATH]) {
        [m_checkBoxShowIcon setEnabled:YES];
        [m_checkBoxShowIcon setState:registerLoginItem(kLICheck)];
        
        [m_checkBoxShowIcon setToolTip:@""];
    } else {
        [m_checkBoxShowIcon setEnabled:NO];
        [m_checkBoxShowIcon setState:NO];
        
        [m_checkBoxShowIcon setToolTip:@"("@NOSLEEP_HELPER_PATH@" not found)"];
    }
    
    if(!m_noSleepInterface) {
        [m_checkBoxEnableAC setEnabled:NO];
        [m_checkBoxEnableAC setState:NO];
        [m_checkBoxEnableBattery setEnabled:NO];
        [m_checkBoxEnableBattery setState:NO];
    } else {
        [m_checkBoxEnableAC setEnabled:YES];
        [m_checkBoxEnableBattery setEnabled:YES];
        [m_noSleepInterface setNotificationDelegate:self];
        [self updateEnableState];
    }
}

- (void)didSelect {
    if(!m_noSleepInterface) {
        SHOW_UI_ALERT_KEXT_NOT_LOADED();           
    }
    
    [[self updater] setDelegate:self];
}

- (void)didUnselect {
    if(!m_noSleepInterface) {
        [m_noSleepInterface release];
        m_noSleepInterface = nil;
    }
    
    [[self updater] setDelegate:nil];
}

- (IBAction)checkboxEnableACClicked:(id)sender {
    BOOL newState = [m_checkBoxEnableAC state];
    if(newState != stateAC) {
        [m_noSleepInterface setState:newState forMode:kNoSleepModeAC];
        stateAC = newState;
    }
}

- (IBAction)checkboxEnableBatteryClicked:(id)sender {
    BOOL newState = [m_checkBoxEnableBattery state];
    if(newState != stateBattery) {
        [m_noSleepInterface setState:newState forMode:kNoSleepModeBattery];
        stateBattery = newState;
    }
}

- (void)checkboxShowIconClicked:(id)sender {
    BOOL showIconState = [m_checkBoxShowIcon state];
    if(showIconState) {
        registerLoginItem(kLIRegister);
    } else {
        registerLoginItem(kLIUnregister);
    }
}

@end
