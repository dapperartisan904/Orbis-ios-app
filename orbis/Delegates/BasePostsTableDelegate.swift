//
//  BasePostsTableDelegate.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 04/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import UIKit

class BasePostsTableDelegate<VM : BasePostsViewModel & PostsViewModelContract> : NSObject, UITableViewDelegate {
    
    // Post key of video that is being played
    private(set) var currentVideoKey: String?

    private(set) var tableOffset: CGFloat = 0
    
    let viewModel: VM
    
    init(viewModel: VM) {
        self.viewModel = viewModel
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let cellType = viewModel.getCellType(indexPath: indexPath)
        if cellType == .adMobCell {
            return 375.0
        }
        
        guard let postType = viewModel.getPost(indexPath: indexPath).typeEnum() else {
            return 0.0
        }
        
        switch postType {
        case .images, .video:
            let hasText = viewModel.getPost(indexPath: indexPath).details?.isEmpty ?? true
            if hasText {
                return UITableView.automaticDimension
            }
            else {
                return 300.0
            }
        case .checkIn, .wonPlace, .lostPlace, .conqueredPlace, .event, .eventGroup:
            return 360.0
        case .text:
            return UITableView.automaticDimension
        }
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 300.0
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        viewModel.onScrolled(position: indexPath.row)
    }
    
    /*
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let videoCell = cell as? VideoPostCell3 else { return }
        print2("[VIDEO] willDisplay \(indexPath.row)")
        let visibleCells = tableView.visibleCells
        let minIndex = visibleCells.startIndex
        if tableView.visibleCells.index(of: cell) == minIndex {
            print2("[VIDEO] willDisplay automatic play \(indexPath.row)")
            videoCell.playerView.player?.play()
        }
    }
    */
    
    private func playVideo(tableView: UITableView, indexPath: IndexPath) {
        let postKey = viewModel.getPost(indexPath: indexPath).postKey
        if postKey == currentVideoKey {
            return
        }
        
        var paths = [IndexPath]()
        
        if let k = currentVideoKey, let i = viewModel.indexOf(postKey: k) {
            paths.append(IndexPath(row: i, section: 0))
        }
        
        currentVideoKey = postKey
        paths.append(indexPath)

        //let offset = tableView.contentOffset
        tableView.reloadRows(at: paths, with: .none)
        tableView.layoutIfNeeded()
        //tableView.contentOffset = offset
    }
    
    private func handleAutoplayInTopVideoCell(tableView: UITableView) {
        if tableView.isDecelerating || tableView.isDragging {
            return
        }
        
        if tableView.contentOffset.y == 0 {
            guard
                let topIndexPath = tableView.indexPathsForVisibleRows?.first
            else {
                return
            }
        
            print2("[Scroll 1] to \(topIndexPath.row)")
            playVideo(tableView: tableView, indexPath: topIndexPath)
            return
        }
       
        tableView.visibleCells.forEach { (cell) in
            guard let indexPath = tableView.indexPath(for: cell) else { return }
            let cellRect = tableView.rectForRow(at: indexPath)
            let superView = tableView.superview
            
            let convertedRect = tableView.convert(cellRect, to: superView)
            let intersect = tableView.frame.intersection(convertedRect)
            let visibleHeight = intersect.height
            
            // Cell is visible more than 60%
            if visibleHeight > cellRect.height * 0.6 {
                print2("[Scroll 2] to \(indexPath.row)")
                playVideo(tableView: tableView, indexPath: indexPath)
            }
        }
        
    }
    
    func setOffset(offset: CGFloat) {
        tableOffset = offset
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if viewModel.placedOnHome() {
            let delta = scrollView.contentOffset.y - tableOffset
            tableOffset = scrollView.contentOffset.y
            HomeViewModel.instance().contentOffsetSubject.onNext((viewModel.radarTab()!, delta))
        }
    }
    
    /*
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        print2("scrollViewDidScroll")
        handleAutoplayInTopVideoCell(tableView: scrollView as! UITableView)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        print2("scrollViewDidEndDecelerating")
        handleAutoplayInTopVideoCell(tableView: scrollView as! UITableView)
    }
    */
}
