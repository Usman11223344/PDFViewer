//
//  PreviewPDFViewController.swift
//  PSDViewer
//
//  Created by Momin Khan on 04/09/2023.
//

import UIKit
import PDFKit

enum DragViewPosition {
    case upperSideFirst
    case upperSideSecond
    //    case upperSideThird
    //    case upperSideFourth
    case centerFirst
    case centerSecond
    //    case centerThird
    //    case centerFourth
    case lowerSideFirst
    case lowerSideSecond
    //    case lowerSideFourth
}

class PreviewPDFViewController: UIViewController {
    
    @IBOutlet weak var dragColorView: UIView!
    @IBOutlet weak var viewDrag: UIView!
    
    @IBOutlet weak var pdfTableView: UITableView!{
        didSet{
            self.pdfTableView.register(UINib(nibName: "PDFTableViewCell", bundle: .main), forCellReuseIdentifier: "PDFTableViewCell")
            pdfTableView.rowHeight = UITableView.automaticDimension
            self.pdfTableView.delegate = self
            self.pdfTableView.dataSource = self
        }
    }
    // MARK: - Outlets
    
    @IBOutlet weak var pdfView: PDFView!
    
    
    // MARK: - Properties
    
    
    var pdfUrl = URL(string: "")
    var pdfDocument = PDFDocument()
    var imagesArray = [UIImage]()
    var panGesture = UIPanGestureRecognizer()
    var currentPageNumber = 0
    var selectedIndex = IndexPath()
    //    var stoppedDragViewIndex = IndexPath()
    var stoppedDragViewIndex = IndexPath(row: 0, section: 0)
    var lastIndex = IndexPath(row: 0, section: 0)
    var viewDragged = false
    var stoppedIndexes = [IndexPath]()
    var previousStoppedDragViewIndex = IndexPath(row: 0, section: 0)
    var dragViewCenterYInView = CGFloat()
    var halfVisibleCellHeight : Int?
    var rectangles: [CGRect] = []
   
    
    
