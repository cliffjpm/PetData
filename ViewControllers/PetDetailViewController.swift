//
//  PetDetailViewController.swift
//  PetData
//
//  Created by Cliff Malcolm Anderson on 1/23/18.
//  Copyright © 2018 ArenaK9. All rights reserved.
//

import UIKit
import CloudKit
import os.log

class PetDetailViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate, UIImagePickerControllerDelegate,UINavigationControllerDelegate {

    //MARK: Properties
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var petNameField: UITextField!
    @IBOutlet weak var sexPicker: UIPickerView!
    @IBOutlet weak var birthDateTxt: UITextField!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    var pet: Pet?
    var dateFormatter : DateFormatter!
    let datePicker = UIDatePicker()
    
    var dobSelected: Date?
    
    let sex = ["Sex", "Male", "Female"]
    var sexSelected: String?
    
    
    //MARK: UI Actions
    @IBAction func dateFieldTouched(_ sender: Any) {
     saveButton.isEnabled = false
    }
    
    //MARK: UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Hide the keyboard.
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        updateSaveButtonState()
        
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        // Disable the Save button while editing.
        saveButton.isEnabled = false
    }
    
    //MARK: UIImagePickerControllerDelegate
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        // Dismiss the picker if the user canceled.
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
 
        if let img = info[UIImagePickerControllerEditedImage] as? UIImage
        {
            photoImageView.image = img
            
        }
        else if let img = info[UIImagePickerControllerOriginalImage] as? UIImage
        {
            photoImageView.image = img
        }
        
        // Dismiss the picker.
        dismiss(animated: true, completion: nil)
    }
    
    func createDatePicker(){
        
        //format date picker
        datePicker.datePickerMode = .date
        
        //toolbar
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        
        //bar button item
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: nil, action: #selector(dateDonePressed))
        toolbar.setItems([doneButton], animated: false)
        
        //connect the input for this field to the toolbar
        birthDateTxt.inputAccessoryView = toolbar
        
        //assign date picker to text field
        birthDateTxt.inputView = datePicker
    }
    
    @objc func dateDonePressed(){
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .none
        birthDateTxt.text = dateFormatter.string(from: datePicker.date)
        dobSelected = datePicker.date
        self.view.endEditing(true)
        saveButton.isEnabled = true
    }
    
    
    @IBAction func selectImageFromPhotoLibrary(_ sender: UITapGestureRecognizer) {
    
    
        // Hide the keyboard.
        petNameField.resignFirstResponder()
        
        // UIImagePickerController is a view controller that lets a user pick media from their photo library.
        let imagePickerController = UIImagePickerController()
        
        // Only allow photos to be picked, not taken.
        imagePickerController.sourceType = .photoLibrary
        
        //Make editing available
        imagePickerController.allowsEditing = true
        
        // Make sure ViewController is notified when the user picks an image.
        imagePickerController.delegate = self
        present(imagePickerController, animated: true, completion: nil)
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return sex[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return sex.count
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        //he sex must not be "Sex"
        if (sex[row] == "Sex") {
            sexSelected = nil
            
        }
        else {
            sexSelected = sex[row]
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var pickerLabel: UILabel? = (view as? UILabel)
        if pickerLabel == nil {
            pickerLabel = UILabel()
            pickerLabel?.font = UIFont(name: (pickerLabel?.font?.fontName)!, size: 13)
            pickerLabel?.textAlignment = .center
        }
        pickerLabel?.text = sex[row]
        pickerLabel?.textColor = UIColor.blue
        
        return pickerLabel!
    }
    
    
    //MARK: Navigation
    // This method lets you configure a view controller before it's presented.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        super.prepare(for: segue, sender: sender)
        
        // Configure the destination view controller only when the save button is pressed.
        guard let button = sender as? UIBarButtonItem, button === saveButton else {
            os_log("The save button was not pressed, cancelling", log: OSLog.default, type: .debug)
            return
        }
        
        pet?.petName = petNameField.text!
        pet?.dob = dobSelected
        pet?.petSex = sexSelected
        pet?.photo = photoImageView.image
        
        if pet?.recordName == nil {
            pet = Pet(petName: petNameField.text!, dob: dobSelected, petSex: sexSelected, photo: photoImageView.image)
        }
    }
    
    @IBAction func cancel(_ sender: UIBarButtonItem) {
    
        //os_log("I understand you want to Cancel", log: OSLog.default, type: .debug)
        
        // Depending on style of presentation (modal or push presentation), this view controller needs to be dismissed in two different ways.
        let isPresentingInAddPetMode = presentingViewController is UINavigationController
        
        if isPresentingInAddPetMode {
            dismiss(animated: true, completion: nil)
        }
        else if let owningNavigationController = navigationController{
            owningNavigationController.popViewController(animated: true)
        }
        else {
            fatalError("The ViewController is not inside a navigation controller.")
        }}
    
    
    //MARK: Standard methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        birthDateTxt.font = UIFont(name: (birthDateTxt.font?.fontName)!, size: 13)
        
        // Handle the text field’s user input through delegate callbacks.
        petNameField.delegate = self
        
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-dd 'T' hh:mm"
        
        self.sexPicker.delegate = self
        self.sexPicker.dataSource = self
        
        createDatePicker()
        
        // Set up views if editing an existing Pet.
        if let pet = pet {
            petNameField.text = pet.petName
            photoImageView.image = (pet.photo ?? nil)
            if pet.dob != nil {
                datePicker.date = pet.dob!
                dateDonePressed()
                
            } else {
                dobSelected = nil
                birthDateTxt.text = "Select Birthday"
            }
            
            sexSelected = (pet.petSex ?? "")
            switch(pet.petSex ?? "") {
                
            case "":
                sexPicker.selectRow(0, inComponent: 0, animated: true)
                
            case "Male":
                sexPicker.selectRow(1, inComponent: 0, animated: true)
                
            case "Female":
                sexPicker.selectRow(2, inComponent: 0, animated: true)
                
            default:
                fatalError("Unexpected Sex Identifier; \(pet.petSex!)")
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: Private Methods
    private func updateSaveButtonState() {
        // Disable the Save button if the text field is empty.
        let text = petNameField.text ?? ""
        saveButton.isEnabled = !text.isEmpty
    }
    

}


