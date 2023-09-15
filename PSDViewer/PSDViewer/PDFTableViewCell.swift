//
//  PDFTableViewCell.swift
//  PSDViewer
//
//  Created by Momin Khan on 04/09/2023.
//

import UIKit

class PDFTableViewCell: UITableViewCell {

    
    var bookMarkTap: (() -> ())?
    
    @IBOutlet weak var bookMarkBtnOutlet: UIButton!
    
    @IBOutlet weak var shadowView: UIView!
    
    @IBOutlet weak var pdfImageView: UIImageView!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        super.layoutSubviews()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    override func layoutSubviews() {
        super.layoutSubviews()
                let margins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        contentView.frame = contentView.frame.inset(by: margins)
    }

    
   
    @IBAction func bookmarkbuttonAction(_ sender: Any) {
        bookMarkTap?()
    }
    
}
