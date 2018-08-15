//
//  ViewController.m
//  QRCodeTest
//
//  Created by lidong on 2018/8/13.
//  Copyright © 2018年 macbook. All rights reserved.
//
#define URL @"https://qth.nowbook.com/api/extend/user/selectUserQr"
#define Inviter @"https://qth.nowbook.com/api/extend/user/getMobileByInviter"

#import "ViewController.h"
#import <AFNetworking.h>
#import <SDWebImageManager.h>
#import <LBXScanNative.h>

@interface ViewController ()

@property (nonatomic, strong) UIButton * startBtn;

@property (nonatomic, strong) UIButton * testBtn;

@property (nonatomic, strong) UILabel * downloadsLabel;

@property (nonatomic, strong) NSMutableArray *allQRCodeUrlArray;

@property (nonatomic, strong) NSMutableArray *allQRCodeImagesArray;

@property (nonatomic, strong) NSMutableArray *allUserIdArray;

@property (nonatomic, strong) NSMutableArray *allInviterInfoArray;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor redColor];
    
    [self.view addSubview:self.startBtn];
    
    [self.view addSubview:self.downloadsLabel];
    
    [self.view addSubview:self.testBtn];
    
}

- (void)startTest{
    
    [self loadData];
    
}

- (void)TestBtnPress{
    
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadData {
    
    AFHTTPSessionManager * manager = [AFHTTPSessionManager manager];
    
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
   
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json",@"text/html" , nil];
    
    [manager GET:URL parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
     
        [self.allQRCodeUrlArray removeAllObjects];
        
        if ([responseObject[@"data"][@"success"] boolValue]==1) {
            
            NSArray *result = responseObject[@"data"][@"result"];
            
            for (int i = 0; i < result.count; i ++) {
                
                NSDictionary *dic = result[i];
                
                if(![dic isKindOfClass:[NSNull class]]){
                    
                    NSString * codeUrl = dic[@"qrCodeUrl"];
                    
                    [self.allQRCodeUrlArray addObject:codeUrl];
                    
                    NSString *log = [NSString stringWithFormat:@"已经下载了：%d个图片地址", i];
                    
                    NSLog(@"%@", log);
                    
                    
                }
                
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                //回调或者说是通知主线程刷新，
                self.downloadsLabel.text = [NSString stringWithFormat:@"已下载：%ld个图片地址", self.allQRCodeUrlArray.count];
            });
            
            
            [self convertImages];
            
        }
        else if([responseObject[@"data"][@"success"] boolValue]==0)
        {
            
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        NSLog(@"%@", error);
        
    }];
    
}

- (void)convertImages {
    
//    SDWebImageManager *manager = [[SDWebImageManager alloc]init];
    
    [self.allQRCodeImagesArray removeAllObjects];
    
    int pageNum = 10;
    int pageSize = 500;
    
    int limitCount = pageNum * pageSize;
    if(limitCount >= self.allQRCodeUrlArray.count){
        
        limitCount = (int)self.allQRCodeUrlArray.count;
        
    }

    
    for (int i = (pageNum - 1) * pageSize; i < limitCount; i ++) {
        
        NSString *urlStr = self.allQRCodeUrlArray[i];
        
        if([urlStr containsString:@"http://qth.oss"]){
            
            NSURL *codeUrl = [NSURL URLWithString:urlStr];
            
            NSData * data = [NSData dataWithContentsOfURL:codeUrl];
            
            UIImage *codeImage = [UIImage imageWithData:data];
            
            [self.allQRCodeImagesArray addObject:codeImage];
            
            NSLog(@"已经转成UIImages: %d个", i);
            
        }else{
            
            NSLog(@"url: %@, 转不成UIImage", urlStr);
            
        }
        
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        //回调或者说是通知主线程刷新，
        self.downloadsLabel.text = [NSString stringWithFormat:@"已生成：%ld个UIImage", self.allQRCodeImagesArray.count];
    });
    
    [self ScanAllImages];
    
}

