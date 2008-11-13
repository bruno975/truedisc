//
//  main.m
//  TrueDisc
//
//  Created by Erich Ocean on 2/16/07.
//  Copyright Erich Atlas Ocean 2007. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#ifdef LICENSE_CONTROL
#include <LicenseControl/LicenseControl.h>
#endif

int main(int argc, char *argv[])
{
#ifdef LICENSE_CONTROL
    return LC_Main( argc, (const char *)argv, YES );
#else
    return NSApplicationMain( argc,  (const char **) argv );
#endif
}
