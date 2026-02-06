//
// © 2024-present https://github.com/cengiz-pz
//

#ifndef gdp_converter_h
#define gdp_converter_h

#import <Foundation/Foundation.h>
#include "core/object/class_db.h"


@interface GDPConverter : NSObject

// From Godot


// To Godot
+ (String) nsStringToGodotString:(NSString*) nsString;
+ (Variant)nsNumberToGodotVariant:(NSNumber *)number;
+ (Array)nsArrayToGodotArray:(NSArray *)nsArray;
+ (Dictionary) nsDictionaryToGodotDictionary:(NSDictionary*) nsDictionary;

@end

#endif /* gdp_converter_h */
