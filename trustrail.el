;;; trustrail.el --- List installed Emacs packages -*- lexical-binding: t; -*-

;; Author: Palak Mathur
;; Version: 0.1.0
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

(defun trustrail--package-archive (desc)
 "Return the archive name from package DESC."
 (or (and desc (package-desc-archive desc))
     ""))

(defun trustrail--package-maintainer (desc)
 "Return the maintainer string from package DESC."
 (let ((extras (and desc (package-desc-extras desc))))
   (if extras
       (let ((maint (cdr (assq :maintainer extras))))
         (cond
          ((null maint) "")
          ((stringp maint) maint)
          ((consp maint) (or (car maint) ""))
          (t "")))
     "")))

(defun trustrail--package-url (desc)
 "Return the homepage URL from package DESC."
 (let ((extras (and desc (package-desc-extras desc))))
   (or (and extras (cdr (assq :url extras)))
       "")))

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
        (source (trustrail--package-source name config-set dep-set desc))
        (archive (trustrail--package-archive desc))
        (maintainer (trustrail--package-maintainer desc))
        (url (trustrail--package-url desc)))
   (list name
         (vector name version source archive maintainer summary url dir))))

;;;###autoload
(define-derived-mode trustrail-package-list-mode tabulated-list-mode "TrustRail Packages"
 "Major mode for listing installed Emacs packages.

\\{trustrail-package-list-mode-map}"
 (setq tabulated-list-format
       [("Package" 28 t)
        ("Version" 14 t)
        ("Source" 12 t)
        ("Archive" 12 t)
        ("Maintainer" 24 t)
        ("Summary" 48 t)
        ("URL" 40 t)
        ("Directory" 60 t)])
 (setq tabulated-list-padding 2)
 (setq tabulated-list-sort-key (cons "Package" nil))
 (setq-local trustrail--filter-string nil)
 (setq-local trustrail--all-entries nil)
 (tabulated-list-init-header))

(defvar-local trustrail--filter-string nil
 "Current filter substring applied to the package list.")

(defvar-local trustrail--all-entries nil
 "Unfiltered list of all tabulated entries.")

(defun trustrail--apply-filter ()
 "Apply `trustrail--filter-string' to narrow visible entries."
 (setq tabulated-list-entries
       (if (or (null trustrail--filter-string)
               (string-empty-p trustrail--filter-string))
           trustrail--all-entries
         (let ((pattern (downcase trustrail--filter-string)))
           (seq-filter
            (lambda (entry)
              (let ((vec (cadr entry)))
                (or (string-match-p pattern (downcase (aref vec 0)))
                    (string-match-p pattern (downcase (aref vec 5))))))
            trustrail--all-entries))))
 (tabulated-list-print t))

(defun trustrail-refresh ()
 "Rebuild the package list from scratch."
 (interactive)
 (let* ((config-set (trustrail--configured-packages))
        (dep-set (trustrail--dependency-set))
        (entries (mapcar (lambda (pkg)
                           (trustrail--tabulated-entry pkg config-set dep-set))
                         (trustrail--installed-packages))))
   (setq trustrail--all-entries entries)
   (trustrail--apply-filter)
   (message "TrustRail: %d packages" (length trustrail--all-entries))))

(defun trustrail-filter (pattern)
 "Filter the package list by PATTERN (matches name or summary)."
 (interactive "sFilter (name/summary): ")
 (setq trustrail--filter-string pattern)
 (trustrail--apply-filter)
 (message "TrustRail: showing %d/%d packages"
          (length tabulated-list-entries)
          (length trustrail--all-entries)))

(defun trustrail-filter-clear ()
 "Clear the active filter and show all packages."
 (interactive)
 (setq trustrail--filter-string nil)
 (trustrail--apply-filter)
 (message "TrustRail: filter cleared"))

(defun trustrail--current-package-name ()
 "Return the package name on the current line."
 (let ((entry (tabulated-list-get-entry)))
   (when entry (aref entry 0))))

(defun trustrail-describe-package ()
 "Describe the package on the current line."
 (interactive)
 (let ((name (trustrail--current-package-name)))
   (if name
       (describe-package (intern name))
     (user-error "No package on this line"))))

(defun trustrail-open-directory ()
 "Open the install directory of the package on the current line."
 (interactive)
 (let ((entry (tabulated-list-get-entry)))
   (if entry
       (let ((dir (aref entry 7)))
         (if (and dir (not (string-empty-p dir)) (file-directory-p dir))
             (dired dir)
           (user-error "No valid directory for this package")))
     (user-error "No package on this line"))))

(defun trustrail-visit-homepage ()
 "Open the homepage of the package on the current line."
 (interactive)
 (let ((name (trustrail--current-package-name)))
   (if name
       (let* ((desc (cadr (assq (intern name) package-alist)))
              (extras (and desc (package-desc-extras desc)))
              (url (cdr (assq :url extras))))
         (if (and url (not (string-empty-p url)))
             (browse-url url)
           (user-error "No homepage URL for %s" name)))
     (user-error "No package on this line"))))

(define-key trustrail-package-list-mode-map (kbd "g") #'trustrail-refresh)
(define-key trustrail-package-list-mode-map (kbd "/") #'trustrail-filter)
(define-key trustrail-package-list-mode-map (kbd "C") #'trustrail-filter-clear)
(define-key trustrail-package-list-mode-map (kbd "RET") #'trustrail-describe-package)
(define-key trustrail-package-list-mode-map (kbd "d") #'trustrail-open-directory)
(define-key trustrail-package-list-mode-map (kbd "h") #'trustrail-visit-homepage)

;;;###autoload
(defun trustrail-list-packages ()
 "List installed Emacs packages in a TrustRail buffer."
 (interactive)
 (let* ((buffer (get-buffer-create trustrail-buffer-name))
        (config-set (trustrail--configured-packages))
        (dep-set (trustrail--dependency-set))
        (entries (mapcar (lambda (pkg)
                           (trustrail--tabulated-entry pkg config-set dep-set))
                         (trustrail--installed-packages))))
   (with-current-buffer buffer
     (trustrail-package-list-mode)
     (setq trustrail--all-entries entries)
     (trustrail--apply-filter))
   (pop-to-buffer buffer)))

(provide 'trustrail)

;;; trustrail.el ends here
