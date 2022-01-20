//
//  HTTPRequest.swift
//  HPrint
//
//  Created by WuYB on 2019/4/9.
//  Copyright © 2019 hanin. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import BaseKitSwift
import MobileCoreServices

fileprivate var FrameworkBundle: Bundle = {
    
    return Bundle.init(for: MIMEHelper.self)
}()

fileprivate extension String {
    
    var hr_localized: String {
        
        localized(FrameworkBundle)
    }
}

public class MIMEHelper {
    
    public static func mimeType(forPathExtension pathExtension: String) -> String {
        if
            let id = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension as CFString, nil)?.takeRetainedValue(),
            let contentType = UTTypeCopyPreferredTagWithClass(id, kUTTagClassMIMEType)?.takeRetainedValue()
        {
            return contentType as String
        }
        
        return "application/octet-stream"
    }
}

public struct HTTPRequest {
    
    public static let `default` = HTTPRequest()
    
    public init(adaptHandler: @escaping (Options, Any?) -> (options: Options, params: Any?) = { ($0, $1) }) {
        self.adaptHandler = adaptHandler
    }
    
    public let adaptHandler: (Options, Any?) -> (options: Options, params: Any?)
    
    public static var showActivityClosure: (() -> Void)?
    public static var showErrorClosure: ((String) -> Void)?
    public static var dismissToastClosure: (() -> Void)?
    public static var logEnabled = false
    
    public enum ResponseError: Error, CustomStringConvertible {
        case emptyBody
        case empty
        case bodyNotJson(data: Data)
        case statusCode(code: Int)
        case network(Error)
        case multipartEncode(Error)
        
        public var description: String {
            
            switch self {
            case .emptyBody:
                return "服务器错误，无响应数据，请联系客服".hr_localized
            case .empty:
                return "服务器错误，无响应，请联系客服".hr_localized
            case .bodyNotJson(data: _):
                return "服务器错误，响应数据格式错误(NOT JSON)，请联系客服".hr_localized
            case .statusCode(code: let code):
                return String.init(format: "服务器错误，响应状态码-%i，%@".hr_localized, code, HTTPURLResponse.localizedString(forStatusCode: code))
            case .network(let error):
                let error = (error as NSError)
                //NSURLErrorDataNotAllowed 蜂窝数据不可用，不清楚是关闭还是无权限,经测试关闭必定出现
                switch error.domain {
                case NSURLErrorDomain:
                    switch error.code {
                    case NSURLErrorTimedOut:
                        return "网络请求超时，请稍后重试".hr_localized
                    case NSURLErrorNotConnectedToInternet:
                        return "您的iPhone尚未接入互联网，请检查手机网络".hr_localized
                    case NSURLErrorNetworkConnectionLost:
                        return "网络请求失败，连接丢失，请稍后重试".hr_localized
                    case NSURLErrorCannotFindHost:
                        return "网络请求失败，域名解析失败".hr_localized
                    case NSURLErrorCannotConnectToHost:
                        //域名解析正常，但主机故障或不接受特定端口上的连接
                        return "网络请求失败，服务器连接失败，请稍后重试".hr_localized
                    default:
                        break
                    }
                case NSPOSIXErrorDomain:
                    switch error.code {
                    case 50:
                        return String.init(format: "网络请求失败，请允许\"%@\"使用无线数据".hr_localized, AppInfo.displayName)
                    default:
                        break
                    }
                default:
                    break
                }
                let desc = String.init(format: "%@-%i", error.domain, error.code)
                return String.init(format: "网络请求失败，请检查手机网络\n%@".hr_localized, desc)
            case .multipartEncode:
                return "Multipart Form Data编码错误".hr_localized
            }
        }
    }
    
