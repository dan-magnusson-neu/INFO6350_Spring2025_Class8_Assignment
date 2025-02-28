//
//  HelloViewController.swift
//  Class7Example
//
//  Created by Daniel Magnusson on 2/18/25.
//

import Foundation
import UIKit
import LetsCountLib

class CounterViewController: UIViewController {
    
    private let session: CounterAPISession
    private var currentCounter: Counter?
    private var counterView: CounterView!
    private var titleLabel: UILabel!
    
    init(initialCounter: CounterResponse? = nil, session: CounterAPISession) {
        self.session = session
        currentCounter = initialCounter
        counterView = CounterView(count: currentCounter?.currentValue ?? 0)
        counterView.translatesAutoresizingMaskIntoConstraints = false
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        
        titleLabel = UILabel()
        
        view.backgroundColor = .white
        
        counterView.delegate = self
        view.addSubview(counterView)
    
        if let counter = currentCounter as? CounterResponse,
           let namespace = counter.namespace,
           let key = counter.key {
            titleLabel.text = "\(namespace)/\(key)"
        }
    
        Task {
            guard let response = await self.callSessionWith(route: .base) else { return }
            titleLabel.text = "\(response.namespace ?? "")/\(response.key ?? "")"
        }
        
        titleLabel.numberOfLines = 0
        titleLabel.font = .systemFont(ofSize: 36, weight: .medium)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor, constant: 0),
            titleLabel.widthAnchor.constraint(equalTo: view.layoutMarginsGuide.widthAnchor, multiplier: 1),
            
            counterView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            counterView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            counterView.widthAnchor.constraint(equalTo: view.widthAnchor),
            counterView.topAnchor.constraint(lessThanOrEqualTo: titleLabel.bottomAnchor),
            counterView.bottomAnchor.constraint(greaterThanOrEqualTo: view.keyboardLayoutGuide.topAnchor)
        ])
    }
    
    func updateCounter(with response: CounterResponse) {
        guard let namespace = response.namespace,
              let key = response.key,
              let value = response.currentValue else { return }
        currentCounter = response
        titleLabel.text = "\(namespace)/\(key)"
        counterView.updateLabel(text: "\(value)")
    }
    
    func callSessionWith(route: CounterAPISession.Route) async -> CounterResponse? {
        let response = switch route {
        case .base, .update:
            try? await self.session.getCounterValue()
        case .increment:
            try? await self.session.incrementCounter()
        case .decrement:
            try? await self.session.decrementCounter()
        }
        guard let response = response,
              let value = response.currentValue else { return nil }
        self.currentCounter = response
        self.counterView.updateLabel(text: "\(value)")
        return response
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension CounterViewController: CounterViewDelegate {
    func decrementPressed() async {
        if let response = await self.callSessionWith(route: .decrement) {
            updateCounter(with: response)
        }
    }
    
    func incrementPressed() async {
        if let response = await self.callSessionWith(route: .increment) {
            updateCounter(with: response)
        }
    }
}

#Preview {
    let session = CounterAPISession(namespace: "INFO6350", key: "dan.magnusson")
    let home = HomeViewController()
    let vc = CounterViewController(session: session)
    let nav = UINavigationController(rootViewController: home)
    home.show(vc, sender: home)
    return nav
}
