//
//  SSConfig.swift
//  Pods
//
//  Created by LawLincoln on 15/7/10.
//
//

import Foundation

let SSPHOTO_LOADING_DID_END_NOTIFICATION = "SSPHOTO_LOADING_DID_END_NOTIFICATION"
let PADDING: CGFloat = 10
let PAGE_INDEX_TAG_OFFSET = 1000
public typealias SSProgressUpdateBlock = (CGFloat)->()

func PAGE_INDEX(page: SSZoomingScrollView)->Int {
    let index = page.tag - PAGE_INDEX_TAG_OFFSET
    return index
}
func SYSTEM_VERSION_EQUAL_TO(to:String) -> Bool{
    let ver = UIDevice.current.systemVersion
    return ver.compare(to, options: String.CompareOptions.numeric, range: nil, locale: nil) == ComparisonResult.orderedSame
}

func SYSTEM_VERSION_GREATER_THAN(to:String) -> Bool{
    let ver = UIDevice.current.systemVersion
    return ver.compare(to, options: String.CompareOptions.numeric, range: nil, locale: nil) == ComparisonResult.orderedSame
}

func SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(to:String) -> Bool{
    let ver = UIDevice.current.systemVersion
    return ver.compare(to, options: String.CompareOptions.numeric, range: nil, locale: nil) == ComparisonResult.orderedSame
}

func SYSTEM_VERSION_LESS_THAN(to:String) -> Bool{
    let ver = UIDevice.current.systemVersion
    return ver.compare(to, options: String.CompareOptions.numeric, range: nil, locale: nil) == ComparisonResult.orderedSame
}

func SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(to:String) -> Bool{
    let ver = UIDevice.current.systemVersion
    return ver.compare(to, options: String.CompareOptions.numeric, range: nil, locale: nil) == ComparisonResult.orderedSame
}

func SSPhotoBrowserLocalizedStrings(key: String) -> String{
    if let path = Bundle(for: SSImageBrowser.self).path(forResource: "IDMPBLocalizations", ofType: "bundle") {
        if let bundle = Bundle(path: path) {
            return NSLocalizedString(key, bundle: bundle, comment: key)
        }
        
    }
    return key
}