    // MARK: - LifeCycle
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupPDF()
    }
    
    
    // MARK: - Functions
    func setupPDF(){
        displayPDF(url: pdfUrl ?? URL(fileURLWithPath: ""))
        self.imagesArray = convertPDFToImages(pdfURL: (self.pdfUrl ?? URL(string: ""))!) ?? []
        print(imagesArray.count)
        dragColorView.layer.borderColor = UIColor.systemBlue.cgColor
        dragColorView.layer.borderWidth = 2
        dragColorView.layer.cornerRadius = 8
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(PreviewPDFViewController.draggedView(_:)))
        viewDrag.isUserInteractionEnabled = true
        viewDrag.addGestureRecognizer(panGesture)
        currentPageNumber = 0
        panGesture.delegate = self
        print(pdfView.frame.height)
        
    }
    
    func displayPDF(url: URL) {
        guard let pdfDocument = PDFDocument(url: url) else {
            print("Failed to load the PDF document.")
            return
        }
        pdfView.displaysPageBreaks = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.minScaleFactor = 1
        pdfView.autoScales = true
        self.pdfDocument = pdfDocument
        pdfView.document = pdfDocument
        pdfView.autoScales = true
        UIScrollView.appearance().showsVerticalScrollIndicator = false
        UIScrollView.appearance().showsHorizontalScrollIndicator = false
    }
    func convertPDFToImages(pdfURL: URL) -> [UIImage]? {
        guard let pdfDocument = PDFDocument(url: pdfURL) else {
            return nil
        }
        var images: [UIImage] = []
        for pageNum in 0..<pdfDocument.pageCount {
            if let pdfPage = pdfDocument.page(at: pageNum) {
                let pdfPageSize = pdfPage.bounds(for: .mediaBox)
                let renderer = UIGraphicsImageRenderer(size: pdfPageSize.size)
                let image = renderer.image { ctx in
                    UIColor.white.set()
                    ctx.fill(pdfPageSize)
                    ctx.cgContext.translateBy(x: 0.0, y: pdfPageSize.size.height)
                    ctx.cgContext.scaleBy(x: 1.0, y: -1.0)
                    pdfPage.draw(with: .mediaBox, to: ctx.cgContext)
                }
                images.append(image)
            }
        }
        return images
    }
    
    @objc func draggedView(_ sender: UIPanGestureRecognizer) {
        self.view.bringSubviewToFront(viewDrag)
        if let currentCell = pdfTableView.cellForRow(at: stoppedDragViewIndex) {
            let dragViewCenterInCell = self.view.convert(viewDrag.center, to: currentCell.contentView)
            
            
            dragViewCenterYInView = dragViewCenterInCell.y
        }
        switch sender.state {
        case .began:
            calculateRectanglesForPDFPage()
            if let currentCell = pdfTableView.cellForRow(at: stoppedDragViewIndex) {
                dragViewCenterYInView = currentCell.convert(viewDrag.center, from: currentCell.contentView).y
            }
            break
        case .changed:
            let translation = sender.translation(in: self.view)
            let newY = viewDrag.center.y + translation.y
            let minY = pdfTableView.frame.minY + viewDrag.bounds.height / 2
            let maxY = pdfTableView.frame.maxY - viewDrag.bounds.height / 2
            let newCenterY = max(minY, min(maxY, newY))
            viewDrag.center = CGPoint(x: viewDrag.center.x, y: newCenterY)
            let yOffset = pdfTableView.contentOffset.y
            let newPageY = newY - pdfTableView.frame.origin.y + yOffset
            if let newPage = pdfTableView.indexPathForRow(at: CGPoint(x: 0, y: newPageY)) {
                if newPage != stoppedDragViewIndex {
                    stoppedDragViewIndex = newPage
                    if let page = self.pdfView.document?.page(at: stoppedDragViewIndex.row) {
                        pdfView.go(to: page)
                    }
                    pdfTableView.scrollToRow(at: newPage, at: .middle, animated: true)
                }
            }
            // Calculate dragViewCenterYInView here based on the current cell
            if let currentCell = pdfTableView.cellForRow(at: stoppedDragViewIndex) {
                let dragViewCenterInCell = self.view.convert(viewDrag.center, to: currentCell.contentView)
                dragViewCenterYInView = dragViewCenterInCell.y
            }
            
            checkDragViewPositionInAllCells()
            if stoppedDragViewIndex != previousStoppedDragViewIndex {
                previousStoppedDragViewIndex = stoppedDragViewIndex
            }
            sender.setTranslation(CGPoint.zero, in: self.view)
        case .ended, .cancelled:
            break
        default:
            break
        }
    }
    func calculateRectanglesForPDFPage() {
        guard let page = pdfView.currentPage else { return }
        let pageBounds = page.bounds(for: .mediaBox)
        let pageHeight = pageBounds.size.height
        let numberOfParts = 6
        let partHeight = pageHeight / CGFloat(numberOfParts)
        
        rectangles.removeAll() // Clear the existing rectangles
        
        for i in 0..<numberOfParts {
            let yOrigin = CGFloat(i) * partHeight
            let rect = CGRect(x: 0, y: yOrigin, width: pageBounds.size.width, height: partHeight)
            rectangles.append(rect)
        }
    }
    func checkDragViewPositionInAllCells() {
        guard let cell = pdfTableView.cellForRow(at: stoppedDragViewIndex)else{return}
        guard let indexPath = pdfTableView.indexPath(for: cell) else {
            return
        }
        let position = calculateDragViewPositionInCurrentCell(viewDrag)
        switch position {
        case .upperSideFirst:
         if let page = self.pdfView.document?.page(at: stoppedDragViewIndex.row) {
             if imagesArray.count > 7 {
                 if stoppedDragViewIndex.row == 1 || stoppedDragViewIndex.row == 2 || stoppedDragViewIndex.row == 3{
                     pdfView.go(to: rectangles[0], on: page)
                 }
                 else{
                     pdfView.go(to: rectangles[4], on: page)
                 }
             }
             else {
                 pdfView.go(to: rectangles[4], on: page)
             }
           
        }
            print("Drag view in the upperSideFirst of cell at indexPath: \(indexPath)")
            break
        case .upperSideSecond:
            if let page = self.pdfView.document?.page(at: stoppedDragViewIndex.row) {
                if imagesArray.count > 7 {
                    if stoppedDragViewIndex.row == 1 || stoppedDragViewIndex.row == 2 || stoppedDragViewIndex.row == 3{
                        pdfView.go(to: rectangles[1], on: page)
                    }
                    else {
                        pdfView.go(to: rectangles[4], on: page)
                    }
                }
                else {
                    pdfView.go(to: rectangles[4], on: page)
                }
               
            }
            
            print("Drag view in the upperSideSecond of cell at indexPath: \(indexPath)")
            break
        case .centerFirst:
            if let page = self.pdfView.document?.page(at: stoppedDragViewIndex.row) {
                if imagesArray.count > 7 {
                    if stoppedDragViewIndex.row == 1 || stoppedDragViewIndex.row == 2 || stoppedDragViewIndex.row == 3{
                        pdfView.go(to: rectangles[2], on: page)
                    }
                    else {
                        pdfView.go(to: rectangles[3], on: page)
                    }
                }
                else {
                    pdfView.go(to: rectangles[3], on: page)
                }
             
            }
            print("Drag view in the centerFirst of cell at indexPath: \(indexPath)")
            break
        case .centerSecond:
            if let page = self.pdfView.document?.page(at: stoppedDragViewIndex.row) {
                if imagesArray.count > 7 {
                    if stoppedDragViewIndex.row == 1 || stoppedDragViewIndex.row == 2 || stoppedDragViewIndex.row == 3{
                        pdfView.go(to: rectangles[3], on: page)
                    }
                    else {
                        pdfView.go(to: rectangles[2], on: page)
                    }
                }
                else{
                    pdfView.go(to: rectangles[2], on: page)
                }
              
            }
            print("Drag view in the centerSecond of cell at indexPath: \(indexPath)")
            break
        case .lowerSideFirst:
            if let page = self.pdfView.document?.page(at: stoppedDragViewIndex.row) {
                if imagesArray.count > 7 {
                    if stoppedDragViewIndex.row == 1 || stoppedDragViewIndex.row == 2 || stoppedDragViewIndex.row == 3{
                        pdfView.go(to: rectangles[4], on: page)
                    }
                    else{
                        pdfView.go(to: rectangles[1], on: page)
                    }
                }
                else {
                    pdfView.go(to: rectangles[1], on: page)
                }
           
        }
            print("Drag view in the lowerSideFirst of cell at indexPath: \(indexPath)")
            break
        case .lowerSideSecond:
             if let page = self.pdfView.document?.page(at: stoppedDragViewIndex.row) {
                 if imagesArray.count > 7 {
                     if stoppedDragViewIndex.row == 1 || stoppedDragViewIndex.row == 2 || stoppedDragViewIndex.row == 3{
                         pdfView.go(to: rectangles[5], on: page)
                     }
                     else {
                         pdfView.go(to: rectangles[0], on: page)
                     }
                    
                 }
                 else {
                     pdfView.go(to: rectangles[0], on: page)
                 }
          
        }
            print("Drag view in the lowerSideSecond of cell at indexPath: \(indexPath)")
            break
        case .none:
            print("Drag view out of bound: \(indexPath)")
            break
        }
    }
    func calculateDragViewPositionInCurrentCell(_ dragView: UIView) -> DragViewPosition? {

        if let cell = pdfTableView.cellForRow(at: stoppedDragViewIndex) {
            let centerY = cell.bounds.midY
            //                print(centerY)
            self.dragViewCenterYInView = 0
            //                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [self] in
            
            var center = dragView.center
            
           
            if let index = pdfTableView.indexPathsForFullyVisibleRows().firstIndex(where: {$0 == stoppedDragViewIndex}){
                print(index)
                if pdfTableView.indexPathsForVisibleRows != pdfTableView.indexPathsForFullyVisibleRows(){
                    if let index = pdfTableView.indexPathsForVisibleRows?.first{
                        var cellRect = pdfTableView.rectForRow(at: index)
                            if let superview = pdfTableView.superview {
                                let convertedRect = pdfTableView.convert(cellRect, to:superview)
                                let intersect = CGRectIntersection(pdfTableView.frame, convertedRect)
                                let visibleHeight = CGRectGetHeight(intersect)
                                if visibleHeight != 124{
                                    self.halfVisibleCellHeight = Int(visibleHeight)
                                }
//                                print("Heigth for half Visible cell =")
//                                print(visibleHeight)
                            }

                    }
                }
                if stoppedDragViewIndex.row > 0 {
                    var previousSpaces =  (index) * 124
                    previousSpaces = previousSpaces + (halfVisibleCellHeight ?? 0)
                    print(halfVisibleCellHeight)
                    let finalSpace = center.y - CGFloat(previousSpaces)
                    if previousSpaces > Int(dragView.center.y) {
                        let finalSpace = CGFloat(previousSpaces) - center.y
                        center = CGPoint(x: center.x, y: finalSpace)
                    }
                    else{
                        center = CGPoint(x: center.x, y: finalSpace)
                    }
                   
                    print("Previous Space = \(previousSpaces) final space = \(finalSpace)")
                }
            }
            else {
                
            }
            print("drag view center \(dragView.center) center \(center)")
            
            print(pdfTableView.indexPathsForFullyVisibleRows())
            
            dragViewCenterYInView = cell.convert(center, from: cell.contentView).y
    
            //                }
            
//            print("cell bounds \(cell.contentView.bounds) graview bound \(dragView.center)")
            print(dragViewCenterYInView)
            if dragViewCenterYInView < 21 {
                return .upperSideFirst
            } else if dragViewCenterYInView >= 21 && dragViewCenterYInView < 42 {
                return .upperSideSecond
            } else if dragViewCenterYInView >= 42 && dragViewCenterYInView < 63 {
                return .centerFirst
            } else if dragViewCenterYInView >= 63 && dragViewCenterYInView < 84 {
                return .centerSecond
            } else if dragViewCenterYInView >= 84 && dragViewCenterYInView < 105{
                return .lowerSideFirst
            }else{
                return .lowerSideSecond
            }
            
        }
        return nil
        
    }
    
    func getHalfVisibleCellHeight(indexPath: IndexPath){
        var cellRect = pdfTableView.rectForRow(at: indexPath)
            if let superview = pdfTableView.superview {
                let convertedRect = pdfTableView.convert(cellRect, to:superview)
                let intersect = CGRectIntersection(pdfTableView.frame, convertedRect)
                let visibleHeight = CGRectGetHeight(intersect)
            }
    }
    
    func calculateDragViewPositionInCurrentCell1(_ dragView: UIView) -> DragViewPosition? {
        // Get the currently visible cell
        //        if let indexPaths = pdfTableView.indexPathsForVisibleRows, let currentIndexPath = indexPaths.first {
        //                    if let cell = pdfTableView.cellForRow(at: currentIndexPath) {
        
        //        if viewDragged && self.stoppedDragViewIndex != lastIndex{
        if viewDragged{
            
            if let cell = pdfTableView.cellForRow(at: stoppedDragViewIndex) {
                let centerY = cell.bounds.midY
                //                print(centerY)
                self.dragViewCenterYInView = 0
                //                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [self] in
                dragViewCenterYInView = cell.convert(dragView.center, from: cell.contentView).y
                //                }
                print(dragViewCenterYInView)
                //                    let centerYDifference = abs(centerY - dragViewCenterYInView)
                //                print(centerYDifference)
                //                    let centerThreshold = cell.bounds.height / 3
                //                print(centerThreshold)
                if dragViewCenterYInView < 21 {
                    return .upperSideFirst
                } else if dragViewCenterYInView >= 21 && dragViewCenterYInView < 42 {
                    return .upperSideSecond
                } else if dragViewCenterYInView >= 42 && dragViewCenterYInView < 63 {
                    return .centerFirst
                } else if dragViewCenterYInView >= 63 && dragViewCenterYInView < 84 {
                    return .centerSecond
                } else if dragViewCenterYInView >= 84 && dragViewCenterYInView < 105{
                    return .lowerSideFirst
                }else{
                    return .lowerSideSecond
                }
                
            }
            //        }
        }
        else{
            if let cell = pdfTableView.cellForRow(at: stoppedDragViewIndex) {
                let centerY = cell.bounds.midY
                //                print(centerY)
                dragViewCenterYInView = cell.convert(dragView.center, from: cell.contentView).y
                print(dragViewCenterYInView)
                // let centerYDifference = abs(centerY - dragViewCenterYInView)
                //                print(centerYDifference)
                //  let centerThreshold = cell.bounds.height / 3
                //                print(centerThreshold)
                if dragViewCenterYInView < 21 {
                    return .upperSideFirst
                } else if dragViewCenterYInView >= 21 && dragViewCenterYInView < 42 {
                    return .upperSideSecond
                } else if dragViewCenterYInView >= 42 && dragViewCenterYInView < 63 {
                    return .centerFirst
                } else if dragViewCenterYInView >= 63 && dragViewCenterYInView < 84 {
                    return .centerSecond
                } else if dragViewCenterYInView >= 84 && dragViewCenterYInView < 105{
                    return .lowerSideFirst
                }else{
                    if dragViewCenterYInView > 154{
                        dragViewCenterYInView = 0
                    }
                    else {
                        self.viewDragged = true
                        return .lowerSideSecond
                        
                    }
                    
                }
                
            }
            
            
        }
        return nil
        
    }
    
    func updateViewDragPosition() {
        if stoppedIndexes.contains(selectedIndex){
            let targetRect = pdfTableView.rectForRow(at: selectedIndex)
            let centerY = targetRect.midY
            viewDrag.center = CGPoint(x: centerY, y: centerY)
        }
    }
    // MARK: - Actions
    
    @IBAction func dragPlusBtnAction(_ sender: Any) {
        if stoppedDragViewIndex == IndexPath() {
            stoppedDragViewIndex = IndexPath(row: 0, section: 0)
        }
        stoppedIndexes.append(stoppedDragViewIndex)
        pdfTableView.reloadData()
    }
}
// MARK: - TableView delegates & DataSource