    public static func defaultHandleRequestError(_ error: ResponseError, needNetworkAlert: Bool = false) {
        
        guard needNetworkAlert else {
            showErrorClosure?(error.description)
            return
        }
        switch error {
        case .network(let temp):
            let error = (temp as NSError)
            //NSURLErrorDataNotAllowed 蜂窝数据不可用，不清楚是关闭还是无权限,经测试关闭必定出现
            switch error.domain {
            case NSURLErrorDomain:
                switch error.code {
                case NSURLErrorNotConnectedToInternet:
                    let desc = String.init(format: "%@-%i", error.domain, error.code)
                    KeyWindow?.rootViewController?.bk_presentWarningAlertController(title: "提示".hr_localized, message: desc)
                    return
                default:
                    break
                }
            case NSPOSIXErrorDomain:
                switch error.code {
                case 50:
                    let desc = String.init(format: "%@-%i", error.domain, error.code)
                    KeyWindow?.rootViewController?.bk_presentWarningAlertController(title: "提示".hr_localized, message: desc)
                    return
                default:
                    break
                }
            default:
                break
            }
        default:
            break
        }
        showErrorClosure?(error.description)
    }
    
    public static func jsonResponseResolve(response: AFDataResponse<Data?>, completeClosure: (Swift.Result<JSON, ResponseError>) -> Void) -> Void {
        
        if let httpResponse = response.response {
            if httpResponse.statusCode == 200 {
                if let data = response.data {
                    if let json = try? JSON.init(data: data) {
                        completeClosure(.success(json))
                    }else {
                        completeClosure(.failure(ResponseError.bodyNotJson(data: data)))
                    }
                }else {
                    completeClosure(.failure(ResponseError.emptyBody))
                }
            }else {
                completeClosure(.failure(ResponseError.statusCode(code: httpResponse.statusCode)))
            }
        }else {
            if let error = response.error {
                completeClosure(.failure(ResponseError.network(error)))
            }else {
                completeClosure(.failure(ResponseError.empty))
            }
        }
    }
    
    public struct Options {
        
        public var activityVisible: Bool
        public var timeout: TimeInterval
        public var encoding: ParameterEncoding
        public var httpHeaders: HTTPHeaders = ["Platform": "iOS", "Version": AppInfo.version]
        
        public init(activityVisible: Bool = true, timeout: TimeInterval = 30, encoding: ParameterEncoding = URLEncoding.default) {
            self.activityVisible = activityVisible
            self.timeout = timeout
            self.encoding = encoding
            httpHeaders["Language"] =  Bundle.main.preferredLocalizations.first ?? "en"
        }
        
        public static var `default` : Options { return Options() }
        
        public static var silence : Options { Options.init(activityVisible: false) }
    }
    
    @discardableResult
    public func dataRequest(_ url: URLConvertible,
                        method: HTTPMethod,
                        options: Options = Options.default,
                        parameters: Any?,
                        completeClosure: @escaping (Swift.Result<Data, ResponseError>) -> Void
    ) -> DataRequest {
        
        if options.activityVisible {
            HTTPRequest.showActivityClosure?()
        }
        var request = try! URLRequest(url: url, method: method, headers: nil)
        let items = adaptHandler(options, parameters)
        if items.params == nil {
            request = try! items.options.encoding.encode(request, with: nil)
        }else if let params = items.params as? Parameters {
            request = try! items.options.encoding.encode(request, with: params)
        }else {
            if let encoding = items.options.encoding as? JSONEncoding {
                request = try! encoding.encode(request, withJSONObject: items.params)
            }else {
                fatalError("parameters not dictionary can't encode")
            }
        }
        
        request.timeoutInterval = items.options.timeout
        items.options.httpHeaders.forEach({ request.addValue($0.value, forHTTPHeaderField: $0.name) })
        
        if HTTPRequest.logEnabled {
            var description = "#   #   #   #   #   #   #   #   #   #\n"
            description += "Request\n\n"
            description += "URL: "
            description += try! url.asURL().description
            description += "\n\n"
            if let headers = request.allHTTPHeaderFields {
                description += "Header:\n\n"
                description += headers.map({ String.init(format: "%@ : %@", $0.key, $0.value) }).joined(separator: "\n")
                description += "\n\n"
            }
            
            if let body = request.httpBody {
                description += "Body:\n\n"
                description += String.init(data: body, encoding: .utf8)!
            }
            description += "#   #   #   #   #   #   #   #   #   #\n"
            print(description)
        }
        
        let dataRequest = Session.default.request(request)
        dataRequest.response(completionHandler: {
            if options.activityVisible {
                HTTPRequest.dismissToastClosure?()
            }
            if let httpResponse = $0.response {
                if httpResponse.statusCode == 200 {
                    if let data = $0.data {
                        completeClosure(.success(data))
                    }else {
                        completeClosure(.failure(ResponseError.emptyBody))
                    }
                }else {
                    completeClosure(.failure(ResponseError.statusCode(code: httpResponse.statusCode)))
                }
            }else {
                if let error = $0.error {
                    completeClosure(.failure(ResponseError.network(error)))
                }else {
                    completeClosure(.failure(ResponseError.empty))
                }
            }
        })
        return dataRequest
    }
    
