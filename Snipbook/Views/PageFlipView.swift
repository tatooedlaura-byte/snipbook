import SwiftUI
import UIKit

/// Page flip controller that uses existing PageView without any modifications
struct PageFlipView: UIViewControllerRepresentable {
    let pages: [Page]
    let backgroundTexture: String
    let backgroundPattern: String
    let bookTitle: String
    @Binding var currentPageIndex: Int

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIPageViewController {
        let pageVC = UIPageViewController(
            transitionStyle: .pageCurl,
            navigationOrientation: .horizontal,
            options: nil
        )
        pageVC.delegate = context.coordinator
        pageVC.dataSource = context.coordinator
        pageVC.view.backgroundColor = .clear

        if !pages.isEmpty {
            let vc = context.coordinator.viewController(for: 0)
            pageVC.setViewControllers([vc], direction: .forward, animated: false)
        }

        return pageVC
    }

    func updateUIViewController(_ pageVC: UIPageViewController, context: Context) {
        let oldTexture = context.coordinator.parent.backgroundTexture
        let oldPattern = context.coordinator.parent.backgroundPattern
        context.coordinator.parent = self

        // Refresh current page if background or pattern changed
        if (oldTexture != backgroundTexture || oldPattern != backgroundPattern), !pages.isEmpty {
            let index = min(currentPageIndex, pages.count - 1)
            let vc = context.coordinator.viewController(for: index)
            pageVC.setViewControllers([vc], direction: .forward, animated: false)
        }
    }

    class Coordinator: NSObject, UIPageViewControllerDelegate, UIPageViewControllerDataSource {
        var parent: PageFlipView

        init(_ parent: PageFlipView) {
            self.parent = parent
        }

        func viewController(for index: Int) -> UIHostingController<AnyView> {
            let page = parent.pages[index]
            // Use existing PageView exactly as-is
            let view = PageView(
                page: page,
                pageNumber: index + 1,
                backgroundTexture: parent.backgroundTexture,
                backgroundPattern: parent.backgroundPattern,
                bookTitle: parent.bookTitle
            )
            let vc = UIHostingController(rootView: AnyView(view))
            vc.view.backgroundColor = .clear
            vc.view.tag = index
            return vc
        }

        func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
            let index = viewController.view.tag
            guard index > 0 else { return nil }
            return self.viewController(for: index - 1)
        }

        func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
            let index = viewController.view.tag
            guard index < parent.pages.count - 1 else { return nil }
            return self.viewController(for: index + 1)
        }

        func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
            guard completed, let vc = pageViewController.viewControllers?.first else { return }
            DispatchQueue.main.async {
                self.parent.currentPageIndex = vc.view.tag
            }
        }
    }
}