extension PreviewPDFViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        imagesArray.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PDFTableViewCell", for: indexPath) as! PDFTableViewCell
        cell.pdfImageView.image = self.imagesArray[indexPath.row]
        if stoppedIndexes.contains(indexPath) {
            cell.bookMarkBtnOutlet.isHidden = false
        } else {
            cell.bookMarkBtnOutlet.isHidden = true
        }
        cell.bookMarkTap = { [self] () in
            selectedIndex = indexPath
            if let page = self.pdfView.document?.page(at: indexPath.row) {
                pdfView.go(to: page)
            }
//            updateViewDragPosition()
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 126
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    }
    
}
extension PDFView  {
    var scrollView: UIScrollView? {
        guard let pageViewControllerContentView = subviews.first else { return nil }
        for view in pageViewControllerContentView.subviews {
            guard let scrollView = view as? UIScrollView else { continue }
            return scrollView
        }
        
        return nil
    }
}

extension PreviewPDFViewController : UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
//extension PreviewPDFViewController: UIScrollViewDelegate {
//    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        let viewDragCenterInTableView = pdfTableView.convert(viewDrag.center, from: self.view)
//        if let indexPath = pdfTableView.indexPathForRow(at: viewDragCenterInTableView) {
//            if indexPath != stoppedIndexes.last {
//                stoppedIndexes.append(indexPath)
//                pdfTableView.reloadRows(at: stoppedIndexes, with: .automatic)
//            }
//        }
//    }
//}

extension UITableView {
    func isCellAtIndexPathFullyVisible(_ indexPath: IndexPath) -> Bool {
        let cellFrame = rectForRow(at: indexPath)
        return bounds.contains(cellFrame)
    }
    func indexPathsForFullyVisibleRows() -> [IndexPath] {
        let visibleIndexPaths = indexPathsForVisibleRows ?? []
        return visibleIndexPaths.filter { indexPath in
            return isCellAtIndexPathFullyVisible(indexPath)
        }
    }
}



