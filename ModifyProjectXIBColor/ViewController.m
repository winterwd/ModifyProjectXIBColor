//
//  ViewController.m
//  ModifyProjectXIBColor
//
//  Created by winter on 16/3/21.
//  Copyright © 2016年 winter. All rights reserved.
//

#import "ViewController.h"
#import "WDColorModel.h"

@interface ViewController ()
@property (weak) IBOutlet NSTextField *modifySuccess;
@property (weak) IBOutlet NSTextField *modifyFailed;

@property (weak) IBOutlet NSProgressIndicator *indicator;

@property (nonatomic, strong) NSMutableArray *xibFilePaths;
@property (nonatomic, strong) NSMutableArray *storyboardFilePaths;

/** 替换的 */
@property (nonatomic, strong) WDColorModel *modifyColorModel;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
    self.xibFilePaths = [NSMutableArray array];
    self.storyboardFilePaths = [NSMutableArray array];
    
    [self.indicator startAnimation:nil];
    
    // 工程总目录 源文件路径绝对
    NSString *sourcePath = @"/Users";
    
    // 工程修改前颜色 RGB
    NSInteger red_pre = 237;
    NSInteger green_pre = 109;
    NSInteger blue_pre = 31;
    
    // 修改后的颜色 RGB
    NSInteger red_mod = 255;
    NSInteger green_mod = 96;
    NSInteger blue_mod = 0;
    
    // 修改后的颜色 RGB
    self.modifyColorModel = [[WDColorModel alloc] init];
    self.modifyColorModel.red = [NSString stringWithFormat:@"%.4f",red_mod/255.0];
    self.modifyColorModel.green = [NSString stringWithFormat:@"%.4f",green_mod/255.0];
    self.modifyColorModel.blue = [NSString stringWithFormat:@"%.4f",blue_mod/255.0];
    
    // 工程修改前颜色 RGB
    WDColorModel *objColorModel = [[WDColorModel alloc] init];
    objColorModel.red = [NSString stringWithFormat:@"%.4f",red_pre/255.0];
    objColorModel.green = [NSString stringWithFormat:@"%.4f",green_pre/255.0];
    objColorModel.blue = [NSString stringWithFormat:@"%.4f",blue_pre/255.0];
    
    [self findXibOrStoryboardFile:sourcePath];
    [self modifyColorModel:objColorModel];
}

// 搜索xib/storyboard文件
- (void)findXibOrStoryboardFile:(NSString*)path
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir = NO;
    if ([fileManager fileExistsAtPath:path isDirectory:&isDir]&&isDir) {
        NSArray* files = [fileManager contentsOfDirectoryAtPath:path error:nil];
        for (NSString* file in files) {
            [self findXibOrStoryboardFile:[path stringByAppendingPathComponent:file]];
        }
    } else {
        if ([path containsString:@".xib"]) {
            [self.xibFilePaths addObject:path];
        }
        else if ([path containsString:@".storyboard"]) {
            [self.storyboardFilePaths addObject:path];
        }
    }
}

static NSInteger flag = 0; // 记录修改

// 开始修改颜色 objColorModel : 需要被替换的
- (void)modifyColorModel:(WDColorModel *)objColorModel
{
    BOOL xibResult = [self modifyColorModel:objColorModel filePaths:self.xibFilePaths];
    BOOL storyboardResult =[self modifyColorModel:objColorModel filePaths:self.storyboardFilePaths];
    
    [self.indicator stopAnimation:nil];
    self.indicator.hidden = YES;
    if (xibResult && storyboardResult) {
        self.modifySuccess.hidden = NO;
        self.modifyFailed.hidden = YES;
    }
    else {
        self.modifySuccess.hidden = YES;
        self.modifyFailed.hidden = NO;
    }
    
    if (self.xibFilePaths.count == 0 && self.storyboardFilePaths.count == 0) {
        NSLog(@"error = 该路径下没有xib/storyboard文件");
    }
    else {
        NSLog(@"修改 %ld 处颜色", (long)flag);
    }
}

// 修改 并返回结果
- (BOOL)modifyColorModel:(WDColorModel *)objColorModel filePaths:(NSMutableArray *)filePaths
{
    BOOL result = NO;
    for (NSString *filePath in filePaths) {
        NSData *xmlData = [NSData dataWithContentsOfFile:filePath];
        NSXMLDocument *document = [self parsedDataFromData:xmlData colorModel:objColorModel];
        // 存储新的
        result = [self saveXMLFile:filePath xmlDoucment:document];
    }
    return result;
}

// 获取 XMLDocument
- (NSXMLDocument *)parsedDataFromData:(NSData *)data colorModel:(WDColorModel *)objColorModel
{
    NSError *error = nil;
    NSXMLDocument *document = [[NSXMLDocument alloc] initWithData:data options:NSXMLNodePreserveWhitespace error:&error];
    NSXMLElement *rootElement = document.rootElement;
    [self parsedXMLElement:rootElement objColorModel:objColorModel];
    
    if (error) {
        NSLog(@"error = %@",error);
    }
    return document;
}

// 修改元素
- (void)parsedXMLElement:(NSXMLElement *)element objColorModel:(WDColorModel *)objColorModel
{
    for (NSXMLElement *subElement in element.children) {
        NSXMLElement *objNode = nil;
        NSInteger index = subElement.index;
        if ([subElement.name isEqualToString:@"color"]) {
            WDColorModel *obj = [WDColorModel colorModelWithArray:subElement.attributes];
            if ([obj isEqual:objColorModel]) {
                objNode = [self creatXMLNodel:obj];
                flag++;
            }
        }
        if (objNode) {
            // 替换
            [element replaceChildAtIndex:index withNode:objNode];
        }
        [self parsedXMLElement:subElement objColorModel:objColorModel];
    }
}

// 设置新的 NSXMLElement
- (NSXMLElement *)creatXMLNodel:(WDColorModel *)obj
{
    NSXMLElement *subNode = [NSXMLElement elementWithName:@"color"];
    [subNode addAttribute:[NSXMLNode attributeWithName:@"key" stringValue:obj.key]];
    [subNode addAttribute:[NSXMLNode attributeWithName:@"red" stringValue:self.modifyColorModel.red]];
    [subNode addAttribute:[NSXMLNode attributeWithName:@"green" stringValue:self.modifyColorModel.green]];
    [subNode addAttribute:[NSXMLNode attributeWithName:@"blue" stringValue:self.modifyColorModel.blue]];
    [subNode addAttribute:[NSXMLNode attributeWithName:@"alpha" stringValue:obj.alpha]];
    [subNode addAttribute:[NSXMLNode attributeWithName:@"colorSpace" stringValue:obj.colorSpace]];
    return subNode;
}

- (BOOL)saveXMLFile:(NSString *)destPath xmlDoucment:(NSXMLDocument *)XMLDoucment
{
    if (XMLDoucment == nil) {
        return NO;
    }
    
    if ( ! [[NSFileManager defaultManager] fileExistsAtPath:destPath]) {
        if ( ! [[NSFileManager defaultManager] createFileAtPath:destPath contents:nil attributes:nil]){
            return NO;
        }
    }
    
    NSData *XMLData = [XMLDoucment XMLDataWithOptions:NSXMLNodePrettyPrint];
    if (![XMLData writeToFile:destPath atomically:YES]) {
        NSLog(@"Could not write document out...");
        return NO;
    }
    return YES;
}

@end
