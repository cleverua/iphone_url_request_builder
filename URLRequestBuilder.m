#import "URLRequestBuilder.h"

@interface URLRequestBuilder(PrivateMethods)
- (NSURLRequest *)initGetRequest;
- (NSURLRequest *)initPostRequest;
+ (NSString *)url:(NSString *)urlString withParameters:(NSDictionary *)params;
@end

@implementation URLRequestBuilder

- (id)initWithMethod:(RequestMethodType)theMethod url:(NSString *)theUrl parameters:(NSDictionary *)theParameters;
{
  if (self = [self init]) 
  {
    method = theMethod;
    url = theUrl;
    [url retain];
    parameters = theParameters;
    [parameters retain];
    fileNames =     [[NSMutableArray alloc] init];
    fileMimeTypes = [[NSMutableArray alloc] init];
    fileContents =  [[NSMutableArray alloc] init];
  }
  return self;
}

+ (NSString *)generateUUID
{
	CFUUIDRef theUUID = CFUUIDCreate(NULL);
	CFStringRef string = CFUUIDCreateString(NULL, theUUID);
	CFRelease(theUUID);
	return [(NSString *)string autorelease];
}

- (void)addFile:(NSData *)data paramName:(NSString *)paramName contentType:(NSString *)contentType fileName:(NSString *)fileName;
{
  if (data != nil) {
    [fileParams addObject:paramName];
    [fileNames addObject: fileName == nil ? [URLRequestBuilder generateUUID] : fileName];
    [fileMimeTypes addObject: contentType == nil ? @"application/octet-stream" : contentType];
    [fileContents addObject:data];
  }  
}

- (NSURLRequest *)initRequest
{
  if (method == RequestMethodGet) 
  {
    return [self initGetRequest];
  }
  else 
  {
    return [self initPostRequest];
  }
}

- (void)dealloc
{
  [url release];
  [parameters release];
  [fileNames release];
  [fileMimeTypes release];
  [fileContents release];
  [super dealloc];
}

#pragma mark Provate Methods
- (NSURLRequest *)initGetRequest
{  
  NSLog(@"initGetRequest");
  return [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:[URLRequestBuilder url:url withParameters:parameters]]
                               cachePolicy:NSURLRequestUseProtocolCachePolicy
                           timeoutInterval:60.0];
}

- (NSURLRequest *)initPostRequest
{
  NSMutableURLRequest *theRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]
                                                                 cachePolicy:NSURLRequestUseProtocolCachePolicy 
                                                             timeoutInterval:60];
  [theRequest setHTTPMethod:@"POST"];
  
  NSString *boundary = [URLRequestBuilder generateUUID];
  NSString *contentType = [NSString stringWithFormat:@"multipart/form-data, boundary=%@", boundary];
  [theRequest setValue:contentType forHTTPHeaderField:@"Content-type"];
  
  NSMutableData *postBody =[[NSMutableData alloc] init];
  for (NSString * key in [parameters allKeys])
  {
    [postBody appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"%@\r\n", [parameters objectForKey:key]] dataUsingEncoding:NSUTF8StringEncoding]];
  }
  
  for (NSInteger i = 0; i<[fileNames count]; i++)
  {
    [postBody appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", [fileParams objectAtIndex:i], [fileNames objectAtIndex:i]] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n\r\n", [fileMimeTypes objectAtIndex:i]] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[fileContents objectAtIndex:i]];
    [postBody appendData:                           [@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
  }
    
  [postBody appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]]; // last line with -- after boundary
  
  [theRequest setHTTPBody:postBody];
  
  [postBody release];
  return theRequest;
}

+ (NSString *)urlEncode :(NSString *)unencodedString
{
  NSString * encodedString = (NSString *)CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                                 (CFStringRef)unencodedString,
                                                                                 NULL,
                                                                                 (CFStringRef)@"!*'\"();:@&=+$,/?%#[]% ",
                                                                                 kCFStringEncodingUTF8 );
  return [encodedString autorelease];
}

+ (NSString *)url:(NSString *)urlString withParameters:(NSDictionary *)dict
{
  NSLog(@"url:withParameters");
 
  NSMutableArray * keysWithValues = [[NSMutableArray alloc] init];
  for (NSString * key in [dict allKeys])
  {
    [keysWithValues addObject:[NSString stringWithFormat:@"%@=%@", key, [URLRequestBuilder urlEncode:[dict valueForKey:key]]]];
  }
  NSString * paramsString = [keysWithValues componentsJoinedByString:@"&"];
  [keysWithValues release];
  [dict release];
  
  if (paramsString == nil) 
  {
    return urlString;
  }
  else 
  {
    return [NSString stringWithFormat:@"%@?%@", urlString, paramsString];
  }
}

@end
