//
//  URLRequestBuilder.h
//  Sociality
//
//  Created by Macbook on 27.09.10.
//  Copyright 2010 CleverUA. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
  RequestMethodGet,
  RequestMethodPost
} RequestMethodType;


@interface URLRequestBuilder : NSObject 
{
  RequestMethodType   method;
  NSString            *url;
  NSDictionary        *parameters;
  
  // file's data
  NSMutableArray      *fileParams;
  NSMutableArray      *fileNames;
  NSMutableArray      *fileMimeTypes;
  NSMutableArray      *fileContents;
}

- (id)initWithMethod:(RequestMethodType)method url:(NSString *)url parameters:(NSDictionary *)parameters;
- (void)addFile:(NSData *)data paramName:(NSString *)paramName contentType:(NSString *)contentType fileName:(NSString *)fileName;
- (NSURLRequest *)initRequest;
@end
