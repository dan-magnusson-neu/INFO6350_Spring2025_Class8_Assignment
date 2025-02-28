//
//  CounterView.swift
//  Class8Assignment
//
//  Created by Daniel Magnusson on 2/28/25.
//

import Foundation
import UIKit
import SwiftUI

class CounterView: UIView {
    
    var count: Int
    weak var delegate: CounterViewDelegate? = nil
    
    private var buttonConfig: UIButton.Configuration {
        let config = UIButton.Configuration.borderedProminent()
        return config
    }
    
    private var countLabel: UILabel = UILabel()
    private var countSpinner = UIActivityIndicatorView()
    
    init(count: Int, frame: CGRect = .zero) {
        
        self.count = count
        
        super.init(frame: frame)
        
        countLabel.text = "\(count)"
        countLabel.font = .systemFont(ofSize: 36, weight: .heavy)
        countLabel.textAlignment = .center
        
        countSpinner.style = .medium
        countSpinner.isHidden = true
        
        let decrement = UIButton(configuration: buttonConfig, primaryAction: UIAction { action in
            Task {
                self.countSpinner.startAnimating()
                self.countLabel.isHidden = true
                await self.delegate?.decrementPressed()
                self.countLabel.isHidden = false
                self.countSpinner.stopAnimating()
            }
        })
        decrement.configuration?.attributedTitle = AttributedString("-", attributes: AttributeContainer([.font: UIFont.systemFont(ofSize: 36)]))
        
        let increment = UIButton(configuration: buttonConfig, primaryAction: UIAction { action in
            Task {
                self.countSpinner.startAnimating()
                self.countLabel.isHidden = true
                await self.delegate?.incrementPressed()
                self.countLabel.isHidden = false
                self.countSpinner.stopAnimating()
            }
        })
        increment.configuration?.attributedTitle = AttributedString("+", attributes: AttributeContainer([.font: UIFont.systemFont(ofSize: 36)]))

        let labelBackground = UIStackView(arrangedSubviews: [countLabel, countSpinner])
        labelBackground.backgroundColor = .lightGray
        labelBackground.layer.cornerRadius = 5
        
        let stack = UIStackView(arrangedSubviews: [decrement, labelBackground, increment])
        stack.axis = .horizontal
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.spacing = 5
        addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            decrement.widthAnchor.constraint(equalToConstant: 50),
            increment.widthAnchor.constraint(equalToConstant: 50),
            
            countLabel.widthAnchor.constraint(equalToConstant: 50),
            countLabel.heightAnchor.constraint(equalToConstant: 50),
            
            countSpinner.widthAnchor.constraint(equalToConstant: 50),
            countSpinner.heightAnchor.constraint(equalToConstant: 50),
        ])
    }
    
    required init?(coder: NSCoder) {
        self.count = 0
        super.init(coder: coder)
    }
    
    func updateLabel(text: String) {
        countLabel.text = text
    }
}

@MainActor
protocol CounterViewDelegate: AnyObject {
    func decrementPressed() async
    func incrementPressed() async
}

#Preview(traits: .fixedLayout(width: 200, height: 100)) {
    CounterView(count: 5)
}
