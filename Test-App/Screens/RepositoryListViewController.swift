//
//  ViewController.swift
//  Test-App
//
//  Created by kaiserdem  on 06.08.2021.
//

import UIKit
import SafariServices

private enum SegueType: String {
    case languageList = "Show Language List"
}

class RepositoryListViewController: UIViewController {
    
    @IBOutlet private weak var tableView: UITableView!

    private let refreshControl = UIRefreshControl()

    private let githubService = GithubService()

    fileprivate var currentLanguage = "Swift"
    fileprivate var repositories = [Repository]()


    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self

        setupUI()
        reloadData()

        refreshControl.addTarget(self, action: #selector(RepositoryListViewController.reloadData), for: .valueChanged)

    }
    
    private func setupUI() {
        let chooseLanguageButton = UIBarButtonItem(barButtonSystemItem: .organize,
                                                   target: self,
                                                   action: #selector(RepositoryListViewController.openLanguageList))
        navigationItem.rightBarButtonItem = chooseLanguageButton

        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 100
        tableView.insertSubview(refreshControl, at: 0)
    }
    
    @objc
    fileprivate func reloadData() {
        refreshControl.beginRefreshing()
        navigationItem.title = currentLanguage

        githubService.getMostPopularRepositories(byLanguage: currentLanguage) { [weak self] result in
            self?.refreshControl.endRefreshing()

            switch result {
            case let .error(error):
                print(error)
            case let .success(newRepositories):
                self?.repositories = newRepositories
                self?.tableView.reloadData()
            }
        }
    }
    
    @objc
    private func openLanguageList() {
        performSegue(withIdentifier: SegueType.languageList.rawValue, sender: self)
    }

    private func presentAlert(message: String) {
        let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertController, animated: true)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        var destinationVC: UIViewController? = segue.destination

        if let nvc = destinationVC as? UINavigationController {
            destinationVC = nvc.viewControllers.first
        }

        if let viewController = destinationVC as? LanguageListViewController, segue.identifier == SegueType.languageList.rawValue {
            viewController.delegate = self
        }
    }
}

extension RepositoryListViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return repositories.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RepositoryCell", for: indexPath) as! RepositoryCell
        let repo = repositories[indexPath.row]
        cell.selectionStyle = .none
        cell.setName(repo.fullName)
        cell.setDescription(repo.description)
        cell.setStarsCountTest("?????? \(repo.starsCount)")
        return cell
    }
}

extension RepositoryListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let repository = repositories[indexPath.row]
        let url = URL(string: repository.url)!
        let safariViewController = SFSafariViewController(url: url)
        navigationController?.pushViewController(safariViewController, animated: true)
    }
}

extension RepositoryListViewController: LanguageListViewControllerDelegate {
    func languageListViewController(_ viewController: LanguageListViewController, didSelectLanguage language: String) {
        currentLanguage = language
        reloadData()
        dismiss(animated: true)
    }

    func languageListViewControllerDidCancel(_ viewController: LanguageListViewController) {
        dismiss(animated: true)
    }
}
