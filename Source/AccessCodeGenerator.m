//
//  AccessCodeGenerator.m
//  PSCodeGenerator
//
//  Created by Pan on 2017/5/15.
//  Copyright © 2017年 Sheng Pan. All rights reserved.
//

#import "AccessCodeGenerator.h"

@implementation AccessCodeGenerator

+ (NSArray<NSString *> *)lazyGetterForString:(NSString *)string {
    NSArray<PSProperty *> *props = [self propertyWithContent:string];
    NSMutableArray *result = [NSMutableArray array];
    for (PSProperty *model in props) {
        [result addObject:[self getterWithPSProperty:model]];
    }
    return result;
}

+ (NSArray<PSProperty *> *)propertyWithContent:(NSString *)content
{
    NSMutableArray *result = [NSMutableArray array];
    NSString * regularStr = @"@property([\\s\\S]*?);";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regularStr options:0 error:nil];
    NSArray *matches = [regex matchesInString:content options:0 range:NSMakeRange(0, content.length)];
    
    for (int i = 0; i < matches.count; i++) {
        
        NSRange propertyRange = [matches[i] range];
        if (propertyRange.length > 0) {
            
            NSString *propertyString = [content substringWithRange:propertyRange];
            if ([propertyString containsString:IB_OUTLET]) {
                continue;
            }
            
            NSArray *keywords = [self propertysKeywordsWithPropertyString:propertyString.copy];
            NSArray *dataTypeAndName = [self propertyTypeAndNameWithProperty:propertyString.copy];
            
            if (!dataTypeAndName.count)
            {
                continue;
            }
            
            PSProperty * proMoel = [[PSProperty alloc] init];
            proMoel.keywords = keywords;
            proMoel.dataType      = [dataTypeAndName firstObject];
            proMoel.name          = [dataTypeAndName lastObject];
            [result addObject:proMoel];
        }
    }
    return result;
}


+ (NSArray<NSString *> *)propertysKeywordsWithPropertyString:(NSString *)propertyStr
{
    NSString * propertyStr1 = propertyStr;
    NSString * regularStr = @"\\(.*\\)";
    NSRegularExpression *regex1 = [NSRegularExpression regularExpressionWithPattern:regularStr options:0 error:nil];
    NSArray *matches1 = [regex1 matchesInString:propertyStr1 options:0 range:NSMakeRange(0, propertyStr1.length)];
    
    for (int i = 0; i < matches1.count; i++)
    {
        NSRange firstHalfRange = [matches1[i] range];
        if (firstHalfRange.length > 0)
        {
            NSString *resultString = [[propertyStr1 substringWithRange:firstHalfRange] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            resultString = [resultString stringByReplacingOccurrencesOfString:@"(" withString:@""];
            resultString = [resultString stringByReplacingOccurrencesOfString:@")" withString:@""];
            return  [resultString componentsSeparatedByString:@","];
        }
    }
    return nil;
}

+ (NSMutableArray *)propertyTypeAndNameWithProperty:(NSString *)propertyStr;
{

    NSString * regularStr = @"\\).*\\;";
    NSRegularExpression *regex1 = [NSRegularExpression regularExpressionWithPattern:regularStr options:0 error:nil];
    NSArray *matches1 = [regex1 matchesInString:propertyStr options:0 range:NSMakeRange(0, propertyStr.length)];
    
    NSMutableArray *result = @[].mutableCopy;
    for (int i = 0 ; i < matches1.count; i++)
    {
        NSRange matchedRange =   [matches1[i] range];
        if (matchedRange.length > 0)
        {
            
            NSString *resultString = [[propertyStr substringWithRange:matchedRange]
                                      stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            resultString = [resultString stringByReplacingOccurrencesOfString:@")" withString:@""];
            resultString = [resultString stringByReplacingOccurrencesOfString:@";" withString:@""];
            if([propertyStr containsString:@"*"])
            {

                resultString = [resultString stringByReplacingOccurrencesOfString:@" " withString:@""];
                result =  [resultString componentsSeparatedByString:@"*"].mutableCopy;
            }
            else
            {
                result =  [resultString componentsSeparatedByString:@" "].mutableCopy;
                [result enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if ([obj isEqualToString:@""]) {
                        [result removeObject:obj];
                    }
                }];
            }
            return result;
        }
    }
    return result;
}


+ (NSString *)getterWithPSProperty:(PSProperty *)model
{
    NSString *lazyGetter = @"";
    if (![model.keywords containsObject:ASSIGN]
        && ![model.dataType isEqualToString:ID]) {
        lazyGetter = [NSString stringWithFormat:@"\n- (%@ *)%@ {\n	if (!_%@) {\n        _%@ = [[%@ alloc] init];\n	}\n	return _%@;\n}",
                      model.dataType,
                      model.name,
                      model.name,
                      model.name,
                      model.dataType,
                      model.name];
    }
    return lazyGetter;
}


@end
