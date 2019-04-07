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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; internalt functions


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; custom variables
(defgroup lafic nil
  "Major mode for editing textfiles in lafic format."
  :prefix "lafic-"
  :group 'wp)

;; lafic path
(defcustom lafic-path
  "~/lafic/"
  "Path to lafic directory"
  :group 'lafic)

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

(defvar lafic-template-list
  '()
  "List of templates"
  )
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; font lock regex
;; templates
(defun lafic-get-template-name-list ()
  "Get a list of installed templates"
  (let ((temp-list
	 (directory-files-and-attributes lafic-path nil
					 ".*\\.tmp\\.tex")))
    (while temp-list
      (setq lafic-template-list
	    (cons (car (split-string (car (car temp-list)) "\\." t))
		  lafic-template-list))
      (setq temp-list (cdr temp-list))
      )))

(lafic-get-template-name-list)

(defconst regex-template
  (concat "^%\\s *"
	  (regexp-opt lafic-template-list t)
	  "\\s *$"
	  )
  "Regex for template font lock."
  )

(defconst regex-environment
  (concat "^%\\s *"
	  (regexp-opt lafic-environment-list t)
	  "\\s *$"
	  )
  "Regex for environment font lock."
  )

(defconst regex-unknown-line-style
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

(defconst regex-unknown-line-style
  (concat "^%\\s *"
	  "\\([[:alpha:][:digit:]]+\\)"
	  "\\s *$"
	  )
  "Regex for unknown templates / environments / macro warning."
  )


(defconst regex-il-macro
  (concat "^%\\s *"
	  "\\(.*?\\)\\s *:\\s *"	  
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

(defconst regex-unknown-il-macro
  (concat "^%\\s *"
	  "\\(.*?\\):\\s *"
	  "\\([[:alpha:][:digit:]]+\\)"
	  "\\s *$"
	  )
  "Regex for unknown inline formation keywords."
  )

(defconst regex-unknown-parameter
  (concat "^%\\s *"
	  "\\([[:alpha:][:digit:]]+\\)"
	  "\\s *=\\s *\\(.*?\\)"
	  "\\s *$"
	  )
  "Regex for unknown parameter keywords."
  )

(defconst lafic-mode-font-lock-keywords
  (list
   ;; templates
   (cons regex-template 'font-lock-function-name-face)
   ;; paragraph style
   (cons regex-environment 'font-lock-function-name-face)
   ;; line style
   (cons regex-macro 'font-lock-function-name-face)
   ;; unknown template / paragraph or line style
   (cons regex-unknown-line-style 'font-lock-warning-face)
   ;; unknow inline macros
   (cons regex-unknown-il-macro '(1 'font-lock-constant-face t))
   (cons regex-unknown-il-macro '(2 'font-lock-warning-face t))
   ;; unknow inline macros
   (cons regex-unknown-il-macro '(1 'font-lock-constant-face t))
   (cons regex-unknown-il-macro '(2 'font-lock-warning-face t))
   ;; inline macros
   (cons regex-il-macro '(1 'font-lock-constant-face t))
   (cons regex-il-macro '(2 'font-lock-function-name-face t))
   ;; unknown parameters
   (cons regex-unknown-parameter '(1 'font-lock-warning-face t))
   (cons regex-unknown-parameter '(2 'font-lock-constant-face t))
   ;; parameters
   (cons regex-parameter '(1 'font-lock-function-name-face t))
   (cons regex-parameter '(2 'font-lock-constant-face t))
   ;; format lines
   (cons "^%.*$" 'font-lock-comment-face)
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
	))
    ))

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
    )
  )

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
    )
  )


