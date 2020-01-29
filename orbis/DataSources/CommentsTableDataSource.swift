//
//  CommentsTableDataSource.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 01/02/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import UIKit

class CommentsTableDataSource : BasePostsTableDataSource<CommentsViewModel> {
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            return super.tableView(tableView, cellForRowAt: indexPath)
        }
    
        let cell = tableView.dequeueReusableCell(withCellType: Cells.comment, for: indexPath) as! CommentCell
        let (comment, group, user, counter) = viewModel.commentData(index: indexPath.row)
        
        cell.delegate = cellDelegate as? CommentCellDelegate
        cell.userLabel.text = user?.username
        cell.groupLabel.text = group?.name
        cell.groupImageView.loadGroupImage(group: group)
        cell.dateLabel.text = comment.serverDate?.dateTimeString()
        cell.dotsButton.isHidden = true // TODO KINE: comment > dots button is hidden for now
        cell.likeImageView.tint(activeGroup: activeGroup, isSelected: likesViewModel.isLiking(commentKey: comment.commentKey))
        cell.likesLabel.text = (counter?.likesCount ?? 0).string
        cell.backgroundColor = viewModel.isSelectedThread(comment: comment) ? lightBlueColor() : UIColor.white
        
        if comment.isMainThread() {
            cell.leftConstraint.constant = 20.0
            cell.replyButton.isHidden = false
        }
        else {
            cell.leftConstraint.constant = 68.0
            cell.replyButton.isHidden = true
        }
        
        if let url = comment.imageUrls?.first {
            cell.commentImageView.isHidden = false
            cell.commentLabel.isHidden = true
            cell.commentImageView.loadPostImage(url: url, useCache: true)
        }
        else {
            cell.commentImageView.isHidden = true
            cell.commentLabel.isHidden = false
            cell.commentLabel.text = comment.message
        }
        
        return cell
    }
}
