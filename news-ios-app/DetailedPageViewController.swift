//
//  DetailedPageViewController.swift
//  hw9-private
//
//  Created by Kathleen Xue on 4/24/20.
//  Copyright © 2020 Kathleen Xue. All rights reserved.
//

import Foundation
import UIKit
import os.log
import SwiftyJSON
import CoreLocation
import MapKit
import Kingfisher
import SwiftSpinner
import Toast_Swift

protocol DetailedPageDelegate {
    func toggleBookmark(id: String)
}

class DetailedPageViewController: UIViewController {
    
    @IBOutlet weak var twitterButton: UIBarButtonItem!
    @IBOutlet weak var bookmarkButton: UIBarButtonItem!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var detailedPageImg: UIImageView!
    @IBOutlet weak var detailedPageSection: UILabel!
    @IBOutlet weak var detailedPageDate: UILabel!
    @IBOutlet weak var detailedPageBody: UILabel!
    @IBOutlet weak var detailedPageTitle: UILabel!
    @IBOutlet weak var detailedPageUrl: UIButton!
    @IBOutlet weak var detailedPageBackButton: UINavigationItem!
    var thumbnailData: String? //article id
    var image: String = "https://assets.guim.co.uk/images/eada8aa27c12fe2d5afa3a89d3fbae0d/fallback-logo.png"
    var newsTitle: String = ""
    var section: String = ""
    var date: String = ""
    var bodyText: String = ""
    var url: String = "https://theguardian.com"
    let formatter = Formatter()
    var defaults = UserDefaults.standard
    var bookmarkArray = [String]()
    var id = ""
    let bookmarkTrue = UIImage(systemName: "bookmark.fill")
    let bookmarkFalse = UIImage(systemName: "bookmark")
    var isBookmarked = false
    var parentIsBookmarked = false
    var delegate: DetailedPageDelegate?
    
    @IBAction func didTapUrl(sender: AnyObject) {
        if let url = URL(string: self.url) {
            UIApplication.shared.open(url)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        id = thumbnailData ?? ""
        self.view.translatesAutoresizingMaskIntoConstraints = true
        bookmarkArray = defaults.object(forKey: "bookmarkArray") as? [String] ?? [String]()
        if bookmarkArray.firstIndex(of: id) != nil {
            self.bookmarkButton.image = self.bookmarkTrue
            self.isBookmarked = true
        } else {
            self.bookmarkButton.image = self.bookmarkFalse
            self.isBookmarked = false
        }
        self.twitterButton.target = self
        self.twitterButton.action = #selector(didTapTwitter(_:))
        self.bookmarkButton.target = self;
        self.bookmarkButton.action = #selector(bookmarkButtonTapped(_:));
        if self.isBookmarked != self.parentIsBookmarked {
            self.delegate?.toggleBookmark(id: self.thumbnailData ?? "")
        }
    }

    
    @IBAction func didTapTwitter(_ sender: Any) {
        UIApplication.shared.openURL(NSURL(string: "https://twitter.com/intent/tweet?text=Check%20out%20this%20article!&hashtags=CSCI571&url=\(self.url)")! as URL)
    }
    
    /*override func viewDidLayoutSubviews() {
        self.scrollView.isScrollEnabled = true
        self.scrollView.contentSize = CGSize(width: 414, height: 1700) // height should be grater than scrollview's frame height
    }*/
    
    @objc func bookmarkButtonTapped(_ sender: UIButton){
        let bkArr = self.defaults.object(forKey: "bookmarkArray") as? [String] ?? [String]()
        if bkArr.firstIndex(of: self.id) != nil {
            self.isBookmarked = false
            self.bookmarkButton.image = self.bookmarkFalse
            self.bookmarkArray = self.bookmarkArray.filter{$0 != self.id}
            self.view.makeToast("Article removed from Bookmarks")
        } else {
            self.isBookmarked = true
            self.bookmarkButton.image = self.bookmarkTrue
            self.bookmarkArray.append(self.id)
            self.view.makeToast("Article bookmarked. Check out the Bookmarks tab to view")
        }
        self.defaults.set(self.bookmarkArray, forKey: "bookmarkArray")
        self.delegate?.toggleBookmark(id: self.id)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        SwiftSpinner.show("Loading Detailed Article...")
        self.defaults = UserDefaults.standard
        self.bookmarkArray = UserDefaults.standard.object(forKey: "bookmarkArray") as? [String] ?? [String]()
        
        if let thumbnailData = thumbnailData {
            if (self.bookmarkArray.firstIndex(of: thumbnailData) != nil) {
                self.isBookmarked = true
                self.bookmarkButton.image = self.bookmarkTrue
            } else {
                self.isBookmarked = false
                self.bookmarkButton.image = self.bookmarkFalse
            }
            let getter = DetailedNewsGetter()
            getter.getDetailedNews(id: thumbnailData, completion: {(data) -> Void in
                let jsonData = JSON(data)
                self.image = jsonData["image"].string ??  "https://assets.guim.co.uk/images/eada8aa27c12fe2d5afa3a89d3fbae0d/fallback-logo.png"
               //print(self.image)
                self.newsTitle = data["title"] ?? "None"
                self.section = data["section"] ?? "None"
                self.date = data["date"] ?? "None"
                self.bodyText = data["bodyText"] ?? "None"
                self.url = data["url"] ?? "https://theguardian.com"
                let imgurl = URL(string: self.image) ?? URL(string: "https://assets.guim.co.uk/images/eada8aa27c12fe2d5afa3a89d3fbae0d/fallback-logo.png")
               let defaultImage = UIImage(named: "big-default-guardian")
                self.detailedPageImg.kf.setImage(with: imgurl, placeholder: defaultImage)
                self.detailedPageTitle.text = self.newsTitle
                self.detailedPageUrl.addTarget(self, action: #selector(self.didTapUrl(sender:)), for: .touchUpInside)
                let bodyHtml = self.bodyText.htmlAttributedString()
                bodyHtml?.enumerateAttribute(.font, in: NSMakeRange(0, bodyHtml!.length), options: []) { value, range, stop in
                    guard let currentFont = value as? UIFont else {
                        return
                    }
                    let fontDescriptor = currentFont.fontDescriptor.addingAttributes([.family: "Helvetica"])
                    if let newFontDescriptor = fontDescriptor.matchingFontDescriptors(withMandatoryKeys: [.family]).first {
                        let newFont = UIFont(descriptor: newFontDescriptor, size: currentFont.pointSize)
                        bodyHtml!.addAttributes([.font: newFont], range: range)
                    }
                }
                self.detailedPageBody.attributedText = bodyHtml
                self.detailedPageDate.text = self.formatter.formatTraditionalDate(date: self.date)
                self.detailedPageSection.text = self.section
                self.navigationController?.navigationBar.topItem?.title = self.newsTitle
                SwiftSpinner.hide()
            })
        }
    }
}

extension String {
    func htmlAttributedString() -> NSMutableAttributedString? {
        guard let data = self.data(using: String.Encoding.utf16, allowLossyConversion: false) else { return nil }
        guard let html = try? NSMutableAttributedString(
            data: data,
            options: [NSMutableAttributedString.DocumentReadingOptionKey.documentType: NSMutableAttributedString.DocumentType.html],
            documentAttributes: nil) else { return nil }
        return html
    }
}
