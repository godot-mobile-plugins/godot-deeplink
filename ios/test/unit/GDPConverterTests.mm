//
// © 2024-present https://github.com/cengiz-pz
//

#import <XCTest/XCTest.h>

#import "gdp_converter.h"

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
static NSString *godotStringToNSString(const String &s) {
    return [NSString stringWithUTF8String:s.utf8().get_data()];
}

// ---------------------------------------------------------------------------
// GDPConverterTests
// ---------------------------------------------------------------------------

@interface GDPConverterTests : XCTestCase
@end

@implementation GDPConverterTests

// -- nsStringToGodotString ----------------------------------------------------

- (void)test_nsStringToGodotString_normalASCII_roundTrips {
    NSString *input = @"hello world";
    String result = [GDPConverter nsStringToGodotString:input];
    XCTAssertEqualObjects(godotStringToNSString(result), input);
}

- (void)test_nsStringToGodotString_emptyString_returnsEmptyGodotString {
    String result = [GDPConverter nsStringToGodotString:@""];
    XCTAssertTrue(result.is_empty());
}

- (void)test_nsStringToGodotString_unicodeCharacters_roundTrips {
    NSString *emoji = @"🎮 Godot 🦕";
    String result = [GDPConverter nsStringToGodotString:emoji];
    XCTAssertEqualObjects(godotStringToNSString(result), emoji);
}

- (void)test_nsStringToGodotString_specialURLCharacters_preserved {
    NSString *url = @"https://example.com/path?q=1&r=2#top";
    String result = [GDPConverter nsStringToGodotString:url];
    XCTAssertEqualObjects(godotStringToNSString(result), url);
}

// -- nsNumberToGodotVariant ----------------------------------------------------

- (void)test_nsNumberToGodotVariant_positiveInt_isInt {
    NSNumber *num = @42;
    Variant v = [GDPConverter nsNumberToGodotVariant:num];
    XCTAssertEqual((int64_t)v, 42LL);
}

- (void)test_nsNumberToGodotVariant_negativeInt_isNegative {
    Variant v = [GDPConverter nsNumberToGodotVariant:@(-7)];
    XCTAssertEqual((int64_t)v, -7LL);
}

- (void)test_nsNumberToGodotVariant_zero_isZero {
    Variant v = [GDPConverter nsNumberToGodotVariant:@0];
    XCTAssertEqual((int64_t)v, 0LL);
}

- (void)test_nsNumberToGodotVariant_boolTrue_isOne {
    Variant v = [GDPConverter nsNumberToGodotVariant:@YES];
    XCTAssertEqual((int64_t)v, 1LL);
}

- (void)test_nsNumberToGodotVariant_boolFalse_isZero {
    Variant v = [GDPConverter nsNumberToGodotVariant:@NO];
    XCTAssertEqual((int64_t)v, 0LL);
}

- (void)test_nsNumberToGodotVariant_float_isDouble {
    NSNumber *num = @3.14f;
    Variant v = [GDPConverter nsNumberToGodotVariant:num];
    XCTAssertEqual(v.get_type(), Variant::FLOAT);
    XCTAssertEqualWithAccuracy((double)v, 3.14, 0.001);
}

- (void)test_nsNumberToGodotVariant_double_isDouble {
    NSNumber *num = @2.718281828;
    Variant v = [GDPConverter nsNumberToGodotVariant:num];
    XCTAssertEqual(v.get_type(), Variant::FLOAT);
    XCTAssertEqualWithAccuracy((double)v, 2.718281828, 1e-9);
}

- (void)test_nsNumberToGodotVariant_largeInt64_preservesPrecision {
    int64_t big = INT64_MAX - 1;
    NSNumber *num = [NSNumber numberWithLongLong:big];
    Variant v = [GDPConverter nsNumberToGodotVariant:num];
    XCTAssertEqual((int64_t)v, big);
}

// -- nsArrayToGodotArray ------------------------------------------------------

- (void)test_nsArrayToGodotArray_emptyArray_returnsEmptyGodotArray {
    Array arr = [GDPConverter nsArrayToGodotArray:@[]];
    XCTAssertEqual(arr.size(), 0);
}

- (void)test_nsArrayToGodotArray_stringElements_roundTrip {
    NSArray *input = @[@"alpha", @"beta", @"gamma"];
    Array arr = [GDPConverter nsArrayToGodotArray:input];

    XCTAssertEqual(arr.size(), 3);
    XCTAssertEqualObjects(godotStringToNSString(String(arr[0])), @"alpha");
    XCTAssertEqualObjects(godotStringToNSString(String(arr[1])), @"beta");
    XCTAssertEqualObjects(godotStringToNSString(String(arr[2])), @"gamma");
}

- (void)test_nsArrayToGodotArray_numberElements_convertCorrectly {
    NSArray *input = @[@1, @2, @3];
    Array arr = [GDPConverter nsArrayToGodotArray:input];

    XCTAssertEqual(arr.size(), 3);
    XCTAssertEqual((int64_t)Variant(arr[0]), 1LL);
    XCTAssertEqual((int64_t)Variant(arr[1]), 2LL);
}

