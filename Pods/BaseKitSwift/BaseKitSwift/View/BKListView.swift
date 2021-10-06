//
//  BKListView.swift
//  BaseKitSwift
//
//  Created by ldc on 2021/9/7.
//  Copyright © 2021 Xiamen Hanin. All rights reserved.
//

import UIKit

public enum BKError: Error {
    case empty
}

public class BKDataContainer<Element> {
    
    public enum DataChange {
        case insert(IndexPath)
        case insertRows([IndexPath])
        case update(IndexPath)
        case deleteRow(IndexPath)
        case deleteSection(Int)
    }
    
    public enum Status: Equatable {
        
        public static func == (lhs: Status, rhs: Status) -> Bool {
            switch (lhs, rhs) {
            case (.loading, .loading):
                return true
            case (.fail, .fail):
                return true
            case (.complete, .complete):
                return true
            default:
                return false
            }
        }
        
        case loading, fail(Error), complete
    }
    
    public var status: Status = .loading {
        didSet { 
            let temp = status
            self.statusDidChangeClosure?(temp)
        }
    }
    
    public var dataSource: [[Element]] = []
    fileprivate var dataSourceDidChangeClosure: ((DataChange) -> Void)?
    fileprivate var statusDidChangeClosure: ((Status) -> Void)?
    
    public func insert(_ model: Element, at indexPath: IndexPath) -> Void {
        
        switch status {
        case .complete:
            var temp = dataSource[indexPath.section]
            temp.insert(model, at: indexPath.row)
            dataSource[indexPath.section] = temp
            dataSourceDidChangeClosure?(.insert(indexPath))
        default:
            break
        }
    }
    
    public func insertRows(_ models: [Element], at indexPaths: [IndexPath]) -> Void {
        
        switch status {
        case .complete:
            if models.count != indexPaths.count {
                print("\(#file)-\(#function)-\(#line): models.count != indexPaths.count")
                return
            }
            for i in 0..<indexPaths.count {
                let indexPath = indexPaths[i]
                var temp = dataSource[indexPath.section]
                temp.insert(models[i], at: indexPath.row)
                dataSource[indexPath.section] = temp
            }
            dataSourceDidChangeClosure?(.insertRows(indexPaths))
        default:
            break
        }
    }
    
    public func update(_ model: Element, at indexPath: IndexPath) -> Void {
        
        switch status {
        case .complete:
            dataSource[indexPath.section][indexPath.row] = model
            dataSourceDidChangeClosure?(.update(indexPath))
        default:
            break
        }
    }
    
    public func delete(at indexPath: IndexPath) -> Void {
        
        switch status {
        case .complete:
            var temp = dataSource[indexPath.section]
            temp.remove(at: indexPath.row)
            if temp.count == 0 {
                dataSource.remove(at: indexPath.section)
                if dataSource.count == 0 {
                    status = .fail(BKError.empty)
                }
                dataSourceDidChangeClosure?(.deleteSection(indexPath.section))
            }else {
                dataSource[indexPath.section] = temp
                dataSourceDidChangeClosure?(.deleteRow(indexPath))
            }
        default:
            break
        }
    }
    
    public func numberOfSections() -> Int {
        
        return executeIfComplete({ $0.count }) ?? 0
    }
    
    public func numberOfRowsInSection(_ section: Int) -> Int {
        
        return executeIfComplete({ $0[section].count }) ?? 0
    }
    
    @discardableResult
    public func executeIfComplete<T>(_ closure: (([[Element]]) -> T)) -> T? {
        
        switch status {
        case .complete:
            return closure(dataSource)
        default:
            return nil
        }
    }
}

public protocol BKErrorDisplayable {
    
    var bk_error: Error { set get }
}

public protocol BKActivityIndicator {
    
    func bk_startAnimating()
    
    func bk_stopAnimating()
}

extension UIActivityIndicatorView: BKActivityIndicator {
    
    public func bk_startAnimating() {
        
        startAnimating()
    }
    
    public func bk_stopAnimating() {
        
        stopAnimating()
    }
}

public protocol BKListViewContentView {
    
    func lv_insert(at IndexPath: IndexPath)
    
    func lv_insertRows(at indexPaths: [IndexPath])
    
    func lv_update(at indexPath: IndexPath)
    
    func lv_deleteRow(at indexPath: IndexPath)
    
    func lv_deleteSection(at section: Int)
    
    func lv_reloadData()
}

extension UITableView: BKListViewContentView {
    
    public func lv_insert(at IndexPath: IndexPath) {
        
        insertRows(at: [IndexPath], with: .automatic)
    }
    
