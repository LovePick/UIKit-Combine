//
//  ViewController.swift
//  WizardSchool
//
//  Created by Supapon Pucknavin on 9/11/2565 BE.
//

import UIKit
import Combine
class ViewController: UIViewController {

    // MARK: - VIEW
    @IBOutlet var nameTextField: UITextField!
    @IBOutlet var passwordTextField: UITextField!
    @IBOutlet var repeatTextField: UITextField!
    @IBOutlet var createButton: UIButton!
    
    
    // MARK: - PROPERTY
    // Step 1: Define our publishers
    @Published var password = ""
    @Published var passwordAgain = ""
    @Published var username: String = ""
    
    // Step 2: Define our validation streams
    var validatedUsername: AnyPublisher<String?, Never> {
        return $username
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .removeDuplicates()
            .flatMap { username in
                return Future { promise in
                    self.usernameAvailable(username) { available in
                        promise(.success(available ? username : nil))
                    }
                }
            }
            .eraseToAnyPublisher()
    }
    
    func usernameAvailable(_ username: String, completion: (Bool) -> Void) {
        completion(true) // Our fake asynchronous backend service
    }
    
    
    var validatedPassword: AnyPublisher<String?, Never> {
        return Publishers.CombineLatest($password, $passwordAgain)
            .map{ password, passwordAgain in
                guard password == passwordAgain, password.count > 0 else { return nil }
                return password
            }
            .map{
                ($0 ?? "" == "password1" ? nil : $0)
            }
            .eraseToAnyPublisher()
    }
    
    var validatedCredentials: AnyPublisher<(String, String)?, Never> {
        return Publishers.CombineLatest(validatedUsername, validatedPassword)
            .receive(on: RunLoop.main)
            .map { username, password in
                guard let uname = username, let pwd = password else { return nil }
                return (uname, pwd)
            }
            .eraseToAnyPublisher()
    }
    
    // Step 3: Define our subscriber
    var createButtonSubscriber: AnyCancellable?
    
    
    // MARK: - viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }

    
    private func setup(){
        title = "Wizard School Signup"

        nameTextField.delegate = self
        passwordTextField.delegate = self
        repeatTextField.delegate = self
        
        createButton.addTarget(self, action: #selector(createButtonTapped(_:)), for: .primaryActionTriggered)
        
        // Step 4: Hook our subscriber up to our validation publisher stream
        createButtonSubscriber = validatedCredentials
            .map{ $0 != nil }
            .receive(on: RunLoop.main)
            .assign(to: \.isEnabled, on: createButton)
        
    }

}


// MARK: - UITextFieldDelegate
extension ViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let textFieldText = textField.text ?? ""
        let text = (textFieldText as NSString).replacingCharacters(in: range, with: string)
        
        if textField == nameTextField { username = text }
        if textField == passwordTextField { password = text }
        if textField == repeatTextField { passwordAgain = text }
        
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}


// MARK: - ACTION
extension ViewController {
    @objc private func createButtonTapped(_ sender: UIButton) {
        print("Create button enabled!")
        print("username : \(username)")
        print("password : \(password)")
    }
}
