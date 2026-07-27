;;; trustrail.el --- List installed Emacs packages -*- lexical-binding: t; -*-

;; Author: Palak Mathur
;; Version: 0.0.1
;; Package-Requires: ((emacs "27.1"))
;; Keywords: tools, packages
;; URL: https://github.com/yourname/trustrail

;;; Commentary:

;; MVP 0 for trustrail.el.
;;
;; This package provides a simple command:
;;
;;   M-x trustrail-list-packages
;;
;; It opens a buffer showing packages currently installed through package.el.

;;; Code:

(require 'package)
(require 'tabulated-list)

(defgroup trustrail nil
 "Inspect installed Emacs packages."
 :group 'tools
 :prefix "trustrail-")

(defconst trustrail-buffer-name "*TrustRail Packages*"
 "Name of the TrustRail package list buffer.")

(defun trustrail--package-name (pkg)
 "Return package name from PKG."
 (symbol-name (car pkg)))

(defun trustrail--package-desc (pkg)
 "Return the selected package descriptor from PKG."
 (cadr pkg))

(defun trustrail--package-version (desc)
 "Return package version string from package DESC."
 (if desc
     (package-version-join (package-desc-version desc))
   "unknown"))

(defun trustrail--package-summary (desc)
 "Return package summary from package DESC."
 (or (and desc (package-desc-summary desc))
     ""))

(defun trustrail--package-dir (desc)
 "Return installed package directory from package DESC."
 (or (and desc
          (boundp 'package-user-dir)
          (package-desc-dir desc))
     ""))

(defun trustrail--installed-packages ()
 "Return installed packages from `package-alist'."
 (unless package--initialized
   (package-initialize))

 (sort
  (copy-sequence package-alist)
  (lambda (a b)
    (string-lessp (trustrail--package-name a)
                  (trustrail--package-name b)))))

(defun trustrail--tabulated-entry (pkg)
 "Convert PKG into a `tabulated-list-mode' entry."
 (let* ((name (trustrail--package-name pkg))
        (desc (trustrail--package-desc pkg))
        (version (trustrail--package-version desc))
        (summary (trustrail--package-summary desc))
        (dir (trustrail--package-dir desc)))
   (list name
         (vector name version summary dir))))

;;;###autoload
(define-derived-mode trustrail-package-list-mode tabulated-list-mode "TrustRail Packages"
 "Major mode for listing installed Emacs packages."
 (setq tabulated-list-format
       [("Package" 28 t)
        ("Version" 18 t)
        ("Summary" 60 t)
        ("Directory" 80 t)])
 (setq tabulated-list-padding 2)
 (setq tabulated-list-sort-key (cons "Package" nil))
 (tabulated-list-init-header))

;;;###autoload
(defun trustrail-list-packages ()
 "List installed Emacs packages in a TrustRail buffer."
 (interactive)
 (let ((buffer (get-buffer-create trustrail-buffer-name)))
   (with-current-buffer buffer
     (trustrail-package-list-mode)
     (setq tabulated-list-entries
           (mapcar #'trustrail--tabulated-entry
                   (trustrail--installed-packages)))
     (tabulated-list-print t))
   (pop-to-buffer buffer)))

(provide 'trustrail)

;;; trustrail.el ends here
