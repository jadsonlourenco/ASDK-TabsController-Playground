//: Please build the scheme 'AsyncDisplayKitPlayground' first
import PlaygroundSupport
PlaygroundPage.current.needsIndefiniteExecution = true

import AsyncDisplayKit


// Main Controller
final class ViewController: TabsController {
    
    init() {
        let items = [
            TabsControllerItem(title: "Albums", controller: SimpleController(color: UIColor.red)),
            TabsControllerItem(title: "Artists", controller: SimpleController(color: UIColor.blue)),
            TabsControllerItem(title: "Genres", controller: SimpleController(color: UIColor.green)),
            TabsControllerItem(title: "Playlists", controller: SimpleController(color: UIColor.brown))
        ]
        super.init(items: items)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}


// TabsController
class TabsController: ASViewController<ASDisplayNode>, ASPagerDataSource, ASPagerDelegate, ASCollectionDataSource, ASCollectionDelegate {
    private var animating = false
    private var oldIndex:Int = 0
    private var currentIndex:Int = 0
    private let indicatorNode = ASDisplayNode()
    private let titleNode:ASCollectionNode
    private let contentNode = ASPagerNode()
    private var tabsTitles:[String] = []
    private var tabsControllers:[ASViewController<ASDisplayNode>] = []
    
    
    // MARK: View lifecycle
    
    init(items:[TabsControllerItem]) {
        // Init titleNode
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        flowLayout.minimumLineSpacing = 0
        flowLayout.minimumInteritemSpacing = 0
        self.titleNode = ASCollectionNode(collectionViewLayout: flowLayout)
        
        // Init
        super.init(node: ASDisplayNode())
        
        // Add items
        if (items.count > 0) {
            for item in items {
                self.tabsTitles.append(item.title)
                self.tabsControllers.append(item.controller)
            }
        }
        
        // Main Node
        self.node.automaticallyManagesSubnodes = true
        self.node.layoutSpecBlock = { node, constrainedSize in
            self.titleNode.style.preferredSize = CGSize(width: constrainedSize.max.width, height: 60)
            self.contentNode.style.preferredSize = constrainedSize.max
            let mainStack = ASStackLayoutSpec(direction: .vertical, spacing: 0, justifyContent: .start, alignItems: .start, children: [self.titleNode, self.contentNode])
            return mainStack
        }
        
        // Tabs title indicator
        self.indicatorNode.backgroundColor = UIColor.white
        self.indicatorNode.frame = CGRect(x: 0, y: 58, width: 100, height: 2)
        
        // Tabs title
        self.titleNode.addSubnode(self.indicatorNode)
        self.titleNode.backgroundColor = UIColor.darkGray
        self.titleNode.delegate = self
        self.titleNode.dataSource = self
        
        // Tabs content
        self.contentNode.delegate = self
        self.contentNode.dataSource = self
        self.contentNode.view.restorationIdentifier = "contentNode"
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.selectItem(index: self.currentIndex)
    }    
    
    
    // TitleNode collection
    
    func numberOfSections(in collectionNode: ASCollectionNode) -> Int {
        return 1
    }
    
    func collectionNode(_ collectionNode: ASCollectionNode, numberOfItemsInSection section: Int) -> Int {
        return self.tabsTitles.count
    }
    
    func collectionNode(_ collectionNode: ASCollectionNode, nodeBlockForItemAt indexPath: IndexPath) -> ASCellNodeBlock {
        let cellNodeBlock = { () -> ASCellNode in
            let text = self.tabsTitles[indexPath.row]
            let isActive = (self.currentIndex == indexPath.row)
            return TabsControllerItemTitle(text: text, active: isActive)
        }
        return cellNodeBlock
    }
    
    func collectionNode(_ collectionNode: ASCollectionNode, constrainedSizeForItemAt indexPath: IndexPath) -> ASSizeRange {
        return ASSizeRangeMake(CGSize(width: 100, height: 60))
    }
    
    func collectionNode(_ collectionNode: ASCollectionNode, didSelectItemAt indexPath: IndexPath) {
        let index = indexPath.row
        self.selectItem(index: index)
    }
    
    
    // PagerNode
    
    func numberOfPages(in pagerNode: ASPagerNode) -> Int {
        return self.tabsControllers.count
    }
    
    func pagerNode(_ pagerNode: ASPagerNode, nodeAt index: Int) -> ASCellNode {
        let node = ASCellNode(viewControllerBlock: { () -> UIViewController in
            return self.tabsControllers[index]
        }, didLoad: nil)
        return node
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if (scrollView.restorationIdentifier == "contentNode") {
            let offsetX = scrollView.contentOffset.x
            let tabsCount = CGFloat(self.tabsTitles.count)
            let maxOffset = (self.node.bounds.width * (tabsCount - 1))
            if (offsetX > 0 && offsetX < maxOffset && !self.animating) {
                self.indicatorNode.frame = CGRect(x: (offsetX / tabsCount), y: 58, width: 100, height: 2)
            }
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if (scrollView.restorationIdentifier == "contentNode") {
            let index = self.contentNode.currentPageIndex
            self.selectItem(index: index)
        }
    }
    
    
    // Helpers
    
    func selectItem(index:Int) {
        self.animating = true
        UIView.animate(withDuration: 0.3, animations: { 
            self.indicatorNode.frame = CGRect(x: (100 * index), y: 58, width: 100, height: 2)
        }) { (done) in
            self.animating = false
        }
        self.contentNode.scrollToPage(at: index, animated: true)
        self.titleNode.scrollToItem(at: IndexPath(item: index, section: 0), at: UICollectionViewScrollPosition.right, animated: true)
        self.oldIndex = self.currentIndex
        self.currentIndex = index
        if (self.currentIndex != self.oldIndex) {
            self.titleNode.reloadItems(at: [IndexPath(item: self.oldIndex, section: 0), IndexPath(item: self.currentIndex, section: 0)])
        }
    }
    
}




struct TabsControllerItem {
    let title:String
    let controller:ASViewController<ASDisplayNode>
}


final class TabsControllerItemTitle: ASCellNode {
    private let textNode = ASTextNode()
    
    init(text:String, active:Bool) {
        super.init()
        self.automaticallyManagesSubnodes = true
        
        self.textNode.attributedText = NSAttributedString(string: text, attributes: [
            NSForegroundColorAttributeName: active ? UIColor.white : UIColor.gray,
            NSFontAttributeName: UIFont.systemFont(ofSize: 16, weight: UIFontWeightMedium)
        ])
    }
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        return ASStackLayoutSpec(direction: .horizontal, spacing: 0, justifyContent: .center, alignItems: .center, children: [self.textNode])
    }
    
}

// Simple controller to be each Pager
final class SimpleController: ASViewController<ASDisplayNode> {
    init(color:UIColor) {
        super.init(node: ASDisplayNode())
        self.node.backgroundColor = color
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}



// Render
PlaygroundPage.current.liveView = ViewController()