    public func lv_insertRows(at indexPaths: [IndexPath]) {
        
        insertRows(at: indexPaths, with: .automatic)
    }
    
    public func lv_update(at indexPath: IndexPath) {
        
        reloadRows(at: [indexPath], with: .automatic)
    }
    
    public func lv_deleteRow(at indexPath: IndexPath) {
        
        deleteRows(at: [indexPath], with: .automatic)
    }
    
    public func lv_deleteSection(at section: Int) {
        
        deleteSections([section], with: .automatic)
    }
    
    public func lv_reloadData() {
        
        reloadData()
    }
}

extension UICollectionView: BKListViewContentView {
    
    public func lv_insert(at IndexPath: IndexPath) {
        
        insertItems(at: [IndexPath])
    }
    
    public func lv_insertRows(at indexPaths: [IndexPath]) {
        
        insertItems(at: indexPaths)
    }
    
    public func lv_update(at indexPath: IndexPath) {
        
        reloadItems(at: [indexPath])
    }
    
    public func lv_deleteRow(at indexPath: IndexPath) {
        
        deleteItems(at: [indexPath])
    }
    
    public func lv_deleteSection(at section: Int) {
        
        deleteSections([section])
    }
    
    public func lv_reloadData() {
        
        reloadData()
    }
}

public class BKListView<Element>: UIView {
    
    private let containerView: UIView
    private let contentView: UIView & BKListViewContentView
    private var reloadView: UIView & BKErrorDisplayable
    private let indicatorView: UIView & BKActivityIndicator
    
    public init(
        containerView: UIView? = nil, 
        contentView: UIView & BKListViewContentView, 
        reloadView: UIControl & BKErrorDisplayable,
        indicatorView: (UIView & BKActivityIndicator)? = nil
    ){
        self.containerView = containerView ?? contentView
        self.contentView = contentView
        self.reloadView = reloadView
        self.indicatorView = indicatorView ?? UIActivityIndicatorView.init(style: .gray)
        self.indicatorView.bk_startAnimating()
        super.init(frame: .zero)
        makeConstraint()
        dataContainer.statusDidChangeClosure = { [weak self] in
            self?.updateStatus($0)
        }
        dataContainer.dataSourceDidChangeClosure = { [weak self] in
            guard let self = self else { return }
            switch $0 {
            case .deleteRow(let indexPath):
                self.contentView.lv_deleteRow(at: indexPath)
            case .deleteSection(let section):
                self.contentView.lv_deleteSection(at: section)
            case .insert(let indexPath):
                self.contentView.lv_insert(at: indexPath)
            case .insertRows(let indexPaths):
                self.contentView.lv_insertRows(at: indexPaths)
            case .update(let indexPath):
                self.contentView.lv_update(at: indexPath)
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public var dataContainer = BKDataContainer<Element>()
    
    public var loadDataSourceClosure: ((@escaping (Swift.Result<[[Element]], Error>) -> Void) -> Void)? {
        
        didSet {
            reload()
        }
    }
    
    @objc private func reloadFromFailView() {
        
        switch dataContainer.status {
        case .fail:
            self.reload()
        default:
            break
        }
    }
    
    public func reload() -> Void {
        
        let closure: (Swift.Result<[[Element]], Error>) -> Void = {
            switch $0 {
            case .success(let source):
                self.dataContainer.dataSource = source
                self.dataContainer.status = .complete
            case .failure(let error):
                self.dataContainer.dataSource = []
                self.dataContainer.status = .fail(error)
            }
        }
        dataContainer.status = .loading
        loadDataSourceClosure?(closure)
    }
    
    private func updateStatus(_ status: BKDataContainer<Element>.Status) -> Void {
        
        switch status {
        case .loading:
            indicatorView.isHidden = false
            reloadView.isHidden = true
            containerView.isHidden = true
            indicatorView.bk_startAnimating()
        case .fail(let error):
            indicatorView.isHidden = true
            reloadView.isHidden = false
            reloadView.bk_error = error
            containerView.isHidden = true
            indicatorView.bk_stopAnimating()
        case .complete:
            indicatorView.isHidden = true
            reloadView.isHidden = true
            containerView.isHidden = false
            indicatorView.bk_stopAnimating()
            contentView.lv_reloadData()
        }
    }
    
    private func makeConstraint() -> Void {
        
        addSubview(indicatorView)
        indicatorView.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
        addSubview(reloadView)
        reloadView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        addSubview(containerView)
        containerView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
}