- (void)ScanAllImages {
    
    [self.allUserIdArray removeAllObjects];
    
    for (int i = 0; i < self.allQRCodeImagesArray.count; i ++) {
        
        UIImage *image = self.allQRCodeImagesArray[i];
        
        CIDetector*detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:@{ CIDetectorAccuracy : CIDetectorAccuracyHigh }];
        NSArray *features = [detector featuresInImage:[CIImage imageWithCGImage:image.CGImage]];
        NSMutableArray<LBXScanResult*> *mutableArray = [[NSMutableArray alloc]initWithCapacity:1];
        for (int index = 0; index < [features count]; index ++)
        {
            CIQRCodeFeature *feature = [features objectAtIndex:index];
            NSString *scannedResult = feature.messageString;
//            NSLog(@"result:%@",scannedResult);
            
            LBXScanResult *item = [[LBXScanResult alloc]init];
            item.strScanned = scannedResult;
            item.strBarCodeType = CIDetectorTypeQRCode;
            item.imgScanned = image;
            [mutableArray addObject:item];
        }
        
        LBXScanResult *scanResult = mutableArray[0];
        
        NSString*strResult = scanResult.strScanned;
        
        NSDictionary *scanResultDic = [self getURLParameters:strResult];
        
        NSString *userId = scanResultDic[@"userId"];
        
        [self.allUserIdArray addObject:userId];
        
        NSLog(@"已经添加userId：%d个", i);
        
//        [LBXScanNative recognizeImage:image success:^(NSArray<LBXScanResult *> *array) {
//
//            LBXScanResult *scanResult = array[0];
//
//            NSString*strResult = scanResult.strScanned;
//
//            NSDictionary *scanResultDic = [self getURLParameters:strResult];
//
//            NSString *userId = scanResultDic[@"userId"];
//
//            [self.allUserIdArray addObject:userId];
//
//            NSLog(@"已经添加userId：%d个", i);
//
//        }];
        
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        //回调或者说是通知主线程刷新，
        self.downloadsLabel.text = [NSString stringWithFormat:@"已生成userId：%ld个", self.allUserIdArray.count];
    });
    
    NSString * allUserIds = [self.allUserIdArray componentsJoinedByString:@","];
    
    NSLog(@"allUserIds: %@", allUserIds);
    
//    [self getInveter];
    
}


- (void)getInveter {
    
    [self.allInviterInfoArray removeAllObjects];
    
    for (int i = 0; i < self.allUserIdArray.count; i ++) {
        
        NSDictionary * paramDic = @{
                                    @"inviter": self.allUserIdArray[i]
                                    };
        
        AFHTTPSessionManager * manager = [AFHTTPSessionManager manager];
        
        manager.responseSerializer = [AFJSONResponseSerializer serializer];
        
        manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json",@"text/html" , nil];
        
        [manager GET:Inviter parameters:paramDic progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            
            if ([responseObject[@"data"][@"success"] boolValue]==1) {
                
                NSLog(@"获得推荐人成功：%d", i);
                
                NSDictionary *dic = @{
                                      @"inviter": [NSString stringWithFormat:@"%@", responseObject],
                                      @"index": [NSString stringWithFormat:@"%d", i]
                                      };
                
                [self.allInviterInfoArray addObject:dic];
                
            }
            else if([responseObject[@"data"][@"success"] boolValue]==0)
            {
                NSLog(@"获得推荐人失败：%d", i);
                
                NSDictionary *dic = @{
                                      @"inviter": @"null",
                                      @"index": [NSString stringWithFormat:@"%d", i]
                                      };
                
                [self.allInviterInfoArray addObject:dic];
                
            }
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            
            NSLog(@"%@", error);
            
        }];
        
    }
    
}

