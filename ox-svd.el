;;; ox-svd.el --- CMSIS System View Description Back-End for Org Export Engine

;; Copyright (C) 2023 Space Cubics, LLC.

;; Author: Yasushi SHOJI <yashi@spacecubics.com>
;; URL: https://github.com/yashi/org-svd
;; Package-Requires: ((org "8.1"))
;; Keywords: org, svd

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This library implements an SVD back-end for Org exporter.
;;
;; It provides two commands for export, depending on the desired
;; output: `org-svd-export-as-svd' (temporary buffer) and
;; `org-svd-export-to-svd' (file).

;;; Code:
(require 'ox)
(require 'cl-lib)
(require 'ox-html)
(require 'ox-publish)
(require 'simple)
(require 'replace)

(defgroup org-export-svd nil
  "Options for exporting Org mode files to SVD."
  :tag "Org Export SVD"
  :group 'org-export)

(org-export-define-backend 'svd
  '(
    (headline . org-svd-headline)
    (section . org-svd-identity)
    (table . org-svd-table)
    (table-cell . org-svd-table-cell)
    (table-row . org-svd-table-row)
    (template . org-svd-template))
  :options-alist
  '((:headline-levels nil nil 4 t))
  :menu-entry
  '(?s "Export to SVD"
       ((?s "As SVD buffer"
	    (lambda (a s v b) (org-svd-export-as-svd a s v)))
	(?S "As SVD file"
	    (lambda (a s v b) (org-svd-export-to-svd a s v)))
	(?o "As SVD file and open"
	    (lambda (a s v b)
	      (if a (org-svd-export-to-svd t s v)
		(org-open-file (org-svd-export-to-svd nil s v))))))))

;;; Identity
(defun org-svd-identity (blob contents info)
  "Transcode BLOB element or object back into Org syntax.
CONTENTS is its contents, as a string or nil.  INFO is ignored."
  (org-export-expand blob contents))


;;; Head Line

;; replace space to undersore
(defun org-svd-make-valid-name (name)
  (replace-regexp-in-string "[ -]" "_" (replace-regexp-in-string " *(.*)" "" name)))

(defun org-svd-headline (headline contents info)
  "Transcode HEADLINE element into SVD format.
CONTENTS is the headline contents."
  (let* ((level (org-export-get-relative-level headline info))
         (title (org-export-data (org-element-property :title headline) info))
         (name (org-export-data (org-element-property :title headline) info))
         (version (org-export-data(org-element-property :VERSION headline) info))
         (base (org-export-data (org-element-property :BASE_ADDRESS headline) info))
         (first-content "testing 1 2 3")
         (size (org-export-data (org-element-property :SIZE headline) info)))
    (cond ((eql level 1)
           (concat "<peripheral>\n"
                   "<name>" (org-svd-make-valid-name name) "</name>\n"
                   "<version>" version "</version>\n"
                   "<description>" first-content "</description>\n"
                   "<baseAddress>" base "</baseAddress>\n"
                   "<addressBlock>\n"
                   "<offset>0</offset>\n"
                   "<size>" size "</size>\n"
                   "<usage>registers</usage>\n"
                   "</addressBlock>\n"
                   "<registers>\n"
                   contents
                   "</registers>\n"
                   "</peripheral>\n"))
          ((and (eql level 2) (string= title "レジスタ詳細"))
           contents)
          ((and (eql level 3))
           contents))))


;;; Table
(defun org-svd-table-register (table contents info)
  (let* ((header (and (org-export-table-has-header-p table info) "header"))
         (pgwide (and (org-export-read-attribute :attr_svd table :pgwide) "pgwide"))
         (options (remq nil (list header pgwide))))
    contents))

(defun org-svd-table-register-field (table contents info)
  (let* ((header (and (org-export-table-has-header-p table info) "header"))
         (pgwide (and (org-export-read-attribute :attr_svd table :pgwide) "pgwide"))
         (options (remq nil (list header pgwide)))
         (register (pop org-svd-register-list)))
    (concat "<register>\n"
            register
            "<fields>\n"
	    contents
	    "</fields>\n"
            "</register>\n"
            )))

(defun org-svd-table (table contents info)
  "Transcode TABLE element into SVD format."
  (let* ((parent (org-export-get-parent-headline table))
         (level (org-export-get-relative-level parent info)))
    (cond ((eql level 2)
           (org-svd-table-register table contents info))
          ((eql level 3)
           (org-svd-table-register-field table contents info)))))

(setq org-svd-register-list ())

(defun org-svd-table-row-register (table-row contents info)
  (let ((header (org-export-table-row-in-header-p table-row info))
        (special (org-export-table-row-is-special-p table-row info))
        (group (org-export-table-row-group table-row info)))
    (when (eql group 2)
      (let ((lines (concat
                    (with-temp-buffer
                      (insert (org-no-properties contents))
                      (beginning-of-buffer)
                      (flush-lines "^$")
                      (beginning-of-buffer)
                      (transpose-lines 2)
                      (buffer-string)))))
        (add-to-list 'org-svd-register-list lines t)
        ""))))

(defun org-svd-table-row-register-field (table-row contents info)
  (let ((header (org-export-table-row-in-header-p table-row info))
        (special (org-export-table-row-is-special-p table-row info))
        (group (org-export-table-row-group table-row info)))
    (when (eql group 2)
      (let ((lines (with-temp-buffer
                     (insert (org-no-properties contents))
                     (beginning-of-buffer)
                     (flush-lines "^$")
                     (beginning-of-buffer)
                     (transpose-lines 2)
                     (buffer-string))))
        (concat
         "<field>\n"
         lines
         "</field>\n")))))

(defun org-svd-table-row (table-row contents info)
  "Transcode TABLE ROW element into SVD format."
  (let* ((parent (org-export-get-parent-headline table-row))
         (level (org-export-get-relative-level parent info)))
    (cond ((eql level 2)
           (org-svd-table-row-register table-row contents info))
          ((eql level 3)
           (concat
            (org-svd-table-row-register-field table-row contents info))))))

(defun org-svd-table-cell-register (table-cell contents info)
  (let* ((row (car (org-export-table-cell-address table-cell info)))
         (col (cdr (org-export-table-cell-address table-cell info)))
         (table-row (org-export-get-parent table-cell))
         (header (org-export-table-row-starts-header-p table-row info))
         (table (org-export-get-parent-table table-cell))
         (col-header-cell (org-export-get-table-cell-at (cons 0 col) table info))
         (col-header (org-no-properties (car (org-element-contents col-header-cell)))))
    (cond ((string= col-header "Offset")
           (concat "<addressOffset>" contents "</addressOffset>\n"))
          ((string= col-header "Symbol")
           (concat "<name>" (org-svd-make-valid-name contents) "</name>\n"))
          ((string= col-header "Register")
           (concat "<description>" contents "</description>\n")))))

(defun org-svd-table-cell-field (table-cell contents info)
  (let* ((row (car (org-export-table-cell-address table-cell info)))
         (col (cdr (org-export-table-cell-address table-cell info)))
         (table-row (org-export-get-parent table-cell))
         (header (org-export-table-row-starts-header-p table-row info))
         (table (org-export-get-parent-table table-cell))
         (col-header-cell (org-export-get-table-cell-at (cons 0 col) table info))
         (col-header (org-no-properties (car (org-element-contents col-header-cell)))))
    (cond ((string= col-header "bit")
           (let ((str (if (string-match ":" contents) contents
                        (concat contents ":" contents))))
            (concat "<bitRange>[" str  "]</bitRange>\n")))
          ((string= col-header "Symbol")
           (concat "<name>" (org-svd-make-valid-name contents) "</name>\n"))
          ((string= col-header "R/W")
           (concat
            (cond ((string= contents "RO") "<access>read-only</access>")
                  ((string= contents "WO") "<access>write-only</access>")
                  ((string= contents "R/W") "<access>read-write</access>"))
            "\n"))
          ((string= col-header "Description")
           (concat "<description>" contents "</description>\n")))))

(defun org-svd-table-cell (table-cell contents info)
  "Transcode TABLE CELL element into SVD format."
  (let* ((parent (org-export-get-parent-headline table-cell))
         (level (org-export-get-relative-level parent info)))
    (cond ((eql level 2)
           (org-svd-table-cell-register table-cell contents info))
          ((eql level 3)
           (org-svd-table-cell-field table-cell contents info)))))

(defun org-svd-section (section contents info)
  (let* ((parent (org-export-get-parent-headline section))
         (level (org-export-get-relative-level parent info)))
    (cond ((eql level 2)
           contents)
          ((eql level 3)
           (concat
            contents)))))


;;; Template
(defun org-svd-make-withkey (key)
  (intern (concat ":with-" (substring (symbol-name key) 1))))

(defun org-svd-info-get-with (info key)
  "wrapper accessor to the communication channel.  Return the
  value if and only if \"with-key\" is set to t."
  (let ((withkey (org-svd-make-withkey key)))
    (and withkey
	 (plist-get info withkey)
	 (org-export-data (plist-get info key) info))))

(defun org-svd-info-get (info key)
  (org-export-data (plist-get info key) info))


(defun org-svd-template--opening (info)
  (let ((title (org-svd-info-get info :title))
	(author (org-svd-info-get-with info :author))
	(email (org-svd-info-get-with info :email))
        (date (org-svd-info-get-with info :date))
        (docinfo (plist-get info :svd-docinfo))
	(latex-transcoder (plist-get info :svd-latex)))
    (concat
     "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n"
     "<device schemaVersion=\"1.1\" xmlns:xs=\"https://raw.githubusercontent.com/ARM-software/CMSIS/master/CMSIS/Utilities/CMSIS-SVD.xsd\">\n"
     "<vendor>Space Cubics</vendor>\n"
     "<vendorID>SC</vendorID>\n"
     "<name>SC_OBC_FPGA</name>\n"
     "<series>ARMCM3</series>\n"
     "<version>1.2</version>\n"
     "<description>" title "</description>\n"
     "<cpu>\n"
     "<name>CM3</name>\n"
     "<revision>r1p0</revision>\n"
     "<endian>little</endian>\n"
     "<mpuPresent>true</mpuPresent>\n"
     "<fpuPresent>false</fpuPresent>\n"
     "<nvicPrioBits>8</nvicPrioBits>\n"
     "<vendorSystickConfig>false</vendorSystickConfig>\n"
     "</cpu>\n"
     "<addressUnitBits>8</addressUnitBits>\n"
     "<width>32</width>\n"
     "<size>32</size>\n"
     "<access>read-write</access>\n"
     "<resetValue>0x00000000</resetValue>\n"
     "<resetMask>0xFFFFFFFF</resetMask>\n"
     "<peripherals>\n"
     )))

(defun org-svd-template (contents info)
  "Return complete document string after SVD conversion.
CONTENTS is the transcoded contents string.  INFO is a plist
holding export options."
  ;; FIXME: this must be placed at a better place
  (setq org-svd-register-list nil)
  (concat
   ;; 1. Build title block.
   (org-svd-template--opening info)
   ;; 2. Body
   contents
   ;; 3. Closing
   "</peripherals>\n"
   "</device>"))


;;;###autoload
(defun org-svd-export-as-svd (&optional async subtreep visible-only)
  "Export current buffer to a buffer in SVD format.

If narrowing is active in the current buffer, only export its
narrowed part.

If a region is active, export that region.

A non-nil optional argument ASYNC means the process should happen
asynchronously.  The resulting buffer should be accessible
through the `org-export-stack' interface.

When optional argument SUBTREEP is non-nil, export the sub-tree
at point, extracting information from the headline properties
first.

When optional argument VISIBLE-ONLY is non-nil, don't export
contents of hidden elements.

Export is done in a buffer named \"*Org SVD Export*\", which
will be displayed when `org-export-show-temporary-export-buffer'
is non-nil."
  (interactive)
  (org-export-to-buffer 'svd "*Org SVD Export*"
    async subtreep visible-only nil nil (lambda () (text-mode))))

;;;###autoload
(defun org-svd-export-to-svd (&optional async subtreep visible-only)
  "Export current buffer to a SVD file.

If narrowing is active in the current buffer, only export its
narrowed part.

If a region is active, export that region.

A non-nil optional argument ASYNC means the process should happen
asynchronously.  The resulting file should be accessible through
the `org-export-stack' interface.

When optional argument SUBTREEP is non-nil, export the sub-tree
at point, extracting information from the headline properties
first.

When optional argument VISIBLE-ONLY is non-nil, don't export
contents of hidden elements.

Return output file name."
  (interactive)
  (let ((outfile (org-export-output-file-name ".svd" subtreep)))
    (org-export-to-file 'svd outfile async subtreep visible-only)))

;;;###autoload
(defun org-svd-publish-to-svd (plist filename pub-dir)
  "Publish an org file to SVD.

FILENAME is the filename of the Org file to be published.  PLIST
is the property list for the given project.  PUB-DIR is the
publishing directory.

Return output file name."
  (org-publish-org-to 'svd filename ".svd" plist pub-dir))

(provide 'ox-svd)

;;; ox-svd.el ends here
