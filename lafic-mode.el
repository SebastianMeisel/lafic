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
(puthash "view" "evince" lafic-command-hash)

(defvar lafic-command-file-association-list
  '(
    ("lafic2tex" . "lafic")
    ("lafic2html" . "lafic")
    ("lafic2pdf" . "lafic")
    ("evince" . "pdf")
    )
  "Association list of command and file extentions."
  )


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

(defvar lafic-parameter-list
  '(
    ;; figure
    "width" "height" "caption" 
    )
  "Keywords for parameters."
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

(defconst regex-parameter
  (concat "^%\\s *"
	  (regexp-opt lafic-parameter-list t)	  
	  "\\s =\\s *\\(.*?\\)"	  
	  "\\s *$"
	  )
  "Regex for parameter font lock."
  )


(defconst lafic-mode-font-lock-keywords
  (list
   ;; paragraph style
   (cons regex-environment 'font-lock-function-name-face)
   ;; line style
   (cons regex-macro 'font-lock-function-name-face)
   ;; inline macros
   (cons regex-il-macro '(0 'font-lock-comment-face t))
   (cons regex-il-macro '(1 'font-lock-constant-face t))
   (cons regex-il-macro '(2 'font-lock-function-name-face t))
   ;; parameters
   (cons regex-parameter '(0 'font-lock-comment-face t))
   (cons regex-parameter '(1 'font-lock-function-name-face t))
   (cons regex-parameter '(2 'font-lock-constant-face t))
   (cons "^%%\\(\\S \\|\\s \\)*?

" 'font-lock-comment-face)
   )
  "Syntax highlighting for LaFiC files."
)
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; functions
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; commands
(defun lafic-run ()
  "Run a command to convert the lafic file."
  (interactive)
  (save-buffer)
  (let ((format (completing-read "Output format: "
	      (mapcar 'list (hash-table-keys lafic-command-hash))
	      nil t nil 'lafic-command-history t)))
    (let ((program (gethash format lafic-command-hash))) 
      (async-shell-command (concat 
	   program
	   " "
	   (file-name-sans-extension (buffer-name))
	   "."
	   (cdr (assoc program lafic-command-file-association-list))
	)
	(concat 
	 "*"
	 (file-name-sans-extension (buffer-name))
	 ".output*"
	 )
	(concat 
	 "*"
	 (file-name-sans-extension (buffer-name))
	 ".error*"
	 )
	)
      )
    )
  )

;; formation
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

;; highlighting

(defun lafic-highlight-par ()
  "Highlight inline formations for paragrah at point"
  (interactive)
  ;; TODO : make sure to omit line- / par-style line 
  (save-excursion
    ;; find start of paragraph 
    (re-search-backward "^\\s *?
\\(\\S \\)" nil t 1)
    (if (eq (match-string 1) "%")
	(re-search-forward "
\\(\\S \\)" nil t 1))
    ;; find end of paragraph
    (let ((par-start (- (match-end 0) 1)))
      (if (re-search-forward "
%" nil t 1)
	  (let ((par-end (- (match-beginning 0) 1)))
	    ;; clear up
	    (overlay-recenter par-start)
	    (remove-overlays par-start par-end)
	    ;; find end of format blocl
	    (re-search-forward "\\S 
\\s *?$" nil t 1)
	    (let ((formbl-end (- (match-end 0) 1))) 
	      (goto-char par-end)
	      ;; find words to format
	      ;; TODO: regions & context
	      (while (re-search-forward regex-il-macro
					formbl-end t )
		(let ((search-string (match-string 1)))
		  ;; move to content block
		  (save-excursion
		    (goto-char par-end)
		    ;; search string in content block
		    (while (re-search-backward search-string
					       par-start t)
		      (let ((start (match-beginning 0))
			    (end (match-end 0)))
			(let ((overlay (make-overlay start end)))
			  (overlay-put overlay 'face 'font-lock-constant-face)
			  ))))
		  ))
	      )))
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

(defun lafic-format-par-or-line ()
  "Define style for current paragraph."
  (interactive)
  (save-excursion
    (re-search-backward "^\\s *$" nil t)
    (newline)
    (insert "% ")
    (insert (completing-read "paragraph/line-style: "
	 (mapcar 'list (append lafic-environment-list lafic-macro-list))
	 nil nil nil 'lafic-macro-history t))
    )
  )


(defun lafic-format-word (&optional format)
  "Formate word at point." ;;or region."
  (interactive)
  (save-excursion
    (let (
	  (word (or ;;region or word at point
		 (if (and transient-mark-mode mark-active)
		     (let ((a (region-beginning))
			   (b (region-end)))
		   (concat
		    (save-excursion
		      (goto-char (+ a 1))
		      (word-at-point))
		    "…"
		    (save-excursion
		      (goto-char (- b 1))
		      (word-at-point))
		    )
		   ))
		 (word-at-point))
		)
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

(defun lafic-fill-paragraph ()
  "Fill paragraph at point"
  (interactive)
  (save-excursion
    (let ((start (+ 2 (re-search-backward "

"))))
    
    (let ((end (or(-(re-search-forward "
\\(%\\|
\\)" nil t 2) 1)
        (point-max))))
	(fill-region start end t)
	)
      )
    )
  )



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
    (define-key map "\C-c RET" 'lafic-format-word)
    ;
    (define-key map "\C-c\C-f\C-e" (lambda () (interactive)
	   (lafic-format-word "emphasize")))
    (define-key map "\C-c\C-f\C-i" (lambda () (interactive)
	   (lafic-format-word "italic")))
    (define-key map "\C-c\C-f\C-b" (lambda () (interactive)
	   (lafic-format-word "bold")))
    (define-key map "\C-c\C-f\C-c" (lambda () (interactive)
           (lafic-format-word "smallcaps")))
    ;; fill
    (define-key map "\C-c\C-q\C-p" 'lafic-format-word)
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
