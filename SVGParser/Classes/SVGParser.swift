//
//  SVGParser.swift
//  SVGParser
//
//  Created by Andrii Momot on 10/31/18.
//

import UIKit
import JavaScriptCore


public class SVGWebView: UIWebView {
    
    deinit {
        // Ref: http://www.codercowboy.com/code-uiwebview-memory-leak-prevention/
        stringByEvaluatingJavaScript(from: "document.body.innerHTML='';")
        loadHTMLString("", baseURL: nil)
        stopLoading()
        delegate = nil
        removeFromSuperview()
    }
}

public class SVGParser: NSObject {
    
    public init(xmlData: Data) {
        super.init()
        initializeWith(data: xmlData)
    }
    
    public init(contentsOfFile: String) {
        super.init()
        if let data = NSData(contentsOfFile: contentsOfFile) {
            initializeWith(data: data as Data)
        }
    }
    
    public init(contentsOfURL: URL) {
        super.init()
        do {
            let data = try Data(contentsOf: contentsOfURL)
            initializeWith(data: data)
        } catch {
            print("Unable to load data: \(error)")
        }
    }
    
    fileprivate func initializeWith(data: Data) {
        
        contentData = data
        scale = 1.0
    }
    
    static var cache: NSCache<NSData, UIImage> = NSCache<NSData, UIImage>()
    var contentData: Data?
    var scale: CGFloat?
    var size: CGSize?
    
    public func scaledImageWithSize(_ size: CGSize, completion: @escaping (UIImage?) -> Void) {
        
        SVGParser.cache.countLimit = 100
        guard let data = contentData else { return }
        if let img = SVGParser.cache.object(forKey: data as NSData) {
            completion(img)
            return
        }
        
        uiImage(size: size) { image in
            SVGParser.cache.setObject(image, forKey: data as NSData)
            completion(image)
        }
    }
    
    fileprivate func uiImage(size: CGSize, completion: @escaping (UIImage) -> Void) {
        
        uiWebViewWithImageDrawnInSize(size, originalImageSize: nil) { (webView, svgSize) in
            DispatchQueue.main.async {
                UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
                if let currentContext = UIGraphicsGetCurrentContext() {
                    webView.layer.render(in: currentContext)
                }
                if let image = UIGraphicsGetImageFromCurrentImageContext() {
                    UIGraphicsEndImageContext()
                    completion(image)
                }
            }
        }
    }
    
    fileprivate func uiWebViewWithImageDrawnInSize(_ size: CGSize, originalImageSize: CGSize?, completion: @escaping (UIWebView, CGSize) -> Void) {
        
        assert(Thread.isMainThread, "This method should be called only on main thread")
        
        // Create WebView
        let webView = SVGWebView(frame: CGRect(origin: CGPoint.zero, size: size))
        webView.isOpaque = false
        webView.backgroundColor = UIColor.clear
        
        // Load HTML
        guard let xmlData = contentData else { return }
        let srcString = "data:image/svg+xml;charset=utf-8;base64,\(xmlData.base64EncodedString(options: []))"
        
        let htmlString = String(format: """
    <!DOCTYPE html><html>
    <head><meta name=\"viewport\" content=\"width=%.3lf, user-scalable=no\"></head>
    <body style="padding:0;margin:0;background:transparent;">
    <img src="%@" onload="loaded()" width="%.3lf" height="%.3lf"></body></html>
    """, size.width, srcString, size.width, size.height)
        
        webView.loadHTMLString(htmlString, baseURL: nil)
        
        // Add JS Method
        if let jsContext = webView.value(forKeyPath: "documentView.webView.mainFrame.javaScriptContext") as? JSContext {
            let loaded: @convention(block) () -> Void = {
                
                let imageElement = jsContext.globalObject.objectForKeyedSubscript("document")?.objectForKeyedSubscript("images")?.objectAtIndexedSubscript(0)
                let width = imageElement?.objectForKeyedSubscript("naturalWidth")?.toDouble()
                let height = imageElement?.objectForKeyedSubscript("naturalHeight")?.toDouble()
                completion(webView, CGSize(width: width ?? Double(size.width), height: height ?? Double(size.height)))
            }
            
            jsContext.setObject(loaded, forKeyedSubscript: "loaded" as NSCopying & NSObjectProtocol)
            jsContext.evaluateScript("loaded")
        }
    }
}
