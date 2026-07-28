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

(defcustom trustrail-user-config-files nil
 "List of config file paths to scan for package declarations.
When nil, auto-detect from `user-init-file' and follow includes."
 :type '(repeat file)
 :group 'trustrail)

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

;; --- Config file parser ---

(defun trustrail--extract-org-elisp (text)
 "Extract emacs-lisp source blocks from Org TEXT."
 (let ((blocks nil)
       (start 0))
   (while (string-match
           "#\\+begin_src[ \t]+emacs-lisp.*\n\\(\\(?:.\\|\n\\)*?\\)#\\+end_src"
           text start)
     (push (match-string 1 text) blocks)
     (setq start (match-end 0)))
   (mapconcat #'identity (nreverse blocks) "\n")))

(defun trustrail--scan-elisp-packages (text)
 "Scan elisp TEXT for `use-package' and `require' declarations."
 (let ((names nil)
       (start 0))
   (while (string-match "(use-package[ \t\n]+\\([^ \t\n)]+\\)" text start)
     (push (match-string 1 text) names)
     (setq start (match-end 0)))
   (setq start 0)
   (while (string-match "(require[ \t\n]+'\\([^ \t\n)]+\\)" text start)
     (push (match-string 1 text) names)
     (setq start (match-end 0)))
   names))

(defun trustrail--scan-elisp-includes (text)
 "Scan elisp TEXT for file-loading forms and return referenced paths."
 (let ((paths nil)
       (start 0))
   ;; Match string-literal paths: (load "path"), (load-file "path"),
   ;; (org-babel-load-file "path")
   (while (string-match
           "(\\(?:org-babel-load-file\\|load-file\\|load\\)[ \t\n]+\"\\([^\"]+\\)\""
           text start)
     (push (match-string 1 text) paths)
     (setq start (match-end 0)))
   ;; Match expand-file-name with a string literal inside a load form:
   ;; (load (expand-file-name "name.el" dir))
   (setq start 0)
   (while (string-match
           "(expand-file-name[ \t\n]+\"\\([^\"]+\\)\""
           text start)
     (push (match-string 1 text) paths)
     (setq start (match-end 0)))
   paths))

(defun trustrail--resolve-load-path (path base-dir)
 "Resolve PATH relative to BASE-DIR, appending .el if needed."
 (let ((expanded (expand-file-name path base-dir)))
   (cond
    ((and (file-regular-p expanded)
          (string-match-p "\\.\\(?:el\\|org\\)\\'" expanded))
     expanded)
    ((file-regular-p (concat expanded ".el")) (concat expanded ".el"))
    ((file-regular-p (concat expanded ".org")) (concat expanded ".org"))
    (t nil))))

(defun trustrail--parse-config-file (file visited)
 "Parse FILE for package names, following includes.  VISITED tracks seen files."
 (when (and file (file-regular-p file) (file-readable-p file)
            (not (gethash file visited)))
   (puthash file t visited)
   (let* ((text (with-temp-buffer
                  (insert-file-contents file)
                  (buffer-string)))
          (elisp (if (string-suffix-p ".org" file)
                     (trustrail--extract-org-elisp text)
                   text))
          (names (trustrail--scan-elisp-packages elisp))
          (includes (trustrail--scan-elisp-includes elisp))
          (base-dir (file-name-directory file)))
     (dolist (inc includes)
       (let ((resolved (trustrail--resolve-load-path inc base-dir)))
         (when resolved
           (setq names (append names
                               (trustrail--parse-config-file resolved visited))))))
     names)))

(defun trustrail--configured-packages ()
 "Return a hash-table of package names declared in the user config."
 (let ((table (make-hash-table :test 'equal))
       (files (or trustrail-user-config-files
                  (and (boundp 'user-init-file) (list user-init-file))))
       (visited (make-hash-table :test 'equal)))
   (dolist (file files)
     (dolist (name (trustrail--parse-config-file file visited))
       (puthash name t table)))
   table))

;; --- Dependency collector ---

(defun trustrail--dependency-set ()
 "Return a hash-table of package names that are dependencies of other packages."
 (let ((deps (make-hash-table :test 'equal)))
   (dolist (pkg package-alist)
     (let ((desc (cadr pkg)))
       (when desc
         (dolist (req (package-desc-reqs desc))
           (puthash (symbol-name (car req)) t deps)))))
   deps))

;; --- Source classifier ---

(defun trustrail--package-source (name config-set dep-set desc)
 "Classify the install source of package NAME.
CONFIG-SET and DEP-SET are hash-tables.  DESC is the package descriptor."
 (cond
  ((gethash name config-set) "configured")
  ((gethash name dep-set) "dependency")
  ((and desc (package-desc-dir desc)
        (boundp 'package-user-dir)
        (string-prefix-p (expand-file-name package-user-dir)
                         (expand-file-name
                          (format "%s" (package-desc-dir desc)))))
   "manual")
  (t "unknown")))

(defun trustrail--installed-packages ()
 "Return installed packages from `package-alist'."
 (unless package--initialized
   (package-initialize))

 (sort
  (copy-sequence package-alist)
  (lambda (a b)
    (string-lessp (trustrail--package-name a)
                  (trustrail--package-name b)))))

(defun trustrail--tabulated-entry (pkg config-set dep-set)
 "Convert PKG into a `tabulated-list-mode' entry.
CONFIG-SET and DEP-SET are hash-tables for source classification."
 (let* ((name (trustrail--package-name pkg))
        (desc (trustrail--package-desc pkg))
        (version (trustrail--package-version desc))
        (summary (trustrail--package-summary desc))
        (dir (trustrail--package-dir desc))
        (source (trustrail--package-source name config-set dep-set desc)))
   (list name
         (vector name version source summary dir))))

;;;###autoload
(define-derived-mode trustrail-package-list-mode tabulated-list-mode "TrustRail Packages"
 "Major mode for listing installed Emacs packages."
 (setq tabulated-list-format
       [("Package" 28 t)
        ("Version" 18 t)
        ("Source" 12 t)
        ("Summary" 60 t)
        ("Directory" 80 t)])
 (setq tabulated-list-padding 2)
 (setq tabulated-list-sort-key (cons "Package" nil))
 (tabulated-list-init-header))

;;;###autoload
(defun trustrail-list-packages ()
 "List installed Emacs packages in a TrustRail buffer."
 (interactive)
 (let* ((buffer (get-buffer-create trustrail-buffer-name))
        (config-set (trustrail--configured-packages))
        (dep-set (trustrail--dependency-set)))
   (with-current-buffer buffer
     (trustrail-package-list-mode)
     (setq tabulated-list-entries
           (mapcar (lambda (pkg)
                     (trustrail--tabulated-entry pkg config-set dep-set))
                   (trustrail--installed-packages)))
     (tabulated-list-print t))
   (pop-to-buffer buffer)))

(provide 'trustrail)

;;; trustrail.el ends here
