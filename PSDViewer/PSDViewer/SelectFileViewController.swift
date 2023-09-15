//
//  SelectFileViewController.swift
//  PSDViewer
//
//  Created by Momin Khan on 04/09/2023.
//

import UIKit
import PDFKit
import UniformTypeIdentifiers
import MobileCoreServices


class SelectFileViewController: UIViewController{
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    func selectFiles() {
        let types = UTType.types(tag: "pdf",
                                 tagClass: UTTagClass.filenameExtension,
                                 conformingTo: nil)
        let documentPickerController = UIDocumentPickerViewController(
                forOpeningContentTypes: types)
        documentPickerController.delegate = self
        self.present(documentPickerController, animated: true, completion: nil)
    }
    
    func showPreviewPDFVC(url:URL){
        let vc = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "PreviewPDFViewController") as? PreviewPDFViewController
        vc?.pdfUrl = url
        self.navigationController?.pushViewController(vc!, animated: true)
    }
    
    @IBAction func selectFileBtnAction(_ sender: Any) {
        selectFiles()
    }
    
}

extension SelectFileViewController: UIDocumentPickerDelegate, UINavigationControllerDelegate {
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
         let myURL = urls.first
        self.showPreviewPDFVC(url: myURL ?? URL(fileURLWithPath: ""))
        print("import result : \(String(describing: myURL))")
    }
          

     func documentMenu(_ documentMenu:UIDocumentPickerViewController, didPickDocumentPicker documentPicker: UIDocumentPickerViewController) {
        documentPicker.delegate = self
        present(documentPicker, animated: true, completion: nil)
    }


    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("view was cancelled")
        dismiss(animated: true, completion: nil)
    }
   
}
