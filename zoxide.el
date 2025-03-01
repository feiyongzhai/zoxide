;;; zoxide.el -- alternative to fasd.el for cross-platform

;;; Requirements:

;; `zoxide' command line tool, see: https://github.com/ajeetdsouza/zoxide

;;; Commentary:

;; `zoxide' 只可以记录目录，`fasd' 不仅可以记录目录，还可以记录文件，不过从 `fasd' 的使用来看
;; 只记录目录已经够用了

;;; Code:

(defcustom zoxide-add-file-to-db-when-eshell t
  "Whether enable zoxide db update when eshell directory changes"
  :type 'boolean)

(defgroup zoxide nil
  "Navigate previously-visited files and directories easily"
  :group 'tools
  :group 'convenience)

(defcustom zoxide-file-manager 'dired
  "A default set of file managers to use with `zoxide-find-file'"
  :type '(radio
          (const :tag "Use `dired', default emacs file manager" dired)
          (const :tag "Use `deer', ranger's file manager" deer)
          (function :tag "Custom predicate")))

;;;###autoload
(defun zoxide-add-directory-to-db ()
  "Add current directory to the Zoxide database."
  (if (not (executable-find "zoxide"))
      (message "Zoxide executable cannot be found. It is required by `zoxide.el'. Cannot add directory to the zoxide db")
    (let ((file (cond ((string= major-mode "eshell-mode")
		       default-directory)
		      ((string= major-mode "dired-mode")
		       ;; must expand file name, otherwise zoxide add will not work
		       (expand-file-name dired-directory))
		      (t
		       default-directory))))
      (when (and file
                 (stringp file)
                 (file-readable-p file))
        (start-process "*zoxide*" nil "zoxide" "add" file)))))

;;;###autoload
(defun zoxide-delete-file-from-db (file)
  ;; This command not used yet
  (start-process "*zoxide*" nil "zoxide" "remove" file))

;;;###autoload
(define-minor-mode global-zoxide-mode
  "Toggle zoxide mode globally.
   With no argument, this command toggles the mode.
   Non-null prefix argument turns on the mode.
   Null prefix argument turns off the mode."
  :global t
  :group 'zoxide

  (if global-zoxide-mode
      (progn (add-hook 'find-file-hook 'zoxide-add-directory-to-db)
             (add-hook 'dired-mode-hook 'zoxide-add-directory-to-db)
	     (when zoxide-add-file-to-db-when-eshell
	       (add-hook 'eshell-directory-change-hook 'zoxide-add-directory-to-db)))
    (remove-hook 'find-file-hook 'zoxide-add-directory-to-db)
    (remove-hook 'dired-mode-hook 'zoxide-add-directory-to-db)
    (remove-hook 'eshell-directory-change-hook 'zoxide-add-directory-to-db)))

;; @REF https://0x709394.me/Fasd%E4%B8%8E-Eshell%E7%9A%84%E4%B8%8D%E6%9C%9F%E8%80%8C%E9%81%87
(defun eshell/z (&rest args)
  "Use zoxide to change directory more effectively by passing ARGS."
  (setq args (eshell-flatten-and-stringify args))
  (let* ((zoxide (concat "zoxide query " args))
	 (zoxide-result (shell-command-to-string zoxide))
	 (path (replace-regexp-in-string "\n$" "" zoxide-result)))
    (and (or (eq system-type 'ms-dos) (eq system-type 'windows-nt))
	 ;; 因为 windows 下有的时候可以正确解释为 utf-8 ，有的时候不可以，为 gbk
	 ;; 思路：为 gbk 编码的时候，转换成 utf-8，为 utf-8 则不操作
	 (text-property-any 0 (1- (length path)) 'charset 'chinese-gbk path)
	 (setq path (decode-coding-string
		     (encode-coding-string path 'gbk) 'utf-8)))
    (if (eq 0 (length args))
	(eshell/cd "-")
      (eshell/cd path)
      ;; (eshell/echo path)
      ;; https://emacs.stackexchange.com/questions/13698/eshell-print-only-works-when-called-from-eshell
      (eshell-commands (eshell-print "\neshell cd here!")) ;这是一个提醒：我希望我做了目录切换之后有一个提醒

      )))

(provide 'zoxide)

;; zoxide.el ends here
