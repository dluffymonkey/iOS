import UIKit

class GiphySelectionViewController: UIViewController {
    
    private var mainView: GiphySelectionView {
        return self.view as! GiphySelectionView
    }
    
    let chatRoom: MEGAChatRoom!
    
    let searchController = UISearchController(searchResultsController: nil)
    
    init(chatRoom: MEGAChatRoom) {
        self.chatRoom = chatRoom

        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = GiphySelectionView(controller: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = AMLocalizedString("Send GIF")
        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)

        searchController.obscuresBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.showsCancelButton = false
        searchController.searchBar.placeholder = AMLocalizedString("Search GIPHY")
        definesPresentationContext = true
        
        searchController.searchBar.delegate = mainView
        searchController.delegate = mainView
        if #available(iOS 11.0, *) {
            navigationItem.searchController = searchController
            navigationItem.hidesSearchBarWhenScrolling = false
        } else {
           navigationItem.titleView = searchController.searchBar
        }
        
        navigationController?.isToolbarHidden = false
        let giphyIconItem = UIBarButtonItem(image: UIImage(named: "poweredByGIPHY"), style: .plain, target: nil, action: nil)
        toolbarItems = [UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
                        giphyIconItem,
                        UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)]
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        mainView.viewOrientationDidChange()
    }
}

extension GiphySelectionViewController: TraitEnviromentAware {
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        traitCollectionChanged(to: traitCollection, from: previousTraitCollection)
    }
    
    func colorAppearanceDidChange(to currentTrait: UITraitCollection, from previousTrait: UITraitCollection?) {
        if #available(iOS 13, *) {
            AppearanceManager.forceSearchBarUpdate(searchController.searchBar, traitCollection: currentTrait)
        }
    }
}