(defun lafic-format-word (&optional format)
  "Formate word at point." ;;or region."
  (interactive)
  (save-excursion
    (let ((word (if (and transient-mark-mode mark-active)
		    (let ((a (region-beginning))
			  (b (region-end)))
		      (goto-char (+ a 1))
		      (let ((word-a (thing-at-point 'word t)))
			(goto-char (- b 1))
			(let ((word-b (thing-at-point 'word t)))
			  (if (string= word-a word-b)
			      word-a
			    (concat
			     word-a "…" word-b)))))
		      (thing-at-point 'word t)
		      )))
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
    ))
  )

(defun lafic-delete-formation-at-point ()
  "Delete all formations for the current position."
  (interactive)
  (save-excursion
    (let ((overlays (overlays-at (point))))
      (while overlays
	(let ((overlay (car overlays)))
	  (let ((a (+ (overlay-start overlay) 1))
		(b (- (overlay-end overlay) 1)))
	    ;; First word of overlay
	    (goto-char a)
	    (let ((word-a (thing-at-point 'word t)))
	      ;; Last word of overlay
	      (goto-char b)
	      (let ((word-b (thing-at-point 'word t)))
		(let ((search-string
		       (concat
			;; check for context
			"^%\\s *\\((.*?)\\)?\\s *"
			;; Just on word?
			;; TODO: What if equal word 
			;;       but not the same?
			(if (string= word-a word-b)
			    word-a
			  (concat
			   word-a "…" word-b))
			"\\s *:")))
		  (if (re-search-forward search-string nil t)
		      (progn
			(goto-char (match-beginning 0))
			(kill-line 1)))
		)))
	    ))
	(setq overlays (cdr overlays))
	))))

;; context
(defun lafic-add-leading-context ()
  "Add leading context for a formated word, to make it unique in the paragraph."
  (interactive)
  (save-excursion
    (if ;; If region is selected …
	(and transient-mark-mode mark-active) 
	(progn 
	  (setq region-string (buffer-substring-no-properties (region-beginning) (region-end)))
	  ;; …the last word must be formated
	  (string-match "\\s *\\(\\w*\\)$" region-string)
	  (setq last-word (match-string-no-properties 1 region-string))
	  ;; … and the rest of the region is context. 
	  (setq region-string (replace-regexp-in-string "\\s *\\(\\w*\\)$" "" region-string))
 
	)
      (right-char);; make sure we're not at the first letter of word
      )
    (let ((word (or last-word
		 (thing-at-point 'word t))))
      (left-word 2)
      (let ((context (or region-string
		      (thing-at-point 'word t)))
	    (hier (point))
	    )
	;; find end of paragraph 
	(let ((end-par 
	       (or (re-search-forward
		    "\\S 
\\s *?$" nil t 1)
		   (point-max))))
	      (goto-char hier)
	      (if ;; search for format line for word
		  (re-search-forward
		   (concat
		    "^%\\s *\\("
		    word
		    "\\)\\s *:")
		   end-par t)
		  ;; Place point before word.
		  (progn
		    (goto-char (match-beginning 1))
		    (insert (concat
			     "(" context ") "))
		    ))
	      )))
      ))

(defun lafic-add-trailing-context ()
  "Add trailing context for a formated word, to make it unique in the paragraph."
  (interactive)
  (save-excursion
    (right-char);; make sure we're not at the first letter of word
    (let ((word (thing-at-point 'word t)))
      (right-word 2)
      (let ((context (thing-at-point 'word t))
	    (hier (point))
	    )
	;; find end of paragraph 
	(let ((end-par 
	       (or (re-search-forward
		    "\\S 
\\s *?$" nil t 1)
		   (point-max))))
	      (goto-char hier)
	      (if ;; search for format line for word
		  (re-search-forward
		   (concat
		    "^%\\s *\\("
		    word
		    "\\)\\s *:")
		   end-par t)
		  ;; Place point after word.
		  (progn
		    (goto-char (match-end 1))
		    (insert (concat
			     " (" context ")"))
		    ))
	      )))
      ))


;; highlighting
(defun lafic-highlight-par ()
  "Highlight inline formations for paragrah at point"
  (interactive)
  (save-excursion
    ;; One step forward to find the beginning of line.
    (right-char)
    ;; find start of paragraph 
    (re-search-backward "^\\s *
\\(\\S \\)" nil t 1)
    ;;  omit line- / par-style line 
    (if (eq (match-string-no-properties 1) "%")
	(re-search-forward "
\\(\\S \\)" nil t 1))
    (let ((par-start (- (match-end 0) 1)))
    ;; find end of paragraph
      (if (re-search-forward "
%" nil t 1)
	  (let ((par-end (- (match-beginning 0) 1)))
	    ;; prevent to skip to next par / line
	    (or
	     (unless (>
		     (re-search-backward "\\S 
\\s *$" nil t 1) par-start)
	      (goto-char par-end)
	      ;; clear up
	      (overlay-recenter par-start)
	      (remove-overlays par-start par-end)
	      ;; find end of format block
	      (re-search-forward "\\S \\s *
\\s *$" nil t 1)
	      (let ((formbl-end (- (match-end 0) 1))) 
		(goto-char par-end)
		;; find words to format
		;; TODO: regions & context
		(while (re-search-forward regex-il-macro
					  formbl-end t )
		  ;; not yet found any context
		  (setq context 0) 
		  (let ((search-string (match-string-no-properties 1)))
		    (let ((regex
			   (or ;; region or single word
			    (if ;; region
				(string-match
				 "\\(.*?\\)\\(…\\|\\.\\{3,3\\}\\)\\(.*\\)" search-string)
				(concat (match-string-no-properties 1 search-string)
					".*
*.*";; make sure to include possible line break
					(match-string-no-properties 3 search-string)))
			    (or ;; single word
			     (cond ;; check for context
			      ((string-match ;; leading context
				"^\\s *(\\(.*?\\))\\s *\\(.*?\\)\\s *$"
				search-string)
			       (setq context 1)
			       (concat
				"\\(?:"
				(match-string-no-properties 1 search-string)
				"\\)
?\\W *\\("
				(match-string-no-properties 2 search-string)
				"\\)")
			       )
			      ((string-match ;; trailing context
				"^\\s *\\(.*?\\)\\s *(\\(.*?\\))\\s *$"
				search-string)
			       (setq context 2)
			       (concat
				"\\("
				(match-string-no-properties 1 search-string)
				"\\)
?\\W *\\(?:"
				(match-string-no-properties 2 search-string)
				"\\)"
				)
			       ))
			     search-string))))
		      ;; move to content block
		      (save-excursion
			(goto-char (+ par-end 1))
			;; search string in content block
			(while (re-search-backward regex
						   par-start t)
			  (let ((start
				 (or
				  (cond
				   ((= context 1)
				    (match-beginning 1))
				   ((= context 2)
				    (match-beginning 1)))
				  (match-beginning 0)))
				(end
				 (or
				  (cond
				   ((= context 1)
				    (match-end 1))
				   ((= context 2)
				    (match-end 1)))
				  (match-end 0)))
				)
			    (let ((overlay (make-overlay start end)))
			      (overlay-put overlay 'face 'font-lock-constant-face)
	



			    ))))
		    )))
		)t) ;; if no format block found, just clean up
	      (remove-overlays par-start par-end)))
	))))
  
(defun lafic-highlight-buffer ()
  "Highlight inline formations for the whole buffer"
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (while (re-search-forward "^.*
\\S*" nil t 1)
      (lafic-highlight-par)
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
    (define-key map [?\C-c return] 'lafic-format-word)
    ;
    (define-key map "\C-c\C-f\C-e" (lambda () (interactive)
	   (lafic-format-word "emphasize")))
    (define-key map "\C-c\C-f\C-i" (lambda () (interactive)
	   (lafic-format-word "italic")))
    (define-key map "\C-c\C-f\C-b" (lambda () (interactive)
	   (lafic-format-word "bold")))
    (define-key map "\C-c\C-f\C-c" (lambda () (interactive)
	   (lafic-format-word "smallcaps")))
    (define-key map "\C-c\C-f\C-t" (lambda () (interactive)
	   (lafic-format-word "mono")))
    ;
    (define-key map "\C-c\C-f\C-d" 'lafic-delete-formation-at-point)
    ;; add context
    (define-key map [?\C-c C-left] 'lafic-add-leading-context)
    (define-key map [?\C-c C-right] 'lafic-add-trailing-context)
    ;; fill
    (define-key map "\C-c\C-q\C-p" 'lafic-format-word)
    ;; highlighting
    (define-key map "\C-c\C-h\C-p" 'lafic-highlight-par)
    (define-key map "\C-c\C-h\C-b" 'lafic-highlight-buffer)
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
  ;; highlighting
  (unless (< (buffer-size) 50) (lafic-highlight-buffer))
  (add-hook 'post-command-hook 'lafic-highlight-par t t)
  ;; Font lock
  (set (make-local-variable 'font-lock-defaults)
       '(lafic-mode-font-lock-keywords))
  (set (make-local-variable 'font-lock-multiline) t)
  ;; Keymap 
  (use-local-map lafic-mode-map)
  ;; Major Mode
  (setq major-mode 'lafic-mode)
  (setq mode-name "LAFIC")
  (run-hooks 'lafic-mode-hook)
  )


(provide 'lafic-mode)
