//
//  ViewController.swift
//  SVGParser
//
//  Created by AndreyMomot on 10/31/2018.
//  Copyright (c) 2018 AndreyMomot. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    
    @IBAction func parseButtonAction(_ sender: Any) {
        
        // Load SVG from local path as Data
        
        if let path = Bundle.main.path(forResource: "swift_logo", ofType: "svg") {
            if let nsData = NSData(contentsOfFile: path) {
                parseSVG(nsData as Data) { image in
                    self.imageView.image = image
                }
            }
        }
        
        // Load SVG from local path
        
        //        if let path = Bundle.main.path(forResource: "pin", ofType: "svg") {
        //            parseSVG(path) { image in
        //                self.imageView.image = image
        //            }
        //        }
        
        // Load SVG from remote URL

        //        if let url = URL(string: "https://upload.wikimedia.org/wikipedia/commons/9/9d/Swift_logo.svg") {
        //            parseSVG(url) { image in
        //                self.imageView.image = image
        //            }
        //        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func parseSVG(_ data: Data, completionHandler: @escaping (UIImage) -> Void) {
        
        DispatchQueue.main.async {
            SVGParser(xmlData: data).scaledImageWithSize(CGSize(width: 300, height: 300), completion: { image in
                if let img = image {
                    completionHandler(img)
                }
            })
        }
    }
    
    func parseSVG(_ path: String, completionHandler: @escaping (UIImage) -> Void) {
        
        DispatchQueue.main.async {
            SVGParser(contentsOfFile: path).scaledImageWithSize(CGSize(width: 300, height: 300), completion: { image in
                if let img = image {
                    completionHandler(img)
                }
            })
        }
    }
    
    func parseSVG(_ url: URL, completionHandler: @escaping (UIImage) -> Void) {
        
        DispatchQueue.main.async {
            SVGParser(contentsOfURL: url).scaledImageWithSize(CGSize(width: 300, height: 300), completion: { image in
                if let img = image {
                    completionHandler(img)
                }
            })
        }
    }

}

