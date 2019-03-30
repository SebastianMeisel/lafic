;;; lafic.el --- Emacs Major mode for descriptive formated text

;;; Copyright (C) 2019 Sebastian Meisel <sebastian.meisel@gmail.com>

;;; Author: Sebastian Meisel <sebastian.meisel@gmail.com>
;;; Created: March 28, 2019
;;; Version: 0.1

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.


(require 'subr-x)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; custom variables
(defgroup lafic nil
  "Major mode for editing textfiles in lafic format."
  :prefix "lafic-"
  :group 'wp)

;; faces
(defface lafic-bold-face
  '((((class color)) (:foreground "yellow" :bold t)) (t (:bold t)))
  "Face used for a word accepted by Gspell."
  :group 'lafic)


;; command hash
(defvar lafic-command-hash
  (make-hash-table :test 'equal)
  "List of commands to convert lafic files to other formats"
  )

(puthash "tex" "lafic2tex" lafic-command-hash)
(puthash "html" "lafic2html" lafic-command-hash)
(puthash "pdf" "lafic2pdf" lafic-command-hash)



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; keyword hash
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defvar lafic-environment-list
  '(
    ;; quotes
    "quote" "quotation" 
    ;; center
    "center" "c" 
    ;; lists
    "enumerate" "ol" "itemize" "list" "ul"
    ;; figures 
    "image" "img" "figure"
    ;; verbatim
    "verbatim" "verb"
    )
  "Keywords for paragraph styles."
  )

(defvar lafic-macro-list
  '(
    "h1" "heading1" "title"
    "h2" "heading2" "part"
    "h3" "heading3" "section"
    "h4" "heading4" "subsection"
    "h5" "heading5" "subsubsection"
    "h6" "heading6" "paragraph"
    "h" "heading"
    )
  "Keywords for line styles."
  )

(defvar lafic-inline-macro-list
  '(
    "bold" "emphasize" "italic" "smallcaps" 
    "superscript" "subscript"
    )
  "Keywords for inline formats."
)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; font lock regex
(defconst regex-environment
  (concat "^%\\s *"
	  (regexp-opt lafic-environment-list t)
	  "\\s *$"
	  )
  "Regex for environment font lock."
  )

(defconst regex-macro
  (concat "^%\\s *"
	  (regexp-opt lafic-macro-list t)	  
	  "\\s *$"
	  )
  "Regex for macro font lock."
  )

(defconst regex-il-macro
  (concat "^%\\s *"
	  "\\(.*?\\):\\s *"	  
	  (regexp-opt lafic-inline-macro-list t)	  
	  "\\s *$"
	  )
  "Regex for inline macros font lock."
  )


(defconst lafic-mode-font-lock-keywords
  (list
   (cons regex-environment 'font-lock-function-name-face)
   (cons regex-macro 'font-lock-function-name-face)
   (cons regex-il-macro '(0 'font-lock-comment-face t))
   (cons regex-il-macro '(1 'font-lock-constant-face t))
   (cons regex-il-macro '(2 'font-lock-function-name-face t))
   (cons "^%%\\(\\S \\|\\s \\)*?

" 'font-lock-comment-face)
   )
  "Syntax highlighting for LaFiC files."
)
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; functions
(defun lafic-run ()
  "Run a command to convert the lafic file."
  (interactive)
  (async-shell-command (concat
	(gethash
	 (completing-read "Output format: "
	      (mapcar 'list (hash-table-keys lafic-command-hash))
	      nil t nil 'lafic-command-history t)
	 lafic-command-hash)
	" " (buffer-name)))
  )

(defun lafic-format-par ()
  "Define style for current paragraph."
  (interactive)
  (save-excursion
    (re-search-backward "^\\s *$" nil t)
    (newline)
    (insert "% ")
    (insert (completing-read "paragraph-style: "
	 (mapcar 'list lafic-environment-list)
	 nil nil nil 'lafic-environment-history t))
    ))

(defun lafic-format-line ()
  "Define style for current paragraph."
  (interactive)
  (save-excursion
    (re-search-backward "^\\s *$" nil t)
    (newline)
    (insert "% ")
    (insert (completing-read "line-style: "
	 (mapcar 'list lafic-macro-list)
	 nil nil nil 'lafic-macro-history t))
    ))


(defun lafic-format-word (&optional format)
  "Formate word at point." ;;or region."
  (interactive)
  (save-excursion
    (let (
	   (word (word-at-point))
	   )
    (re-search-forward "^\\s *?$" nil t)
    (insert "% ")
    (insert word)
    (insert ": ")
    (insert (or format
	     (completing-read "word-style: "
		  (mapcar 'list lafic-inline-macro-list)
		  nil nil nil 'lafic-inline-macro-history t)
	     ))
    (newline)
    )))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; mode definition
(defvar lafic-mode-hook nil)

(defvar lafic-mode-map
  (let ((map (make-keymap "lafic")))
    ;; run commands
    (define-key map "\C-c\C-c" 'lafic-run)    
    ;; format paragraphs
    (define-key map "\C-c\C-p" 'lafic-format-par)
    ;; format lines
    (define-key map "\C-c\C-l" 'lafic-format-line)
    ;; format word (/ regions)
    (define-key map "\C-c\C-w" 'lafic-format-word)
    (define-key map "\C-c\C-f\C-e" (lambda () (interactive)
	   (lafic-format-word "emphasize")))
    (define-key map "\C-c\C-f\C-i" (lambda () (interactive)
	   (lafic-format-word "italic")))
    (define-key map "\C-c\C-f\C-b" (lambda () (interactive)
	   (lafic-format-word "bold")))
    (define-key map "\C-c\C-f\C-b" (lambda () (interactive)
	   (lafic-format-word "smallcaps")))
    map)
  "Keymap for Descriptiv Formated Text major mode")

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.lafic\\'" . lafic-mode))

(defun lafic-mode ()
  "Major mode for editing Descriptiv Formated Text files"
  (interactive)
  (kill-all-local-variables)
  ;;  (set-syntax-table wpdl-mode-syntax-table)
  ;; Comments or Formating
  (setq-local comment-start "% ")
  (setq-local comment-end "
")
  ;; Font lock
  (set (make-local-variable 'font-lock-defaults)
       '(lafic-mode-font-lock-keywords))
  (set (make-local-variable 'font-lock-multiline) t)
  ;;
  ;; Keymap 
  (use-local-map lafic-mode-map)
  ;; Major Mode
  (setq major-mode 'lafic-mode)
  (setq mode-name "LAFIC")
  (run-hooks 'lafic-mode-hook)
  )

(provide 'lafic-mode)