- (UIButton *)startBtn{
    
    if(!_startBtn){
        
        _startBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        
        _startBtn.frame = CGRectMake(50, 150, 200, 50);
        
        _startBtn.backgroundColor = [UIColor blackColor];
        
        [_startBtn setTitle:@"开始" forState: UIControlStateNormal];
        
        [_startBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        
        [_startBtn addTarget:self action:@selector(startTest) forControlEvents:UIControlEventTouchUpInside];
        
    }
    
    return _startBtn;
}

- (UIButton *)testBtn{
    
    if(!_testBtn){
        
        _testBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        
        _testBtn.frame = CGRectMake(50, 450, 200, 50);
        
        _testBtn.backgroundColor = [UIColor blackColor];
        
        [_testBtn setTitle:@"测试" forState: UIControlStateNormal];
        
        [_testBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        
        [_testBtn addTarget:self action:@selector(TestBtnPress) forControlEvents:UIControlEventTouchUpInside];
        
    }
    
    return _testBtn;
}

- (NSMutableArray *)allQRCodeUrlArray {
    
    if(!_allQRCodeUrlArray){
        
        _allQRCodeUrlArray = [NSMutableArray array];
        
    }
    
    return _allQRCodeUrlArray;
}

- (NSMutableArray *)allQRCodeImagesArray {
    
    if(!_allQRCodeImagesArray){
        
        _allQRCodeImagesArray = [NSMutableArray array];
        
    }
    
    return _allQRCodeImagesArray;
}

- (NSMutableArray *)allUserIdArray {
    
    if(!_allUserIdArray){
        
        _allUserIdArray = [NSMutableArray array];
        
    }
    
    return _allUserIdArray;
}

- (NSMutableArray *)allInviterInfoArray {
    
    if(!_allInviterInfoArray){
        
        _allInviterInfoArray = [NSMutableArray array];
        
    }
    
    return _allInviterInfoArray;
}

- (UILabel *)downloadsLabel {
    
    if(!_downloadsLabel) {
        
        _downloadsLabel = [[UILabel alloc]init];
        
        _downloadsLabel.frame = CGRectMake(50 , 250, 200, 50);
        
        _downloadsLabel.textColor = [UIColor blackColor];
        
    }
    
    return _downloadsLabel;
}

/**
 *  截取URL中的参数
 *
 *  @return NSMutableDictionary parameters
 */
- (NSMutableDictionary *)getURLParameters:(NSString *)urlStr {
    
    // 查找参数
    NSRange range = [urlStr rangeOfString:@"?"];
    if (range.location == NSNotFound) {
        return nil;
    }
    
    // 以字典形式将参数返回
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    
    // 截取参数
    NSString *parametersString = [urlStr substringFromIndex:range.location + 1];
    
    // 判断参数是单个参数还是多个参数
    if ([parametersString containsString:@"&"]) {
        
        // 多个参数，分割参数
        NSArray *urlComponents = [parametersString componentsSeparatedByString:@"&"];
        
        for (NSString *keyValuePair in urlComponents) {
            // 生成Key/Value
            NSArray *pairComponents = [keyValuePair componentsSeparatedByString:@"="];
            
            //            NSString *key = [pairComponents.firstObject stringByRemovingPercentEncoding];
            //            NSString *value = [pairComponents.lastObject stringByRemovingPercentEncoding];
            
            NSString *key = [NSString stringWithFormat:@"%@",pairComponents.firstObject];
            NSString *value = [NSString stringWithFormat:@"%@",pairComponents.lastObject];
            
            
            // Key不能为nil
            if (key == nil || value == nil) {
                continue;
            }
            
            id existValue = [params valueForKey:key];
            
            if (existValue != nil) {
                
                // 已存在的值，生成数组
                if ([existValue isKindOfClass:[NSArray class]]) {
                    // 已存在的值生成数组
                    NSMutableArray *items = [NSMutableArray arrayWithArray:existValue];
                    [items addObject:value];
                    
                    [params setValue:items forKey:key];
                } else {
                    
                    // 非数组
                    [params setValue:@[existValue, value] forKey:key];
                }
                
            } else {
                
                // 设置值
                [params setValue:value forKey:key];
            }
        }
    } else {
        // 单个参数
        
        // 生成Key/Value
        NSArray *pairComponents = [parametersString componentsSeparatedByString:@"="];
        
        // 只有一个参数，没有值
        if (pairComponents.count == 1) {
            return nil;
        }
        
        // 分隔值
        //        NSString *key = [pairComponents.firstObject stringByRemovingPercentEncoding];
        //        NSString *value = [pairComponents.lastObject stringByRemovingPercentEncoding];
        
        NSString *key = [NSString stringWithFormat:@"%@",pairComponents.firstObject];
        NSString *value = [NSString stringWithFormat:@"%@",pairComponents.lastObject];
        
        // Key不能为nil
        if (key == nil || value == nil) {
            return nil;
        }
        
        // 设置值
        [params setValue:value forKey:key];
    }
    
    return params;
}

@end