    @discardableResult
    public func request(_ url: URLConvertible,
                        method: HTTPMethod,
                        options: Options = Options.default,
                        parameters: Parameters?,
                        completeClosure: @escaping (Swift.Result<JSON, ResponseError>) -> Void
    ) -> DataRequest {
        
        return dataRequest(url, method: method, options: options, parameters: parameters, completeClosure: {
            switch $0 {
            case .success(let data):
                if let json = try? JSON.init(data: data) {
                    completeClosure(.success(json))
                }else {
                    completeClosure(.failure(ResponseError.bodyNotJson(data: data)))
                }
            case .failure(let error):
                completeClosure(.failure(error))
            }
        })
    }
    
    @discardableResult
    public static func uploadMultipartFormData(
        url: URLConvertible, 
        options: Options = Options.default,
        parameters: Parameters? = nil,
        multipartFormData: @escaping (MultipartFormData) -> Void,
        progressClosure: ((Progress) -> Void)?,
        completeClosure: @escaping (Swift.Result<JSON, ResponseError>) -> Void
    ) -> UploadRequest {
        
        var request = try! URLRequest(url: url, method: .post, headers: options.httpHeaders)
        request.timeoutInterval = options.timeout
        
        let closure: (MultipartFormData) -> Void = {
            if let temp = parameters {
                var components = [(String, String)]()
                for (key, value) in temp {
                    components += URLEncoding.default.queryComponents(fromKey: key, value: value)
                }
                for (key, value) in components.map({ ($0.0, $0.1.data(using: .utf8)!) }) {
                    $0.append(value, withName: key)
                }
            }
            multipartFormData($0)
        }
        
        let uploadRequest = Session.default.upload(multipartFormData: closure, with: request)
        if let progressClosure = progressClosure {
            uploadRequest.uploadProgress(closure: progressClosure)
        }
        uploadRequest.response(completionHandler: {
            self.jsonResponseResolve(response: $0, completeClosure: {
                completeClosure($0)
            })
        })
        return uploadRequest
    }
    
    @discardableResult
    public static func download(
        url: URLConvertible, 
        headers: HTTPHeaders? = nil,
        destinationUrl: @escaping ((HTTPURLResponse) -> URL), 
        completeHandle: @escaping ((AFDownloadResponse<Data>) -> Void),
        progressHandle: ((Progress) -> Void)? = nil
    ) -> DownloadRequest {
        
        let request = Session.default.download(url, method: .get, parameters: nil, encoding: URLEncoding.default, headers: headers, to:  {
            let url = try! destinationUrl($1).asURL()
            return (url, [.createIntermediateDirectories, .removePreviousFile])
        })
        if let temp = progressHandle {
            request.downloadProgress(closure: temp)
        }
        request.responseData(completionHandler: completeHandle)
        return request
    }
}
