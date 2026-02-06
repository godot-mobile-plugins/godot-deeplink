//
// © 2024-present https://github.com/cengiz-pz
//

#import "gdp_converter.h"


@implementation GDPConverter

// FROM GODOT


// TO GODOT

+ (String) nsStringToGodotString:(NSString*) nsString {
	return [nsString UTF8String];
}


+ (Dictionary)nsDictionaryToGodotDictionary:(NSDictionary *)nsDictionary {
	Dictionary dictionary;

	for (NSObject *keyObject in nsDictionary) {
		if (![keyObject isKindOfClass:[NSString class]]) {
			continue;
		}

		NSString *key = (NSString *)keyObject;
		NSObject *valueObject = nsDictionary[key];
		if (!valueObject) {
			continue;
		}

		const char *godotKey = [key UTF8String];

		if ([valueObject isKindOfClass:[NSString class]]) {
			dictionary[godotKey] = [(NSString *)valueObject UTF8String];
		}
		else if ([valueObject isKindOfClass:[NSNumber class]]) {
			dictionary[godotKey] =
				[GDPConverter nsNumberToGodotVariant:(NSNumber *)valueObject];
		}
		else if ([valueObject isKindOfClass:[NSDictionary class]]) {
			dictionary[godotKey] =
				[GDPConverter nsDictionaryToGodotDictionary:(NSDictionary *)valueObject];
		}
		else if ([valueObject isKindOfClass:[NSArray class]]) {
			dictionary[godotKey] =
				[GDPConverter nsArrayToGodotArray:(NSArray *)valueObject];
		}
	}

	return dictionary;
}


+ (Variant)nsNumberToGodotVariant:(NSNumber *)number {
	const char *type = [number objCType];

	// Floating point
	if (strcmp(type, @encode(float)) == 0 ||
		strcmp(type, @encode(double)) == 0) {
		return Variant([number doubleValue]);
	}

	// Integer / Boolean / Char / Long
	return Variant((int64_t)[number longLongValue]);
}


+ (Array)nsArrayToGodotArray:(NSArray *)nsArray {
	Array godotArray;

	for (NSObject *element in nsArray) {

		if ([element isKindOfClass:[NSString class]]) {
			godotArray.append([(NSString *)element UTF8String]);
		}
		else if ([element isKindOfClass:[NSNumber class]]) {
			godotArray.append(
				[GDPConverter nsNumberToGodotVariant:(NSNumber *)element]
			);
		}
		else if ([element isKindOfClass:[NSDictionary class]]) {
			godotArray.append(
				[GDPConverter nsDictionaryToGodotDictionary:(NSDictionary *)element]
			);
		}
		else if ([element isKindOfClass:[NSArray class]]) {
			godotArray.append(
				[GDPConverter nsArrayToGodotArray:(NSArray *)element]
			);
		}
		// NSNull / unsupported types ignored
	}

	return godotArray;
}

@end
