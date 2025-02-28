//
//  ViewController.swift
//  Class7Example
//
//  Created by Daniel Magnusson on 2/18/25.
//

import UIKit
import SwiftUI
import LetsCountLib

class HomeViewController: UIViewController {
    
    var namespaceField = UITextField()
    var keyField = UITextField()
    
    var counterButton = UIButton()
    
    var fetchCounterTask: Task<Void, Error>? = nil
    
    var namespaces = ["INFO6350", "INFO6250"]
    var keys = [["dan.magnusson", "dan"], ["daniel"]]
    
    var historyView = UITableView(frame: .zero, style: .plain)
    
    var createString = AttributedString("Create", attributes: AttributeContainer([.font: UIFont.systemFont(ofSize: 24)]))
    var loadString = AttributedString("Load", attributes: AttributeContainer([.font: UIFont.systemFont(ofSize: 24)]))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.title = "Counters"
        view.backgroundColor = .white
        
        historyView.delegate = self
        historyView.dataSource = self
    
        let editAction = UIAction { action in
            self.updateButtonForSession()
        }
        
        let beginEditAction = UIAction { action in
            // Deselect any selected rows when we start editing the namespace / key
            self.historyView.selectRow(at: nil, animated: false, scrollPosition: .none)
        }
        
        namespaceField.placeholder = "namespace"
        namespaceField.font = .systemFont(ofSize: 36)
        namespaceField.borderStyle = .roundedRect
        namespaceField.autocapitalizationType = .none
        namespaceField.autocorrectionType = .no
        namespaceField.addAction(editAction, for: .editingChanged)
        namespaceField.addAction(beginEditAction, for: .editingDidBegin)
        
        keyField.placeholder = "key"
        keyField.font = .systemFont(ofSize: 36)
        keyField.borderStyle = .roundedRect
        keyField.autocapitalizationType = .none
        keyField.autocorrectionType = .no
        keyField.addAction(editAction, for: .editingChanged)
        keyField.addAction(beginEditAction, for: .editingDidBegin)
        
        var config = UIButton.Configuration.filled()
        config.buttonSize = .medium
        
        counterButton.addAction(UIAction { action in
            self.counterButton.isEnabled = false
            guard let namespace = self.namespaceField.text,
                  let key = self.keyField.text else { return }
            self.namespaceField.resignFirstResponder()
            self.keyField.resignFirstResponder()
            let session = CounterAPISession(namespace: namespace, key: key)
            Task {
                if (try? await session.getCounterValue()) == nil {
                    guard let _ = try? await session.createCounter(startingWith: nil) else { return }
                }
                await self.navigateToCounter(for: session)
            }
        }, for: .primaryActionTriggered)
        counterButton.isEnabled = false
        counterButton.configuration = config
        counterButton.configuration?.attributedTitle = createString
        
        let separator = UIView()
        separator.backgroundColor = .separator
        separator.layer.cornerRadius = 3
        
        let stack = UIStackView(arrangedSubviews: [historyView, separator, namespaceField, keyField, counterButton])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 10
        
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(closeKeyboard))
        swipe.direction = .down
        swipe.numberOfTouchesRequired = 1
        view.addGestureRecognizer(swipe)
        
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor, constant: -50),
            stack.widthAnchor.constraint(equalTo: view.layoutMarginsGuide.widthAnchor),
            stack.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
            
            separator.heightAnchor.constraint(equalToConstant: 3),
            separator.widthAnchor.constraint(equalTo: stack.widthAnchor, multiplier: 1.0),
            
            counterButton.widthAnchor.constraint(equalToConstant: 100),
            historyView.widthAnchor.constraint(equalTo: stack.widthAnchor),
            namespaceField.widthAnchor.constraint(equalTo: stack.widthAnchor),
            keyField.widthAnchor.constraint(equalTo: stack.widthAnchor)
        ])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        updateButtonForSession()
        historyView.selectRow(at: nil, animated: false, scrollPosition: .top)
    }
    
    @IBAction func closeKeyboard() {
        self.namespaceField.resignFirstResponder()
        self.keyField.resignFirstResponder()
    }
    
    func navigateToCounter(for session: CounterAPISession) async {
        let path = await session.getPath()
        
        let namespace = path.namespace
        let key = path.key
        
        if let index = namespaces.firstIndex(of: namespace) {
            if !keys[index].contains(key) {
                keys[index].append(key)
            }
        } else {
            namespaces.append(namespace)
            keys.append([key])
        }
        let counterVC = CounterViewController(session: session)
        show(counterVC, sender: self)
//        self.navigationController?.pushViewController(counterVC, animated: true)
    }
    
    func updateButtonForSession(navigate: Bool = false) {
        historyView.selectRow(at: nil, animated: false, scrollPosition: .none)
        guard let namespace = namespaceField.text,
           let key = keyField.text,
              namespace.count > 0 && key.count > 0 else {
            counterButton.isEnabled = false
            fetchCounterTask?.cancel()
            return
        }
        fetchCounterTask?.cancel()
        fetchCounterTask = Task {
            let session = CounterAPISession(namespace: namespace, key: key)
            do {
                guard let _ = try await session.getCounterValue().currentValue else {
                    if (keyField.text ?? "").count > 0 {
                        counterButton.isEnabled = true
                        counterButton.configuration?.attributedTitle = createString
                        if navigate { await navigateToCounter(for: session) }
                    }
                    return
                }
                counterButton.isEnabled = true
                counterButton.configuration?.attributedTitle = loadString
                if navigate { await navigateToCounter(for: session) }
                
            } catch {
                let error = error as NSError
                if error.domain == NSURLErrorDomain,
                   error.code == NSURLErrorCancelled {
                    counterButton.isEnabled = true
                    counterButton.configuration?.attributedTitle = createString
                    if navigate { await navigateToCounter(for: session) }
                } else {
                    print(error)
                }
                counterButton.isEnabled = false
                return
            }
        }
    }
}

extension HomeViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let namespace = namespaces[indexPath.section]
        let key = keys[indexPath.section][indexPath.row]
        namespaceField.text = namespace
        keyField.text = key
        self.updateButtonForSession(navigate: true)
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        namespaces[section]
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        namespaces.count
    }
}

extension HomeViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        keys[indexPath.section].remove(at: indexPath.row)
        if keys[indexPath.section].count == 0 {
            keys.remove(at: indexPath.section)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return keys[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CounterSession") ?? UITableViewCell(style: .default, reuseIdentifier: "CounterSession")
        
        let key = keys[indexPath.section][indexPath.row]
        var config = cell.defaultContentConfiguration()
        config.text = "\(key)"
        config.textProperties.font = .preferredFont(forTextStyle: .title3)
        cell.contentConfiguration = config
        cell.accessoryType = .disclosureIndicator
        return cell
    }
}

#Preview {
    let vc = HomeViewController()
    let nav = UINavigationController(rootViewController: vc)
    return nav
}
