//
//  LoginViewController.swift
//  RoamDemo
//
//  Created by Roam on 09/11/23.
//

import UIKit

class LoginViewController: UIViewController {
    let loginButton: UIButton = {
        let button = UIButton()
        button.setTitle("Login With User", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .red
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 15
        return button
    }()
    
    let loginWithoutUserButton: UIButton = {
        let button = UIButton()
        button.setTitle("Login Without User", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .red
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 15
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        view.addSubview(loginButton)
        view.addSubview(loginWithoutUserButton)
        
        NSLayoutConstraint.activate([
            loginButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loginButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -10),
            loginButton.heightAnchor.constraint(equalToConstant: 50),
            loginButton.widthAnchor.constraint(equalToConstant: 150),
            
            loginWithoutUserButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loginWithoutUserButton.topAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: 10),
            loginWithoutUserButton.heightAnchor.constraint(equalToConstant: 50),
            loginWithoutUserButton.widthAnchor.constraint(equalToConstant: 180),
        ])
        
        loginButton.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        loginWithoutUserButton.addTarget(self, action: #selector(loginWithoutUserButtonTapped), for: .touchUpInside)
    }

    @objc func loginButtonTapped() {
      
        DispatchQueue.main.async {
            let mapViewController = MapViewController()
            mapViewController.loginType = "LoginWithUser"
            self.navigationController?.pushViewController(mapViewController, animated: true)
        }
    }
    
    @objc func loginWithoutUserButtonTapped() {
      
        DispatchQueue.main.async {
            let mapViewController = MapViewController()
            mapViewController.loginType = "LoginWithOutUser"
            self.navigationController?.pushViewController(mapViewController, animated: true)
        }
    }
}
