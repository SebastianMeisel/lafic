;;; lafic-german-keywords.el --- German keyword for LaFiC

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

(defvar lafic-environment-list-de
  '(
    "zitat" "lzitat" "langzitat"
    ;; Zentriert
    "zentriert" "z"
    ;; Listen
    "aufzählung" "liste"
    ;;;;;;;;;;;;
    ;; Bilder 
    "bild"
    )
  "German Keywords for paragraph styles."
  )

(defvar lafic-macro-list-de
  '(
    "Ü1" "Überschrift1" "titel" 
    "Ü2" "Überschrift2" "teil" 
    "Ü3" "Überschrift3" "abschnit" 
    "Ü4" "Überschrift4" "unterabschnitt" 
    "Ü5" "Überschrift5" "h5" 
    "Ü6" "Überschrift6" "absatz" 
    "Ü"  "Überschrift" 
    )
  "German Keywords for line styles."
  )

(defvar lafic-inline-macro-list-de
  '(
    "fett" "hervorheben" "kursiv" 
    "schreibmaschine" "nicht proportional" 
    "kapitälchen" "hochgestellt" "tiefgestellt" 
    "siehe" "fußnote" 
    )
  "German Keywords for inline formations."
  )

(defvar lafic-keyword-list-de
  '(
    ;; line breaks
    "Zeilen umbrechen"
    )
  "Special German keywords."
)

(provide 'lafic-german-keywords)