- (void)test_nsArrayToGodotArray_nestedArray_convertsRecursively {
    NSArray *inner = @[@"x", @"y"];
    NSArray *outer = @[inner, @"top"];
    Array arr = [GDPConverter nsArrayToGodotArray:outer];

    XCTAssertEqual(arr.size(), 2);
    // first element should itself be an Array
    XCTAssertEqual(Variant(arr[0]).get_type(), Variant::ARRAY);
}

- (void)test_nsArrayToGodotArray_nestedDictionary_convertsRecursively {
    NSDictionary *dict = @{@"key": @"value"};
    NSArray *input = @[dict];
    Array arr = [GDPConverter nsArrayToGodotArray:input];

    XCTAssertEqual(arr.size(), 1);
    XCTAssertEqual(Variant(arr[0]).get_type(), Variant::DICTIONARY);
}

- (void)test_nsArrayToGodotArray_unsupportedType_isSkipped {
    // NSNull is not handled; it should be silently skipped
    NSArray *input = @[[NSNull null], @"kept"];
    Array arr = [GDPConverter nsArrayToGodotArray:input];

    XCTAssertEqual(arr.size(), 1,
                   @"NSNull (unsupported) should be skipped, leaving only 1 element");
    XCTAssertEqualObjects(godotStringToNSString(String(arr[0])), @"kept");
}

- (void)test_nsArrayToGodotArray_mixedTypes_allConvertedInOrder {
    NSArray *input = @[@"hello", @99, @[@"nested"]];
    Array arr = [GDPConverter nsArrayToGodotArray:input];

    XCTAssertEqual(arr.size(), 3);
    XCTAssertEqual(Variant(arr[0]).get_type(), Variant::STRING);
    XCTAssertEqual(Variant(arr[1]).get_type(), Variant::INT);
    XCTAssertEqual(Variant(arr[2]).get_type(), Variant::ARRAY);
}

// -- nsDictionaryToGodotDictionary --------------------------------------------

- (void)test_nsDictionaryToGodotDictionary_emptyDict_returnsEmptyGodotDictionary {
    Dictionary d = [GDPConverter nsDictionaryToGodotDictionary:@{}];
    XCTAssertEqual(d.size(), 0);
}

- (void)test_nsDictionaryToGodotDictionary_stringSValue_roundTrips {
    NSDictionary *input = @{@"name": @"godot"};
    Dictionary d = [GDPConverter nsDictionaryToGodotDictionary:input];

    String val = d["name"];
    XCTAssertEqualObjects(godotStringToNSString(val), @"godot");
}

- (void)test_nsDictionaryToGodotDictionary_integerValue_convertsCorrectly {
    NSDictionary *input = @{@"count": @7};
    Dictionary d = [GDPConverter nsDictionaryToGodotDictionary:input];

    XCTAssertEqual((int64_t)Variant(d["count"]), 7LL);
}

- (void)test_nsDictionaryToGodotDictionary_floatValue_convertsCorrectly {
    NSDictionary *input = @{@"ratio": @0.5};
    Dictionary d = [GDPConverter nsDictionaryToGodotDictionary:input];

    XCTAssertEqualWithAccuracy((double)Variant(d["ratio"]), 0.5, 1e-9);
}

- (void)test_nsDictionaryToGodotDictionary_nestedDictionary_convertsRecursively {
    NSDictionary *nested = @{@"inner_key": @"inner_val"};
    NSDictionary *input = @{@"outer": nested};
    Dictionary d = [GDPConverter nsDictionaryToGodotDictionary:input];

    XCTAssertEqual(Variant(d["outer"]).get_type(), Variant::DICTIONARY);
    Dictionary inner = d["outer"];
    XCTAssertEqualObjects(godotStringToNSString(String(inner["inner_key"])), @"inner_val");
}

- (void)test_nsDictionaryToGodotDictionary_arrayValue_convertsToGodotArray {
    NSDictionary *input = @{@"items": @[@"a", @"b"]};
    Dictionary d = [GDPConverter nsDictionaryToGodotDictionary:input];

    XCTAssertEqual(Variant(d["items"]).get_type(), Variant::ARRAY);
    Array arr = d["items"];
    XCTAssertEqual(arr.size(), 2);
}

- (void)test_nsDictionaryToGodotDictionary_nonStringKey_isSkipped {
    // Only NSString keys are accepted per the implementation.
    NSDictionary *input = @{@1: @"number_key_value"};
    Dictionary d = [GDPConverter nsDictionaryToGodotDictionary:input];

    XCTAssertEqual(d.size(), 0, @"Non-NSString keys must be silently skipped");
}

- (void)test_nsDictionaryToGodotDictionary_multipleKeys_allPresent {
    NSDictionary *input = @{@"a": @"alpha", @"b": @"beta", @"c": @"gamma"};
    Dictionary d = [GDPConverter nsDictionaryToGodotDictionary:input];

    XCTAssertEqual(d.size(), 3);
}

@end
