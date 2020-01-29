//
//  EventGroupCell.swift
//  orbis_sandbox
//
//  Created by Guru on 8/29/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import UIKit

class EventGroupCell: UITableViewCell {

    weak var likesViewModel: LikesViewModel?
    weak var activeGroup: Group?
    weak var cellDelegate: PostCellDelegate?
    var posts: [OrbisPost] = []
    weak var viewModel: BasePostsViewModel?
    var indexPath = IndexPath(row: 0, section: 0)
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var pageControl: UIPageControl!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        collectionView.register(WonPlacePostCell2.self, forCellWithReuseIdentifier: "WonPlacePostCell2")
        collectionView.register(LostPlacePostCell2.self, forCellWithReuseIdentifier: "LostPlacePostCell2")
        collectionView.register(CheckInCell2.self, forCellWithReuseIdentifier: "CheckInCell2")
        collectionView.delegate = self
        collectionView.dataSource = self
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func fill(indexPath: IndexPath, viewModel: BasePostsViewModel?, evenGroup: [OrbisPost], activeGroup: Group?, likesViewModel: LikesViewModel?, cellDelegate: PostCellDelegate?) {
        self.likesViewModel = likesViewModel
        self.activeGroup = activeGroup
        self.cellDelegate = cellDelegate
        self.posts = evenGroup
        self.viewModel = viewModel
        self.indexPath = indexPath
        collectionView.reloadData()
        pageControl.numberOfPages = posts.count
    }

}

extension EventGroupCell: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: contentView.frame.width, height: 360)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let post = posts[indexPath.row]
        let wrapper = viewModel!.getPostWrapper(indexPath: IndexPath(row: self.indexPath.row, section: indexPath.row), activeGroup: activeGroup, isLiking: likesViewModel?.isLiking(postKey: post.postKey) ?? false, cellDelegate: cellDelegate)
        
        let type = post.typeEnum()?.getCellType() ?? Cells.checkInPostCell
        switch type {
        case .wonPlacePostCell:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "WonPlacePostCell2", for: indexPath) as! WonPlacePostCell2
            cell.cell.fill(wrapper: wrapper)
            return cell
        case .lostPlacePostCell:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "LostPlacePostCell2", for: indexPath) as! LostPlacePostCell2
            cell.cell.fill(wrapper: wrapper)
            return cell
        default:
            break
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CheckInCell2", for: indexPath) as! CheckInCell2
        cell.cell.fill(wrapper: wrapper)
        return cell
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        let pageNumber = round(scrollView.contentOffset.x / scrollView.frame.size.width)
        pageControl.currentPage = Int(pageNumber)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let pageNumber = round(scrollView.contentOffset.x / scrollView.frame.size.width)
        pageControl.currentPage = Int(pageNumber)
    }
}

class WonPlacePostCell2: UICollectionViewCell {
    
    let cell = UIView.loadFromNib(named: Cells.wonPlacePostCell.rawValue) as! WonPlacePostCell
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(cell.contentView)
        cell.contentView.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.leftAnchor.constraint(equalTo: contentView.leftAnchor).isActive = true
        cell.contentView.rightAnchor.constraint(equalTo: contentView.rightAnchor).isActive = true
        cell.contentView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        cell.contentView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class CheckInCell2: UICollectionViewCell {
    
    let cell = UIView.loadFromNib(named: Cells.checkInPostCell.rawValue) as! CheckInCell

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(cell.contentView)
        cell.contentView.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.leftAnchor.constraint(equalTo: contentView.leftAnchor).isActive = true
        cell.contentView.rightAnchor.constraint(equalTo: contentView.rightAnchor).isActive = true
        cell.contentView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        cell.contentView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

class LostPlacePostCell2: UICollectionViewCell {
    
    let cell = UIView.loadFromNib(named: Cells.lostPlacePostCell.rawValue) as! LostPlacePostCell

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(cell.contentView)
        cell.contentView.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.leftAnchor.constraint(equalTo: contentView.leftAnchor).isActive = true
        cell.contentView.rightAnchor.constraint(equalTo: contentView.rightAnchor).isActive = true
        cell.contentView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        cell.contentView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
